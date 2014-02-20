module ApplicationHelper
	def map_feature_collater(for_boroughs, primary_factor, request_url_base)
		require 'open-uri' 
		map_features 	= Array.new
		ranking_array 	= Array.new

		#construct factor data url
		request_url = request_url_base + primary_factor.to_s + "/"
		if for_boroughs then 
			request_url += "false"
		else
			request_url += "true"
		end


		#grab data from the server
		request = open(request_url) 

		parsed_data = ""
		request.each_line do |response|
			parsed_data = JSON.parse(response)
		end

		#Whilst we are structuring etc, we want to produce a min/max list of values
		min_max_vals = Hash.new


		#Pass through parsed JSON, structuring for the JS
		parsed_data.each do |location_group|
			feature_group 					= Hash.new
			feature_group["locations"] 		= location_group['location']
			feature_group["factors"] 		= Hash.new
			feature_group["primary_factor"] = primary_factor


			#Add in the value of each factor to the location list
			fill_min_max_hash = false
			if(min_max_vals.length == 0)
				fill_min_max_hash = true
			end
			location_group.each do |key, value|
				if key != "location" then
					feature_group["factors"][key] = value

					if fill_min_max_hash
						min_max_vals[key] = Hash.new
						min_max_vals[key]['min'] = value
						min_max_vals[key]['max'] = value
					else
						if min_max_vals[key]['min'] > value
							min_max_vals[key]['min'] = value
						end
						if min_max_vals[key]['max'] < value
							min_max_vals[key]['max'] = value
						end
					end
				end
			end
			map_features.push(feature_group)

			#add to ranking array
			ranking_array << {:array_id => (map_features.length - 1), :primary_value => feature_group["factors"][primary_factor] }
		end

		#rank by the primary factor
		rank_count = 0
		ranking_array.sort_by{|hsh| hsh[:primary_value]}.each do |rank|
			map_features[rank[:array_id]]["rank"] = rank_count

			#This is not great practice as it inc data transfer but the 
			#map might break horribly if I include it as a global to the boros
			map_features[rank[:array_id]]["min_max"] = min_max_vals
			rank_count += 1
		end

		map_features
	end
end
