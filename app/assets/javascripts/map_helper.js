function intialise_map()
{
    var map = new OpenLayers.Map('map');
    var fromProjection  = new OpenLayers.Projection("EPSG:4326");   // Transform from WGS 1984
    var toProjection    = new OpenLayers.Projection("EPSG:900913"); // to Spherical Mercator Projection
    var position        = new OpenLayers.LonLat(-0.11,51.51).transform( fromProjection, toProjection);
    var zoom            = 12; 

    map.addLayer(new OpenLayers.Layer.OSM());

    map.setCenter(position, zoom);
    return map;
}

function setup_controls(map, layer) {
    var highlightCtrl = new OpenLayers.Control.SelectFeature(layer, {
        hover: true,
        highlightOnly: true,
    });
    map.addControl(highlightCtrl);
    highlightCtrl.activate();
    highlightCtrl.handlers.feature.stopDown = false;
}

function setup_layers(map, borough_style, ward_style, ward_select) {
    var renderer = OpenLayers.Util.getParameters(window.location.href).renderer;
    renderer = (renderer) ? [renderer] : OpenLayers.Layer.Vector.prototype.renderers;

    var layers = [];

    layers['borough_layer'] = new OpenLayers.Layer.Vector("Boroughs", {
        styleMap: new OpenLayers.StyleMap({'default': borough_style}),
        renderers: renderer
    });

    map.addLayer(layers['borough_layer']);

    layers['ward_layer'] = new OpenLayers.Layer.Vector("Wards", {
        styleMap: new OpenLayers.StyleMap({'default': ward_style,
                                            'select': ward_select}),
        renderers: renderer
    });

    map.addLayer(layers['ward_layer']);

    return layers;
}


function setup_styles() {
    var rtn = [];
    rtn['borough_fill_style'] = new OpenLayers.Style({
        'fillOpacity': 0.5,
        'label' : "${name}\n${stat}",

        'strokeColor': "#000000",
        'strokeWidth': 2.5,
        'strokeDashstyle': "solid",
        
        'fontColor': 'black',
        'fontSize': "12px",
        'fontFamily': "Courier New, monospace",
        'fontWeight': "bold",
        'labelOutlineColor': "white",
        'labelOutlineWidth': 3
    });

    rtn['ward_fill_style'] = new OpenLayers.Style({
        'fillOpacity': 0,
        'fillColor': "#FFFFFF",
        'label' : "",

        'strokeColor': "#0000FF",
        'strokeWidth': 1,
        'strokeDashstyle': "dashdot",

        'fontColor': 'black',
        'fontSize': "12px",
        'fontFamily': "Courier New, monospace",
        'fontWeight': "bold",
        'labelOutlineColor': "white",
        'labelOutlineWidth': 3
    });

    rtn['ward_select_style'] = new OpenLayers.Style({
        'fillOpacity': 0.5,
        'fillColor': "#FFFFFF",
        'label' : "${name}",

        'strokeColor': "#0000FF",
        'strokeWidth': 1,
        'strokeDashstyle': "dashdot",

        'fontColor': 'black',
        'fontSize': "12px",
        'fontFamily': "Courier New, monospace",
        'fontWeight': "bold",
        'labelOutlineColor': "white",
        'labelOutlineWidth': 3
    });

    rtn['basic_line'] = {
        'strokeColor': "#000000",
        'strokeWidth': 1,
        'strokeDashstyle': "dashdot",
    };

    rtn['ward_line'] = OpenLayers.Util.extend({}, rtn['basic_line']);
    rtn['ward_line'].strokeColor = "#0000FF";
    rtn['ward_line'].strokeWidth = 1;

    return rtn;
}

function setup_rules (num_rules) 
{
    var rtn = new Array;
    var start_color = "0x0000FF00";
    var end_color = "0x00FF0000";
    var steps = Math.floor((parseInt(end_color, 16) - parseInt(start_color, 16)) / num_rules);
    var current_color = parseInt(start_color, 16);


    console.log((current_color + steps).toString(16) + " " + (current_color + steps));

    for(var i = 0; i <= num_rules; i++)
    {
    	var hex_section = current_color.toString(16);
    	while(hex_section.length < 6)
    		hex_section = "0" + hex_section;
    	var color_string = "#" + hex_section;
	    rtn.push(new OpenLayers.Rule({
	        filter: new OpenLayers.Filter.Comparison({
	            type: OpenLayers.Filter.Comparison.EQUAL_TO,
	            property: "rank",
	            value: i,
	        }),
	        symbolizer: {
	            fillColor : color_string,
	            fillOpacity: 0.5,
	        },
	    }));
	   current_color += steps;
	}
    return rtn;
}


function _setup_rules () {
    var rtn = [];
    rtn['rule1'] = new OpenLayers.Rule({
        filter: new OpenLayers.Filter.Comparison({
            type: OpenLayers.Filter.Comparison.EQUAL_TO,
            property: "styleNum",
            value: 1,
        }),
        symbolizer: {
            fillColor : "#FF00FF",
        },
    });
    rtn['rule2'] = new OpenLayers.Rule({
        filter: new OpenLayers.Filter.Comparison({
            type: OpenLayers.Filter.Comparison.EQUAL_TO,
            property: "styleNum",
            value: 2,
        }),
        symbolizer: {
            fillColor : "#FF0000",
        },
    });
    rtn['rule3'] = new OpenLayers.Rule({
        filter: new OpenLayers.Filter.Comparison({
            type: OpenLayers.Filter.Comparison.EQUAL_TO,
            property: "styleNum",
            value: 3,
        }),
        symbolizer: {
            fillColor : "#0000FF",
       },
    });
    rtn['rule4'] = new OpenLayers.Rule({
        filter: new OpenLayers.Filter.Comparison({
            type: OpenLayers.Filter.Comparison.EQUAL_TO,
            property: "styleNum",
            value: 4,
        }),
        symbolizer: {
            fillColor : "#00FF00",
        },
    });

    return rtn;
}

function plot_regions(map, layer, data, nameTrim, fromProj, toProj)
{
    for(var j = 0; j < data.length; j++)
    {
        var pointList = [];
        for(var i = 0; i < data[j]['shape'].length; i++)
        {
            var point = new OpenLayers.Geometry.Point(data[j]['shape'][i]['long'], data[j]['shape'][i]['lat']).transform( fromProj, toProj);
            pointList.push(point);
        }
        pointList.push(pointList[0]);

        var linearRing = new OpenLayers.Geometry.LinearRing(pointList);
        var rawName = data[j]['record']['DeletionFlag'].replace(nameTrim, "");
        var placeName = "";
        if(rawName.length > 15)
        {
            for(c in rawName)
            {
                //console.log(c);
                if(rawName[c] == " " && c >= 15 && placeName == "")
                {

                    var latter =  rawName.substr(c);
                    var initial = rawName.substr(0, c);
                    
                    placeName = initial + "\n" + latter;
                    //console.log(c + " " + rawName.length + " " + latter + " " + placeName);
                }
            }
        }
        if(placeName == "")
            placeName = rawName;

        var polygonFeature = new OpenLayers.Feature.Vector(
            new OpenLayers.Geometry.Polygon([linearRing]), 
            {
                'name': placeName,
                'styleNum': Math.floor((Math.random() * 10)) % 4 + 1,
            });

        layer.addFeatures(polygonFeature);
    }
}

function _plot_regions(map, layer, data, nameTrim, fromProj, toProj)
{
	for(set in data)
	{
		var current_loc_group = data[set];
		var factors 		= current_loc_group["factors"];
		var locations 		= current_loc_group["locations"];
		var primary_factor 	= current_loc_group["primary_factor"];

        var primary_value   = 0;
		var rank		 	= current_loc_group["rank"];

        var count = 0;
        for(i in factors)
        {
            if(count == primary_factor)
                primary_value = factors[i];
            count++;
        }

		//console.log(current_loc_group);
	    for(var j = 0; j < locations.length; j++)
	    {	
	        var pointList = [];
	       //console.log(locations);
	        for(var i = 0; i < locations[j]['shape'].length; i++) 
	        {
	        	//console.log(locations[j]);
	            var point = new OpenLayers.Geometry.Point(locations[j]['shape'][i]['long'], locations[j]['shape'][i]['lat']).transform( fromProj, toProj);
	            pointList.push(point);
	        }
	        pointList.push(pointList[0]);

	        var linearRing = new OpenLayers.Geometry.LinearRing(pointList);
	        //var rawName = locations[j]['record']['DeletionFlag'].replace(nameTrim, "");
	        var placeName = _name_trimmer(locations[j]['record']['DeletionFlag'].replace(nameTrim, ""));
	        
	        var polygonFeature = new OpenLayers.Feature.Vector(
	            new OpenLayers.Geometry.Polygon([linearRing]), 
	            {
	                'name': placeName,
	                'styleNum': Math.floor((Math.random() * 10)) % 4 + 1,
	                'rank': rank,
                    'stat': primary_value,
	            });

	        //console.log(polygonFeature);

	        layer.addFeatures(polygonFeature);
	    }
	}
}

function _name_trimmer(rawName)
{
	var placeName = "";
	if(rawName.length > 15)
    {
        for(c in rawName)
        {
            //console.log(c);
            if(rawName[c] == " " && c >= 15 && placeName == "")
            {

                var latter =  rawName.substr(c);
                var initial = rawName.substr(0, c);
                
                placeName = initial + "\n" + latter;
                //console.log(c + " " + rawName.length + " " + latter + " " + placeName);
            }
        }
    }
    if(placeName == "")
        placeName = rawName;

    return placeName
}