var Helper = {
  error: function(error) {
    $("#error").removeClass("hide").find("span").html(error);
  },

  process_colorblocks: function(scope) {
    $(scope).find(".colorblock[data-state]").each(function() {
      var block = $(this);

      var color = Helper.light_color(block.data("state"));
      block.data("state", null).attr("data-state", null).css("background-color", color);
    });
  },

  light_color: function(light) {
    if( light.colormode == "xy" ) {
      color = this.xy_to_rgb(light.xy);
      color = "rgb(" + color.r + "," + color.g + "," + color.b + ")";
    } else if( light.colormode == "ct" ) {
      color = this.ct_to_rgb(light.ct);
      color = "rgb(" + color.r + "," + color.g + "," + color.b + ")";
    } else if( light.colormode == "hs" ) {
      color = "hsl(" + (light.hue / 182.02) + "," + (light.sat / HueData.sat.max) * 100 + "%," + (light.bri / (HueData.bri.max + 146)) * 100 + "%)";
    }

    return color;
  },

  field_error: function(field, text) {
    var group = $("#" + field).closest(".control-group");
    group.addClass("error");

    if( group.find(".help-inline").length == 1 ) {
      var help = group.find(".help-inline");
      help.text(text);
    } else {
      this.error(text);
    }
  },

  reset_errors: function() {
    $(".control-group.error").removeClass("error");
    $("#error").addClass("hide");
  },

  reset_queue: function() {
    this.request_queue = [];
  },

  queue_request: function(args) {
    this.request_queue.push(args);
  },

  schedule_or_run: function(name, time, args) {
    if( time > Date.now() ) {
      var light = args.light;
      delete(args.light);
      var address = "/api/" + hub_info.apikey + "/lights/" + light + "/state";

      return {path: "schedules", type: "POST", data: {name: name, time: time.toISOString(), command: {method: "PUT", address: address, body: args}}};

    } else {
      var light = args.light;
      delete(args.light);
      return {path: "lights/" + light + "/state", type: "PUT", data: args};
    }
  },

  process_queue: function(status, oncomplete, onerror) {
    var offset = 0, max_offset = this.request_queue.length;
    var scope = this;

    var send_request = function() {
      var args = $.extend(scope.schedule_or_run(scope.request_queue[offset][0], scope.request_queue[offset][1], scope.request_queue[offset][2]), {
        error: function(res, textStatus, error) {
          var text = "Failed to send request: " + textStatus;
          if( typeof(error) == "string" && error != "" ) text += " (" + text + ")";
          scope.error(text + "<p>Please reload the page and try again.</p>");
          onerror();
        },

        success: function(res) {
          // Make sure our request succeeded
          var errors = [];
          for( var i= 0, total=res.length; i < total; i++ ) {
            if( res[i].error ) {
              errors.push(res[i].error.description + " (address: " + res[i].error.address + ")");
            }
          }

          if( errors.length > 0 ) {
            scope.error(errors.join("<br>"));
            onerror();
            return;
          }

          status.text("Processed " + offset + " of " + max_offset);
          offset += 1;

          // Done
          if( offset >= max_offset ) {
            return oncomplete();
          }

          // Process the next request
          send_request();
        }
      });

      // Send it off
      scope.request(args);
    };

    // Start processing
    send_request();
  },

  request: function(args) {
    var url = "http://" + hub_info.ip + "/api/" + hub_info.apikey;
    if( args.path ) {
      url += "/" + args.path;
      delete(args.path);
    }

    if( args.data && typeof(args.data) == "object" ) {
      args.data = JSON.stringify(args.data);
    }

    if( !args.error ) {
      args.error = function(res, textStatus, error) {
        if( res.readyState == 0 ) return;

        var text = "Failed to send request: " + textStatus;
        if( typeof(error) == "string" && error != "" ) text += " (" + text + ")";
        $("#info").removeClass("hide").removeClass("alert-info").addClass("alert-error").html("<strong>" + text + "</strong>");
      };
    }

    return $.ajax(url, args);
  },

  // Credit to https://github.com/Shushik/i-color
  xy_to_rgb: function(xy) {
    var x = xy[0], y = xy[1], z = (1 - xy[0] - xy[1]);

    var rgb = {};
    rgb.r = x * 3.2406 + y * -1.5372 + z * -0.4986;
    rgb.g = x * -0.9689 + y * 1.8758 + z * 0.0415;
    rgb.b = x * 0.0557 + y * -0.2040 + z * 1.0570;

    for( var type in rgb ) {
      if( rgb[type] > 0.0031308 ) {
        rgb[type] = 1.055 * Math.pow(rgb[type], (1 / 2.4)) - 0.055;
      } else {
        rgb[type] *= 12.92;
      }

      rgb[type] = Math.min(255, Math.max(Math.round(rgb[type] * 255), 0));
    }

    return rgb;
  },

  hex_to_hsv: function(hex) {
    var rgb = {r: 0, g: 0, b: 0};

    if( hex.length == 7 ) hex = hex.replace("#", "");
    if( hex.length == 3 ) {
      rgb.r = parseInt((hex.substring(0, 1) + hex.substring(0, 1)), 16);
      rgb.g = parseInt((hex.substring(1, 2) + hex.substring(1, 2)), 16);
      rgb.b = parseInt((hex.substring(2, 3) + hex.substring(2, 3)), 16);
    } else {
      rgb.r = parseInt(hex.substring(0, 2), 16);
      rgb.g = parseInt(hex.substring(2, 4), 16);
      rgb.b = parseInt(hex.substring(4, 6), 16);
    }

    return this.rgb_to_hsv(rgb);
  },

  rgb_to_hsv: function(rgb) {
    for( var key in rgb ) rgb[key] /= 255;

    var min = Math.min(rgb.r, rgb.g, rgb.b);
    var max = Math.max(rgb.r, rgb.g, rgb.b);
    var delta = max - min;

    var hsv = {};
    hsv.v = max;
    hsv.s = delta > 0 ? (delta / max) : 0;

    if( hsv.s <= 0 ) {
      hsv.h = 0;
    } else {
      if( rgb.r == max ) {
        hsv.h = (rgb.g - rgb.b) / delta;
      } else if( rgb.g == max ) {
        hsv.h = 2 + (rgb.b - rgb.r ) / delta;
      } else {
        hsv.h = 4 + (rgb.r - rgb.g ) / delta;
      }

      if( hsv.v < 0 ) hsv.v += 360;
      hsv.h = parseInt(hsv.h * 60 * 182.04);
    }

    hsv.s = parseInt(hsv.s * 254);
    hsv.v = parseInt(hsv.v * 254);
    return hsv;
  },

  // Credit to https://github.com/AaronH/RubyHue, which got it from http://www.tannerhelland.com/4435/convert-temperature-rgb-algorithm-code
  ct_to_rgb: function(ct) {
    ct = (1000000 / ct) / 100;

    var rgb = {};
    rgb.r = ct <= 66 ? 255 : 329.698727446 * Math.pow((ct - 60), -0.1332047592);

    if( ct <= 66 ) {
      rgb.g = 99.4708025861 * Math.log(ct) - 161.1195681661;
    } else {
      rgb.g = 288.1221695283 * Math.pow((ct - 60), -0.0755148492);
    }

    if( ct >= 66 ) {
      rgb.b = 255;
    } else if( ct <= 19 ) {
      rgb.b = 0;
    } else {
      rgb.b = 138.5177312231 * Math.log(ct - 10) - 305.0447927307;
    }

    for( var type in rgb ) {
      rgb[type] = Math.min(255, Math.max(0, Math.round(rgb[type])));
    }

    return rgb;
  },

  // From http://mjijackson.com/2008/02/rgb-to-hsl-and-rgb-to-hsv-color-model-conversion-algorithms-in-javascript
  // so credit to him for the implementation.
  rgb_to_hsl: function(r, g, b) {
    r /= 255, g /= 255, b /= 255;
    var max = Math.max(r, g, b), min = Math.min(r, g, b);
    var h, s, l = (max + min) / 2;

    if(max == min){
        h = s = 0; // achromatic
    }else{
        var d = max - min;
        s = l > 0.5 ? d / (2 - max - min) : d / (max + min);
        switch(max){
            case r: h = (g - b) / d + (g < b ? 6 : 0); break;
            case g: h = (b - r) / d + 2; break;
            case b: h = (r - g) / d + 4; break;
        }
        h /= 6;
    }

    return [h, s, l];
  }
};