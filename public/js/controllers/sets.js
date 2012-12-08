(function() {
  $("#sets .colorblock[data-state]").each(function() {
    var block = $(this);
    console.log(block);
  });

  $("#save-set").click(function(event) {
    event.preventDefault();

    $("#new-set .modal").modal();
  });

  $(".view-state").click(function(event) {
    event.preventDefault();

    $("#view-state").modal();

    $("#view-state").load("/set/state/" + $(this).data("set"), null, function() {
      Helper.process_colorblocks("#view-state");
    });
  });

  $(".delete").click(function(event) {
    event.preventDefault();
    if( !confirm("Are you sure?") ) return;

    $(this).button("loading");
    $.ajax("/set/" + $(this).data("set"), {type: "DELETE", complete: function() { window.location.reload(); }});
  });

  $(".apply").click(function(event) {
    event.preventDefault();

    $(this).button("loading");
    $(".apply").addClass("disabled");

    var data = {
      data: {mode: $(this).data("mode")},
      complete: function() {
        window.location.reload();
      }
    };

    if( $(this).data("mode") == "set-off") {
      data.type = "DELETE";
    } else {
      data.type = "POST";
    }

    $.ajax("/set/apply/" + $(this).data("set"), data);
  });

  $("#new-set").submit(function(event) {
    event.preventDefault();

    var name = $.trim($(this).find("#name").val());
    if( name == "" ) {
      return Helper.field_error("name", "Please enter a name");
    }

    var chosen_lights = $(this).find("#lights").val();
    if( !chosen_lights || chosen_lights.length == 0 ) {
      return Helper.field_error("lights", "Please select at least one light");
    }

    $(this).find("input[type='submit']").button("loading");

    Helper.request({
      success: function(data) {
        var lights = {};
        for( var i=0, total=chosen_lights.length; i < total; i++ ) {
          var state = data.lights[chosen_lights[i]].state;

          var light = lights[chosen_lights[i]] = {};
          light.on = state.on ? "true" : "false";
          light.bri = state.bri;
          light.colormode = state.colormode;

          if( state.colormode == "ct" ) {
            light.ct = state.ct;
          } else if( state.colormode == "hs" ) {
            light.hue = state.hue;
            light.sat = state.sat;
          } else {
            light.xy = state.xy;
          }
        }

        $.ajax("/set", {
          type: "POST",
          data: {name: name, lights: lights},
          success: function() {
            window.location.reload();
          }
        });
      }
    });
  });
})();