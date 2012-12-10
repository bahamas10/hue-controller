(function() {
  $(".tabbable ul li a").click(function(event) {
      event.preventDefault();
      $(this).tab("show");
  });

  $("#stop-all").click(function(event) {
    event.preventDefault();
    $(this).button("loading");

    $.ajax("/effects", {type: "DELETE", complete: function() { window.location.reload(); }});
  });

  var save_set;
  $("#save-set").click(function(event) {
    event.preventDefault();

    save_set = true;
    $("form").submit();
    save_set = false;
  });

  $("form").submit(function(event) {
    event.preventDefault();
    var lights = $("#lights").val();
    var groups = $("#groups").val();

    if( ( !lights || lights.length == 0 ) && ( !groups || groups.length == 0 ) ) {
      return Helper.error("You must select at least one light or group.");
    }

    var name = $.trim($("#name").val());
    if( name == "" ) {
      return Helper.error("You must enter a name.");
    }

    var scope = $(this);

    var data = {};
    data.save_set = save_set;
    data.name = name;
    data.lights = lights;
    data.groups = groups;
    data.finish_off = $("#finish_off").val() == "true";
    data.times_to_run = parseInt($("#times_to_run").val()) || 1;
    data.transitiontime = parseInt($("#transitiontime").val()) || 10;

    if( data.transitiontime <= 0 ) {
      return Helper.field_error("transitiontime", "Cannot be below 0.");
    } else if( data.times_to_run <= 0 ) {
      return Helper.field_error("times_to_run", "Cannot be below 0.");
    }

    Helper.reset_errors();
    scope.find(data.save_set ? "input[type='button']" : "input[type='submit']").button("loading");
    scope.find("input[type='button'], input[type='submit']").attr("disabled", true);

    // Find any specific settings to the effect ytpe
    scope.find(".tab-pane.active").find("input[type='number'], input[type='text'], select").each(function() {
      var field = $(this);

      var val;
      if( field.hasClass("colorpicker") ) {
        val = Helper.hex_to_hsv(field.val());
      } else {
        val = field.val();
      }

      data[field.attr("id")] = val;
    });

    $.ajax("/effect/" + scope.find(".tab-pane.active").attr("id"), {
      type: "POST",
      data: data,
      success: function() {
        scope.find(data.save_set ? "input[type='button']" : "input[type='submit']").button("reset");
        scope.find("input[type='button'], input[type='submit']").attr("disabled", true);

        if( data.save_set ) {
          $("#finished .modal-body").html("<p class='text-success'>Saved new effect as a set named \"" + data.name + "\".</p>");
        } else {
          $("#finished .modal-body").html("<p class='text-success'>Starting effect. This may take up to 10 - 20 seconds to start.</p><p>If nothing happens, make sure the worker is enabled.</p>");
        }

        $("#finished").modal();
      }
    });
  });
})();