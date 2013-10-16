//Place all the behaviors and hooks related to the matching controller here.
// All this logic will automatically be available in application.js.
// You can use CoffeeScript in this file: http://coffeescript.org/


$(document).ready(function (){
	var map = new OpenLayers.Map('map');
    var fromProjection = new OpenLayers.Projection("EPSG:4326");   // Transform from WGS 1984
    var toProjection   = new OpenLayers.Projection("EPSG:900913"); // to Spherical Mercator Projection
	var position       = new OpenLayers.LonLat(-0.11,51.51).transform( fromProjection, toProjection);
    var zoom           = 12; 



    map.addLayer(new OpenLayers.Layer.OSM());
    map.setCenter(position, zoom);

    p1 = OpenLayers.Geometry.Point(470000.1, 206910.3);
    p2 = OpenLayers.Geometry.Point(460000.4, 205503.8);
    p3 = OpenLayers.Geometry.Point(450000.7, 206663.7);

    bounds = new OpenLayers.Bounds();
	bounds.extend(p1);
	bounds.extend(p2);
	bounds.extend(p3);
	bounds.toBBOX(); // returns 4,5,5,6

	var markers = new OpenLayers.Layer.Markers("Markers")
	map.addLayer(markers);
	markers.addMarker(new OpenLayers.Marker.Box(bounds));



    //This is a hack, and I don't like it, but whatever
    //It's necessary because OpenLayers flatly refuses to load into a % width div
    $('.front .map-container').css('height', $(window).height() * 0.8);
});

//Resizes the map after a short delay.
window.onresize = function()
{
  setTimeout( 
  	function() { 
  		$('.front .map-container').css('height', $(window).height() * 0.8);
  		map.updateSize();
  	}, 200);
}