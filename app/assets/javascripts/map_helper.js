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


function setup_one_factor_styles() {
    var rtn = [];
    rtn['borough_fill_style'] = new OpenLayers.Style({
        'fillOpacity': 0.8,
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


function setup_two_factor_styles() {
    var rtn = [];
    rtn['borough_fill_style'] = new OpenLayers.Style({
        'fillOpacity': 0,
        'label' : "${name}",

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
        'fillOpacity': 1,
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
        'label' : "${name}\n${rank}",

        'strokeColor': "#FFFFFF",
        'strokeWidth': 1.5,
        'strokeDashstyle': "solid",

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


function setup_one_factor_rules (num_rules) 
{
    var rtn = new Array;
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
	            fillColor : get_color_string(color_set[i].get_RGB_array()),
	            fillOpacity: 0.7,
	        },
	    }));
	}
    return rtn;
}



function setup_two_factor_rules(boroughs, wards, relation_list) 
{
    var num_rules = boroughs.length;

    var rtn = new Array;
    //Get base_colours for wards
    var color_set = generate_color_set(num_rules);
    console.log("COLOR SET " + num_rules);
    console.log(color_set);

    //there's some disparity between what comes out of the generate method
    //here and when it is used for one-factor


    //Now loop through, for each ward we want to get the base colour for the parent borough, and
    //adjust it based on the ranking of the previous 
    //console.log(relation_list);
    var borough_list = relation_list["borough_list"];
    var factor_list = relation_list["factors"];
    //console.log(borough_list);

    var rule_list = new Array();
    for(borough_key in borough_list)
    {
        var borough = borough_list[borough_key];
        var borough_rank = borough["borough_rank"];
        var borough_wards = borough["ward_list"];
        var base_color = color_set[borough_rank];
        console.log(color_set);
        console.log(borough_rank);

        //console.log("Generating for base rank " + borough_rank + " with base_color " + base_color.RGB);
        var subcolor_set = generate_subcolor_set(base_color.get_RGB_array(), borough["num_ward_ranks"], base_color.fixed_element);
        console.log(subcolor_set);

        //Alter colour slightly based on in_borough rank
        for(var j = 0; j < borough_wards.length; j++)
        {
            //console.log(borough_wards[j]);
            //console.log("Subcolor set " + subcolor_set);
            //console.log(borough_wards[j]["in_borough_rank"]);
            rule_list[borough_rank + "-" + borough_wards[j]["in_borough_rank"]] = get_color_string(subcolor_set[borough_wards[j]["in_borough_rank"]]);
        }   
    }

    for(i in rule_list)
    {
        rtn.push(new OpenLayers.Rule({
            filter: new OpenLayers.Filter.Comparison({
                type: OpenLayers.Filter.Comparison.EQUAL_TO,
                property: "rank",
                value: i,
            }),
            symbolizer: {
                fillColor : rule_list[i],
                fillOpacity: 0.8,
            },
        }));
    }

    console.log(rtn);
    return rtn;
}

function generate_subcolor_set(borough_color, num_ranks, fixed_elem)
{
    var rank_span = 0.1;
    var range_bottom_color = borough_color;
    var range_top_color = borough_color;
    var subcolor_set = new Array();
    var change_array = new Array();


    for(var i = 0; i < borough_color.length; i++)
    {
        change_array.push(Math.round(borough_color[i] * rank_span));
        range_bottom_color[i] = Math.round(range_bottom_color[i] * (1-rank_span));
    }

    var current_subcolor = range_bottom_color;
    //console.log(current_subcolor);
    subcolor_set.push(current_subcolor.slice());
    //console.log(subcolor_set.slice());
    for(var i = 0; i <= num_ranks; i++)
    {
        //increment from bottom, checking not above top
        //
        //console.log("B " +current_color);
        current_subcolor = change_color(current_subcolor.slice(), fixed_elem, change_array, true);
        //console.log("A " + current_color);
        subcolor_set.push(current_subcolor.slice());
    }
    console.log(subcolor_set);
    return subcolor_set;
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

function insert_two_factor_stats(map, layer, data, temp_data)
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
    //Pass through features
    for(var i = 0; i < layer.features.length; i++)
    {   
        var found = false;
        var j = 0;
        while(j < data.length && !found)
        {
            //Get current ward/borough group, incl. location
            var current_loc_group = data[j];
            var locations         = current_loc_group["locations"];

            //The trim is necessary to shake an annoying carriage return that I don't seem to be able to shake
            //in the python script

            for(var k = 0; k < locations.length; k++)
            {
                if(locations[k] == layer.features[i].attributes['sysid'].trim())
                {
                    //Grab borough rank out of relation list
                    var parent_borough_rank = temp_data["borough_list"][locations[k].substring(0,4)]["borough_rank"];
                    //wow...
                    //console.log(temp_data["borough_list"][locations[k].substring(0,4)]["ward_list"]);

                    //culprit down here
                    var wards = temp_data["borough_list"][locations[k].substring(0,4)]["ward_list"];
                    //console.log(wards);
                    var in_borough_rank = -1;

                    //This causes big problems. I think the best option might be to index the wards by ward code
                    for(var p = 0; p < wards.length; p++)
                    {
                        //console.log('l');
                        if(wards[p]["id"] == locations[k])
                            in_borough_rank = wards[p]["in_borough_rank"];
                    }
                    //console.log("p");
                    layer.features[i].attributes['stat'] = current_loc_group["factors"][statIndex].toFixed(1);
                    layer.features[i].attributes['rank'] = parent_borough_rank + "-" + in_borough_rank;
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