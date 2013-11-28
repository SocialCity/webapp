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
        'label' : "${name}\n${stat}",

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




    var color_set = generate_color_set(num_rules);
    console.log(color_set);

    for(var i = 0; i < num_rules; i++)
    {
	    rtn.push(new OpenLayers.Rule({
	        filter: new OpenLayers.Filter.Comparison({
	            type: OpenLayers.Filter.Comparison.EQUAL_TO,
	            property: "rank",
	            value: i,
	        }),
	        symbolizer: {
	            fillColor : get_color_string(color_set[i]),
	            fillOpacity: 0.5,
	        },
	    }));
	}
    return rtn;
}

function generate_color_set(num_rules)
{
    //we don't interact with this bit
    var hex_color_prefix = "0x00";

    var start_const = 1;
    var start_color = [140, 255, 0];
    var start_to_white_steps = get_color_steps(start_color, num_rules);

    var end_const = 0;
    var end_color = [255, 0, 0];
    var end_to_white_steps = get_color_steps(end_color, num_rules);


    //var steps = Math.floor((parseInt(end_color, 16) - parseInt(start_color, 16)) / num_rules);
    //We need to go from start -> white -> end
    var steps = 255 * 2 / num_rules;
    //var current_color = parseInt(get_color_string(start_color), 16);

    console.log("Start steps " + start_to_white_steps);
    console.log("End steps " + end_to_white_steps);


    var color_set = new Array();
    color_set.push(start_color.slice());
    var current_color = start_color;
    var hit_white = false;

    for(var i = 0; i < num_rules; i++)
    {
        if(hit_white == false)
        {
            if(!check_color_over_limit(current_color))
            {
                //Move towards white
                current_color = change_color(current_color, start_const, start_to_white_steps, true);
            }
            else
            {
                hit_white = true;
                current_color = [255,255,255];
            }

            if(!check_color_over_limit(current_color))
                color_set.push(current_color.slice());
        }
        else
        {
            //Move towards end
            if(!check_color_under_limit(current_color))
            {
                //Move towards white
                current_color = change_color(current_color, end_const, end_to_white_steps, false);   
            }
            color_set.push(current_color.slice());
        }
    }

    return color_set;
}

function get_color_string(RGB_array)
{
    console.log(RGB_array);
    var string = ("#" + get_hex(RGB_array[0]) + get_hex(RGB_array[1]) + get_hex(RGB_array[2]));
    console.log(string);
    return string;
}

function get_hex(num)
{
    if(num == 0)
        return "00"
    else
        return num.toString(16);
}


function check_color_over_limit(RGB_array)
{
    for(var i = 0; i < RGB_array.length; i++)
        if(RGB_array[i] > 255)
            return true;
}

function check_color_under_limit(RGB_array)
{
    for(var i = 0; i < RGB_array.length; i++)
        if(RGB_array[i] < 0)
            return true;
}


function change_color(RGB_array, fixed_elem, change_array, increment)
{
    console.log("ARRAY: " + RGB_array + " INCREMENT " + increment);
    for(var i = 0; i < RGB_array.length; i++)
    {
        if(i != fixed_elem)
        {
            if(increment)
                RGB_array[i] += change_array[i];
            else
                RGB_array[i] -= change_array[i];
        }
    }
    return RGB_array;
}

function get_color_steps(RGB_array, num_rules)
{
    var step_array = new Array();
    for(var i = 0; i < RGB_array.length; i++)
        step_array.push(Math.round((255-RGB_array[i]) / (num_rules / 2)));
    return step_array;
}

function plot_features(map, layer, featureList, nameTrim, fromProj, toProj)
{
    var locations       = featureList;

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
                'sysid': locations[j]['record']['SystemID'],
                'rank': 0,
                'stat': -1
            });

        //console.log(polygonFeature);

        layer.addFeatures(polygonFeature);
    }
}

function insert_stats(map, layer, data)
{
    var factors           = data[0]["factors"];
    var primary_factor    = data[0]["primary_factor"];

    var statIndex = "", count = 0;
    for(i in factors) 
    {
        if(count == primary_factor)
            statIndex = i;
        count++;
    }

    //console.log(current_loc_group);
    for(var i = 0; i < layer.features.length; i++)
    {   
        var found = false;
        var j = 0;
        while(j < data.length && !found)
        {
            var current_loc_group = data[j];
            var locations         = current_loc_group["locations"];

            //The trim is necessary to shake an annoying carriage return that I don't seem to be able to shake
            //in the python script

            for(var k = 0; k < locations.length; k++)
            {
                if(locations[k] == layer.features[i].attributes['sysid'].trim())
                {
                    layer.features[i].attributes['stat'] = current_loc_group["factors"][statIndex].toFixed(1);
                    layer.features[i].attributes['rank'] = current_loc_group["rank"];
                    layer.drawFeature(layer.features[i], "");
                    found = true;
                }
            }
            j++;
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