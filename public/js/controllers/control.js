(function() {
  var parent_control;
  var control_ids = {};

  // Need to cleanup the grouping logic one of these days
  $(".tabbable ul li a").click(function(event) {
    event.preventDefault();
    $(this).tab("show");

    parent_control = null;
    control_ids = {};

    $(".group .colors").show();
    $(".group .control-with").hide();
  });

  // Group management
  $(".group .header input").click(function() {
    var scope = $("#lights:visible, #groups:visible").first();
    var checked = $(this).is(":checked");
    var group = $(this).closest(".group");

    var is_parent = parent_control && parent_control.data("id") == group.data("id");

    // The parent is no longer checked
    if( !checked && parent_control && is_parent ) {
      var new_parent = $(".group .header input:checked:first").closest(".group");
      // Found a new one
      if( new_parent.length == 1 ) {
        parent_control = new_parent;
        parent_control.find(".colors").show();
        parent_control.find(".control-with").hide();

        scope.find(".control-with strong").text("Control through " + parent_control.find(".header strong").text());

      // No others found
      } else {
        parent_control = null;
        control_ids = {};
      }

    // Non-parent is checked
    } else if( parent_control && !is_parent ) {
      // Add it to the group control
      if( checked ) {
        group.find(".colors").hide();
        group.find(".control-with").show();
        group.find(".control-with strong").text("Control through " + parent_control.find(".header strong").text());

      // Allow independent control
      } else {
        group.find(".colors").show();
        group.find(".control-with").hide();
      }

    } else if( !parent_control ) {
      parent_control = group;
    }

    if( checked && parent_control ) {
      control_ids[group.data("id")] = true;
    } else {
      delete(control_ids[group.data("id")]);
    }
  });

  $("#select-all").click(function(event) {
    event.preventDefault();

    var scope = $("#lights:visible, #groups:visible").first();
    scope.find(".group .header input").attr("checked", true);

    parent_control = scope.find(".group:first");

    control_ids = {};
    scope.find(".group").each(function() {
      var group = $(this);
      control_ids[group.data("id")] = true;

      if( group.data("id") != parent_control.data("id") ) {
        group.find(".colors").hide();
        group.find(".control-with").show();
        group.find(".control-with strong").text("Control through " + parent_control.find(".header strong").text());
      }
    });
  });

  $("#unselect-all").click(function(event) {
    event.preventDefault();

    parent_control = null;
    control_ids = {};

    var scope = $("#lights:visible, #groups:visible").first();
    scope.find(".group .header input").attr("checked", false);

    var groups = scope.find(".group");
    groups.find(".colors").show();
    groups.find(".control-with").hide();
  });

  // Load initial state
  function load_state(selector, list) {
    for( var id in list ) {
      var state = list[id].action || list[id].state;

      var row = selector.find(".group[data-id='" + id + "']");
      if( state.bri > HueData.bri.min ) {
        row.find(".bri").simpleSlider("setValue", state.bri);
      } else {
        row.find(".bri").simpleSlider("setValue", HueData.bri.min);
      }

      var colorpicker = row.find(".picker");
      if( state.colormode == "xy" ) {
        // Bit of a hack, probably should improve it later
        // First convert X/Y to RGB, which gives us the base color
        var color = Helper.xy_to_rgb(state.xy);
        // then convert RGB to HSV
        color = Helper.rgb_to_hsv(color);
        // then take the brightness into account
        color.v = state.bri;
        // and finally turn it into an rgb with brightness accounted for
        color = Helper.hsv_to_rgb(color);

        colorpicker.miniColors("value", Helper.rgb_to_hex(color));

      } else if( state.colormode == "hs" ) {
        var color = Helper.hsv_to_rgb({h: state.hue, s: state.sat, v: state.bri});
        colorpicker.miniColors("value", Helper.rgb_to_hex(color));

      } else if( state.colormode == "ct" ) {
        colorpicker.val("");
        row.find(".ct").simpleSlider("setValue", state.ct);
      }
    }
  }

  Helper.request({
    success: function(data) {
      load_state($("#lights"), data.lights);
      load_state($("#groups"), data.groups);

      $("#loading").remove();
      $(".tab-content").removeClass("hide");
    }
  });

  // Pushing light states
  function change_single_state(type, id, state) {
    var path;
    if( type == "lights" ) {
      path =  "lights/" + id + "/state";
    } else if( type == "groups" ) {
      path = "groups/" + id + "/action";
    }

    if( state.bri > HueData.bri.min ) {
      state.on = true;
      Helper.request({path: path, type: "PUT", data: state});
    } else {
      Helper.request({path: path, type: "PUT", data: {on: false}});
    }
  }

  // Throttles
  function push_state(mode, group) {
    var state = {};
    if( mode == "ct" ) {
      state.ct = parseInt(group.find(".ct").val());
      state.bri = parseInt(group.find(".bri").val());
    } else if( mode == "rgb" ) {
      var hsv = Helper.hex_to_hsv(group.find(".picker").val());
      state.hue = hsv.h;
      state.sat = hsv.s;
      state.bri = hsv.v;
    }

    var type = group.data("type");

    // Group change, always fun
    if( parent_control ) {
      for( var key in control_ids ) {
        change_single_state(type, key, state);
      }

    // Only changing a single light, nice and simple
    } else {
      change_single_state(type, group.data("id"), state);
    }
  }

  var throttle;
  function throttled_state(mode, group) {
    if( throttle ) clearTimeout(throttle);

    throttle = setTimeout(function() {
      push_state(mode, group);
    }, 25);
  }

  // Updating light state
  var scope = $("#lights, #groups").find(".group");
  scope.find(".picker").miniColors({
    opacity: false,
    letterCase: "uppercase",
    change: function(hex, rgba) {
      if( $("#loading").length == 1 ) return;

      var group = $(this).closest(".group");
      throttled_state("rgb", group);
    }
  });

  scope.find(".ct, .bri").bind("slider:changed", function() {
    if( $("#loading").length == 1 ) return;

    var group = $(this).closest(".group")
    throttled_state("ct", group);
  });
})();