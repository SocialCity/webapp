class StreetMapController < ApplicationController
	def one_factor
		require 'open-uri' 

		#@objs = LondonReducedBoroughRegion.get_borough("GREATER_LONDON_AUTHORITY")
		#gon.boroughs = @objs

		base_factor_url = "http://localhost:8080/oneFactor/"
		@param = params[:factor]

		#@objs_wards = LondonReducedWardRegion.get_borough("GREATER_LONDON_AUTHORITY")
		#gon.wards = @objs_wards

		gon.feature_groups = Hash.new

		#dodgy parameter handling
		if(@param.to_i < 0 or @param.to_i > 7 or @param == nil) then
			primary_factor = 0
		else
			primary_factor = @param
		end



		#--------------------------------------------------
		#          		BOROUGH DATA COLLATION
		#--------------------------------------------------

		gon.feature_groups[:boroughs] = map_feature_collater(true, primary_factor, base_factor_url)

		#--------------------------------------------------
		#  				WARD DATA COLLATION	
		#--------------------------------------------------

		gon.feature_groups[:wards] = map_feature_collater(false, primary_factor, base_factor_url)
	end

	def two_factor
		require 'open-uri' 
				#@objs = LondonReducedBoroughRegion.get_borough("GREATER_LONDON_AUTHORITY")
		#gon.boroughs = @objs

		base_factor_url = "http://localhost:8080/oneFactor/"
		@factor_1 = params[:factor_one]
		@factor_2 = params[:factor_two]

		#@objs_wards = LondonReducedWardRegion.get_borough("GREATER_LONDON_AUTHORITY")
		#gon.wards = @objs_wards

		gon.feature_groups = Hash.new

		#dodgy parameter handling
		if(@factor_1.to_i < 0 or @factor_1.to_i > 7 or @factor_1 == nil) then
			primary_factor = 0
		else
			primary_factor = @factor_1
		end

		if(@factor_2.to_i < 0 or @factor_2.to_i > 7 or @factor_2 == nil) then
			secondary_factor = 0
		else
			secondary_factor = @factor_2
		end





		#--------------------------------------------------
		#          		BOROUGH DATA COLLATION
		#--------------------------------------------------

		gon.feature_groups[:boroughs] = map_feature_collater(true, primary_factor, base_factor_url)

		#--------------------------------------------------
		#  				WARD DATA COLLATION	
		#--------------------------------------------------

		gon.feature_groups[:wards] = map_feature_collater(false, primary_factor, base_factor_url)
	end


	#Takes in a 	
	def map_feature_collater(for_boroughs, primary_factor, request_url_base)
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

		#Pass through parsed JSON, structuring for the JS
		parsed_data.each do |location_group|
			# location_objects = Array.new
			# location_id_list = Array.new

			# location_group["location"].each do |location|
			# 	#a lovely quirk of mongo means that this needs to be regex to match
		 # 		location_id_list << Regexp.new(location)
			# end

			# #this allows you to append lists to lists
			# if(for_boroughs) then
			# 	location_objects.push(*LondonReducedBoroughRegion.get_by_system_id_list(location_id_list))
			# else
			# 	location_objects.push(*LondonReducedWardRegion.get_by_system_id_list(location_id_list))
			# end

			feature_group 					= Hash.new
			feature_group["locations"] 		= location_group['location']
			feature_group["factors"] 		= Hash.new
			feature_group["primary_factor"] = primary_factor


			#Add in the value of each factor to the location list
			location_group.each do |key, value|
				if key != "location" then
					feature_group["factors"][key] = value
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
			rank_count += 1
		end

		map_features
	end
end