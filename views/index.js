(function() {
  var __bind = function(fn, me){ return function(){ return fn.apply(me, arguments); }; };
  script({
    src: "/socket.io/socket.io.js"
  });
  script({
    src: "http://maps.googleapis.com/maps/api/js?sensor=false"
  });
  coffeescript(function() {
    var S4, guid, socket;
    S4 = function() {
      return (((1 + Math.random()) * 0x10000) | 0).toString(16).substring(1);
    };
    guid = function() {
      return S4() + S4() + "-" + S4() + "-" + S4() + "-" + S4() + "-" + S4() + S4() + S4();
    };
    $(function() {});
    socket = io.connect("/");
    return socket.on("connect", function() {
      var MapView, Station, StationList, loadData;
      socket.emit("gimmestations");
      /*
      			Our c
      	socket = io.connect "/"
      	socket.on "connect", () ->
      		socket.emit "gimmestations"ustom implementation of Backbone.sync. It will first consult
      			localStorage for model data, going to the server via socket.io if 
      			necessary. If there is data in localStorage, we immediately provide
      			it, but then tell the server all the ids we have, asking for a list
      			of any additional models. 
      		*/
      loadData = function(name, cb) {};
      Backbone.sync = function(method, model, opts) {
        var data, modelData;
        if (method !== "read") {
          return opts.error("Invalid operation");
        }
        data = typeof localStorage !== "undefined" && localStorage !== null ? localStorage.getItem(model.name) : void 0;
        if (data && (modelData = JSON.parse(data))) {
          return opts.success(modelData);
        }
      };
      Station = Backbone.Model.extend({
        haha: true
      });
      StationList = Backbone.Collection.extend({
        model: Station,
        name: "stations"
      });
      new StationList().fetch();
      MapView = Backbone.View.extend({
        el: $("body"),
        initialize: function() {
          console.log("initialized.");
          this.render = __bind(function() {
            return console.log("rendering.");
          }, this);
          return this.render();
        }
      });
      return new MapView;
    });
  });
  script("// Define the overlay, derived from google.maps.OverlayView\nfunction Label(opt_options) {\n // Initialization\n this.setValues(opt_options);\n\n // Label specific\n var span = this.span_ = document.createElement('span');\n span.style.cssText = 'position: relative; left: -50%; top: -8px; ' +\n                      'white-space: nowrap; border: 1px solid blue; ' +\n                      'padding: 2px; background-color: white';\n\n var div = this.div_ = document.createElement('div');\n div.appendChild(span);\n div.style.cssText = 'position: absolute; display: none';\n};\nLabel.prototype = new google.maps.OverlayView;\n\n// Implement onAdd\nLabel.prototype.onAdd = function() {\n var pane = this.getPanes().overlayLayer;\n pane.appendChild(this.div_);\n\n // Ensures the label is redrawn if the text or position is changed.\n var me = this;\n this.listeners_ = [\n   google.maps.event.addListener(this, 'position_changed',\n       function() { me.draw(); }),\n   google.maps.event.addListener(this, 'text_changed',\n       function() { me.draw(); })\n ];\n};\n\n// Implement onRemove\nLabel.prototype.onRemove = function() {\n this.div_.parentNode.removeChild(this.div_);\n\n // Label is removed from the map, stop updating its position/text.\n for (var i = 0, I = this.listeners_.length; i < I; ++i) {\n   google.maps.event.removeListener(this.listeners_[i]);\n }\n};\n\n// Implement draw\nLabel.prototype.draw = function() {\n var projection = this.getProjection();\n var position = projection.fromLatLngToDivPixel(this.get('position'));\n\n var div = this.div_;\n div.style.left = position.x + 'px';\n div.style.top = position.y + 'px';\n div.style.display = 'block';\n\n this.span_.innerHTML = this.get('text').toString();\n};");
  coffeescript(function() {
    var StationsOverlay, blah, map, stationMarkers;
    StationsOverlay = function(options) {
      return this.setValues(options);
    };
    StationsOverlay.prototype = new google.maps.OverlayView;
    LabelOverlay.prototype.onAdd = function() {
      this._div = $("<div>FUCK YES.</div>");
      this._div.appendTo(this.getPanes().overlayImage);
      return this._div.css({
        position: "absolute",
        width: "20px",
        height: "10px",
        border: "1px solid black",
        padding: "0",
        margin: "0",
        overflow: "hidden",
        background: "white"
      });
    };
    LabelOverlay.prototype.draw = function() {
      var pos;
      console.log(this.get("position"));
      pos = this.getProjection().fromLatLngToDivPixel(this.get("position"));
      console.log(pos);
      return this._div.css({
        left: "" + pos.x + "px",
        top: "" + pos.y + "px"
      });
    };
    stationMarkers = {};
    map = null;
    blah = false;
    socket.on("stations", function(stations) {
      return stations.forEach(function(station) {
        var label, marker;
        if (stationMarkers[station._id]) {
          return;
        }
        marker = new google.maps.Marker({
          position: new google.maps.LatLng(station.lat, station.long),
          map: map,
          flat: true,
          draggable: true
        });
        if (!blah) {
          blah = true;
          label = new Label({
            map: map
          });
          label.bindTo("position", marker, "position");
          label.set("text", "-_-");
        }
        console.log(":)");
        return stationMarkers[station._id] = marker;
      });
    });
    return $(function() {
      var latlng, options;
      latlng = new google.maps.LatLng(-27.466369, 153.029597);
      options = {
        zoom: 16,
        center: latlng,
        mapTypeId: google.maps.MapTypeId.ROADMAP
      };
      map = new google.maps.Map(document.getElementById("map_canvas"), options);
      new LabelOverlay({
        map: map,
        position: latlng
      });
      return new google.maps.BicyclingLayer().setMap(map);
    });
  });
  style("html, body {\n	height: 100%;\n	margin: 0;\n	padding: 0;\n}\n\n#map_canvas {\n	width: 100%;\n	height: 100%;\n}");
  div({
    id: "map_canvas"
    /*
    
    coffeescript ->*/
  });
}).call(this);
