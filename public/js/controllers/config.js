(function() {
  // Reset the API Key we have saved so a new one is generated
  $("#forget").click(function(event) {
    event.preventDefault();
    if( !confirm("Are you sure?") ) return;

    $(this).button("loading");

    $.ajax("/config/apikey", {
      type: "DELETE",
      complete: function() {
        window.location.reload();
      }
    });
  });

  // Try and discover the IP of the hub
  $("#discover").click(function(event) {
    event.preventDefault();

    $(this).button("loading");
    $(".success, .error").removeClass("success").removeClass("error");

    $.ajax("/discover", {
      type: "POST",
      error: function() {
        $("#ip").closest(".controls").find(".help-inline").text("Timed out trying to find IP").addClass("error");
        $("#discover").button("reset");
      },
      success: function(ip) {
        $("#ip").val(ip).addClass("success");
        $("#ip").closest(".controls").find(".help-inline").text("Found IP!").addClass("success");
        $("#discover").button("reset");
      }
    });
  });

  var new_key;
  if( $("#forget").length == 0 ) {
    new_key = true;

    // Force a discovery check when we load the page if we don't have an API Key set
    if( $("#ip").val() == "" ) {
      $("#discover").trigger("click");
    }
  }

  $("form").submit(function(event) {
    event.preventDefault();

    Helper.reset_errors();
    $(".success, .error").removeClass("success").removeClass("error");

    var ip = $.trim($("#ip").val());
    if( ip == "" ) {
      return Helper.field_error("ip", "Please enter an IP");
    }

    var scope = $(this);
    if( new_key ) {
      var name = $.trim($("#devicetype").val());
      if( name == "" ) {
        return Helper.field_error("devicetype", "Please enter a name");
      }

      scope.find("input[type='submit']").button("auth");

      var check_request = function() {
        $.ajax("http://" + ip + "/api", {
          type: "POST",
          data: JSON.stringify({username: $("#username").val(), devicetype: name}),
          error: function(res, textStatus, error) {
            if( res.readyState == 0 ) return;

            var text = "Failed to send request: " + textStatus;
            if( typeof(error) == "string" && error != "" ) text += " (" + text + ")";

            $("#error span").text(text).removeClass("hide");
            $("#auth-modal").modal("hide");
            scope.find("input[type='submit']").button("reset");
          },
          success: function(res) {
            res = res[0];

            // Still waiting
            if( res.error && res.error.type == 101 ) {
              setTimeout(check_request, 1000);

            // Error, need to stop trying to authorize
            } else if( res.error ) {
              $("#error span").text(res.error.description).removeClass("hide");
              $("#auth-modal").modal("hide");

            // Authorized!
            } else {
              new_key = null;

              $("#auth-modal").modal("hide");

              scope.find("input[type='submit']").button("loading");
              scope.submit();
            }
          }
        });
      };

      $("#auth-modal").modal({backdrop: "static", keyboard: false});
      check_request();
      return;
    }

    scope.find("input[type='submit']").button("loading");
    $.ajax(scope.attr("action"), {
      type: "POST",
      data: {ip: ip, advanced: $("#advanced").val(), username: $("#username").val()},
      success: function() {
        $("#auth-modal").modal("hide");
        window.location = "/";
      }
    });
  });
})();