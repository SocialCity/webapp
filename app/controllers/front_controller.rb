class FrontController < ApplicationController
	def map
		require 'open-uri' 

		#@objs = LondonReducedBoroughRegion.get_borough("GREATER_LONDON_AUTHORITY")
		#gon.boroughs = @objs

		@param = params[:factor]

		@objs_wards = LondonReducedWardRegion.get_borough("GREATER_LONDON_AUTHORITY")
		gon.wards = @objs_wards

		#dodgy parameter handling
		if(@param.to_i < 0 or @param.to_i > 7 or @param == nil) then
			primary_factor = 0
		else
			primary_factor = @param
		end

		#--------------------------------------------------
		#          		BOROUGH DATA COLLATION
		#--------------------------------------------------

		#grab data from the server
		request = open("http://localhost:8080/oneFactor/" + primary_factor.to_s + "/false") 
		parsed_data = ""
		request.each_line do |response|
			parsed_data = JSON.parse(response)
		end

		gon.display_arrays = Array.new
		ranking_array = Array.new

		#Pass through parsed JSON, structuring for the JS
		parsed_data.each do |location_group|
			location_objects = Array.new
			location_id_list = Array.new

			location_group["location"].each do |location|
				#a lovely quirk of mongo means that this needs to be regex to match
		 		location_id_list << Regexp.new(location)
			end

			#this allows you to append lists to lists
			location_objects.push(*LondonReducedBoroughRegion.get_by_system_id_list(location_id_list))

			display_array 					= Hash.new
			display_array["locations"] 		= location_objects
			display_array["factors"] 		= Hash.new
			display_array["primary_factor"] = primary_factor


			#Add in the value of each factor to the location list
			location_group.each do |key, value|
				if key != "location" then
					display_array["factors"][key] = value
				end
			end
			gon.display_arrays.push(display_array)

			#add to ranking array
			ranking_array << {:array_id => (gon.display_arrays.length - 1), :primary_value => display_array["factors"][primary_factor] }
		end

		#rank by the primary factor
		rank_count = 0
		ranking_array.sort_by{|hsh| hsh[:primary_value]}.each do |rank|
			gon.display_arrays[rank[:array_id]]["rank"] = rank_count
			rank_count += 1
		end

		#--------------------------------------------------
		#  				WARD DATA COLLATION	
		#--------------------------------------------------

		
	end
end