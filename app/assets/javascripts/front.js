//Place all the behaviors and hooks related to the matching controller here.
// All this logic will automatically be available in application.js.
// You can use CoffeeScript in this file: http://coffeescript.org/


$(document).ready(function (){
	var map = new OpenLayers.Map('map');
    map.addLayer(new OpenLayers.Layer.OSM());
    map.zoomToMaxExtent();
});