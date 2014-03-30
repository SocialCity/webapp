module ApplicationHelper
	require 'open-uri'

	def parse_factor_list(factor_list)
		parsed_data = ""
		factor_list_parsed = Array.new
		factor_list.each_line do |response|
			parsed_data = JSON.parse(response)
		end

		parsed_data.each do |factor|
			factor_list_parsed << {:factor_id => factor["id"],
									:measure => factor["measure"],
									:factor_name => factor["factor"]}
		end

		factor_list_parsed
	end

	def URL_requester(base_url, params)
		request_url = base_url + "/" + params[:method] + "/"
		case params[:method]
		when "oneFactor"
			request_url += params[:factor_number].to_s 		+ "/"
			request_url += params[:get_wards].to_s 			+ "/"
			request_url += params[:combine].to_s 			+ "/"
			request_url += params[:get_all_factors].to_s 	+ "/"
			if params.has_key?(:year)
				request_url += params[:year].to_s 			+ "/"
			end
		when "twoFactors"
			request_url += params[:factor_one].to_s 		+ "/"
			request_url += params[:factor_two].to_s 		+ "/"
			request_url += params[:get_wards].to_s 			+ "/"
			request_url += params[:combine].to_s 			+ "/"
			request_url += params[:get_all_factors].to_s 	+ "/"
			if params.has_key?(:year)
				request_url += params[:year].to_s 			+ "/"
			end
		when "areaFactors"
			request_url += params[:code].to_s 		+ "/"
			if params.has_key?(:year)
				request_url += params[:year].to_s 			+ "/"
			end
		when "timestamps"
			# no params
		when "hashTagList"
			if params.has_key?(:time)
				request_url += params[:time].to_s 			+ "/"
			end
		when "hashTagFactors"
			request_url += params[:tag_1].to_s 				+ "/"			+ "/"
			if params.has_key?(:time)
				request_url += params[:time].to_s 			+ "/"
			end
		when "devicesForBorough"
			request_url += params[:borough_code].to_s 		+ "/"
			if params.has_key?(:time)
				request_url += params[:time].to_s 			+ "/"
			end
		when "deviceList"
			if params.has_key?(:time)
				request_url += params[:time].to_s 			+ "/"
			end
		when "deviceFactor"
			request_url += params[:device].to_s 			+ "/"
			if params.has_key?(:time)
				request_url += params[:time].to_s 			+ "/"
			end
		when "factorList"
			if params.has_key?(:time)
				request_url += params[:time].to_s 			+ "/"
			end
		when "areaSentiment"
			request_url += params[:borough_code].to_s 			+ "/"
		when "hashtagSentiment"
			request_url += params[:tag].to_s 			+ "/"
		when "deviceSentiment"
			request_url += params[:device].to_s 			+ "/"
		when "areaWords"
			request_url += params[:word_code_num].to_s 			+ "/"
			request_url += params[:borough_code].to_s 			+ "/"
		when "hashtagWords"
			request_url += params[:word_code_num].to_s 			+ "/"
			request_url += params[:tag].to_s 			+ "/"
		when "deviceWords"
			request_url += params[:word_code_num].to_s 			+ "/"
			request_url += params[:device].to_s 			+ "/"
		when "areaTags"
			request_url += params[:borough_code].to_s 			+ "/"
		when "areaDevices"
			request_url += params[:borough_code].to_s 			+ "/"
		else
			raise "Invalid REST Method"
		end
		puts request_url
		begin
			request = open(request_url) 
		rescue StandardError => e
			raise ActionController::RoutingError.new("REST Error - #{e.message} - #{request_url}")
		end
	end
	
	def map_feature_collater(for_boroughs, primary_factor, request_data)
		require 'open-uri' 
		map_features 	= Array.new
		ranking_array 	= Array.new

		parsed_data = ""
		#puts "out"
		#puts request_data
		request_data.each_line do |response|
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
			#puts location_group
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
					#puts key
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
