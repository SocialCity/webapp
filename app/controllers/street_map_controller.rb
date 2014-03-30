class StreetMapController < ApplicationController
	include ApplicationHelper 

	def one_factor

		#@objs = LondonReducedBoroughRegion.get_borough("GREATER_LONDON_AUTHORITY")
		#gon.boroughs = @objs
		max_ranks = 10

		@param = params[:factor]
		gon.hide_wards = true
		gon.one_factor = true
		gon.street_map = true

		#, grab the factor information
		factor_info_params = { :method => "factorList"}
		@factor_info = parse_factor_list(URL_requester(BACKEND_URL, factor_info_params))


		gon.feature_groups = Hash.new

		#dodgy parameter handling
		@primary_factor = 0
		if(@param.to_i < 0 or @param.to_i > @factor_info.length - 1 or @param == nil) then
			@primary_factor = 0
		else
			@primary_factor = @param.to_i
		end


		boro_req_params = { :method => "oneFactor",
						:factor_number => @primary_factor,
						:get_wards => false,
						:combine => true,
						:get_all_factors => true}
		ward_req_params = { :method => "oneFactor",
						:factor_number => @primary_factor,
						:get_wards => true,
						:combine => true,
						:get_all_factors => true}

		#--------------------------------------------------
		#          		BOROUGH DATA COLLATION
		#--------------------------------------------------

		boro_request_data = URL_requester(BACKEND_URL, boro_req_params)
		ward_request_data = URL_requester(BACKEND_URL, ward_req_params)

		gon.feature_groups = Hash.new

		gon.feature_groups[:boroughs] = group_ranks(map_feature_collater(true, @primary_factor, boro_request_data), max_ranks)
		
		gon.feature_groups[:wards] = map_feature_collater(false, @primary_factor, ward_request_data)
	end

	def group_ranks(collated_features, reduce_to)
		diff_list = Hash.new
		no_ranks_to_remove = collated_features.length - reduce_to
		combine_list = Array.new

		rank_factor_index = collated_features[0]["primary_factor"].to_i
		rank_factor_name = ""
		collated_features[0]["factors"].keys.each_with_index do |key, index|
			if index == rank_factor_index then
				rank_factor_name = key
			end
		end

		for i in 0...(collated_features.length-1)
			curr_feature = collated_features[i]["factors"][rank_factor_name]
			next_feature = collated_features[i+1]["factors"][rank_factor_name]
			diff_list[(curr_feature - next_feature).abs] = i
		end

		hit_list = diff_list.keys.sort
		#We now take the first (ranks_to_remove) from the hit list, this will pick the ones with the smallest diff
		#To their next rank
		for i in 0..no_ranks_to_remove
			combine_list.push(diff_list[hit_list[i]])
		end
		combine_list = combine_list.sort


		#Now we go through the list and set n+1's rank to n
		for i in 0...collated_features.length
			collated_features[i]["adj_rank"] = collated_features[i]["rank"] 
		end 


		for i in 0...combine_list.length
			collated_features[combine_list[i] + 1]["adj_rank"] = collated_features[combine_list[i]]["adj_rank"]
		end

		#Now we correct ranks by going through and on a rank change from element i to i+1, setting val(i+1) to val(i) + 1
		for i in 0...(collated_features.length-1)
			curr_rank = collated_features[i]["adj_rank"]
			next_rank = collated_features[i+1]["adj_rank"]
			if next_rank > curr_rank then
				#Now we find the end of this run of ranks starting at next element
				count = 0
				for j in (i+1)..(collated_features.length-1)
					if collated_features[j]["adj_rank"] == next_rank then
						count += 1
					end
				end
				for j in (i+1)...(i+1+count) 
					collated_features[j]["adj_rank"] = curr_rank + 1
				end
			end
		end


		collated_features
	end

	def two_factor
		require 'open-uri' 
				#@objs = LondonReducedBoroughRegion.get_borough("GREATER_LONDON_AUTHORITY")
		#gon.boroughs = @objs

		base_factor_url = "http://localhost:8080/oneFactor/"
		@factor_1 = params[:factor_one]
		@factor_2 = params[:factor_two]

		@hide_wards = false;
		gon.street_map = true

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


		#
		# For each ward, attach a borough_rank variable
		# it can then grab the colour and adjust based on that?
		# Index into layer to grab rules, get colour based on that
		# Then permute
		#build up local cache of first 4 letters of id => base colour




		#--------------------------------------------------
		#          		BOROUGH DATA COLLATION
		#--------------------------------------------------

		gon.feature_groups[:boroughs] = map_feature_collater(true, primary_factor, base_factor_url)

		#--------------------------------------------------
		#  				WARD DATA COLLATION	
		#--------------------------------------------------

		gon.feature_groups[:wards] = map_feature_collater(false, primary_factor, base_factor_url)

		gon.one_factor = false
		#puts secondary_factor
		gon.relation_list = relate_wards_to_boroughs(gon.feature_groups[:wards], gon.feature_groups[:boroughs], secondary_factor)
	end

	def relate_wards_to_boroughs(ward_feature_groups, borough_feature_groups, ward_ranking_factor)
		temp_factor_hash = ["crimeRate","drugRate","educationRating","employmentRate","housePrice","meanAge","transportRating","voteTurnout"]
		borough_rank_hash = Hash.new
		borough_ward_list = Hash.new
		borough_sorted_ward_list = Hash.new
		#Stores one copy of the factor data for each rank
		ward_per_rank_factor_data = Hash.new

		borough_feature_groups.each do |borough_feature_group|
			borough_feature_group["locations"].each do |borough_ID|
				borough_rank_hash[borough_ID] = borough_feature_group["rank"];
			end
		end

		#organise into borough-sorted ward list, each location having a rank. 
		#sort by rank
		ward_feature_groups.each do |ward_feature_group|
			ward_per_rank_factor_data[ward_feature_group["rank"]] = ward_feature_group["factors"]
			#for each ward, get the borough, add the ward and rank to the borough list
			ward_feature_group["locations"].each do |ward_ID|
				#trim to get borough
				parent_borough_ID = ward_ID[0...4]
				if not borough_ward_list.has_key?(parent_borough_ID)
					borough_ward_list[parent_borough_ID] = Array.new
				end

				#We need to rank based on factor 2 within boroughs, so we need to sort by that value
				#puts ward_ranking_factor
				#puts "FACTOR "
				#puts "WARD RANK " + ward_ranking_factor
				#puts temp_factor_hash[ward_ranking_factor.to_i]
				ranking_stat_value = ward_per_rank_factor_data[ward_feature_group["rank"]][temp_factor_hash[ward_ranking_factor.to_i]]
				#puts "RANK STAT " + ranking_stat_value.to_s
				borough_ward_list[parent_borough_ID] << {:id => ward_ID, :rank => ward_feature_group["rank"].to_i, :ranking_stat_value => ranking_stat_value}
			end
		end

		# #now sort borough list based on ranks
		#puts borough_ward_list.inspect
		borough_ward_list.each do |borough_ID, borough_wards|
			rank_count = 0
			#puts borough.inspect
			borough_wards.sort_by!{|hsh| hsh[:ranking_stat_value]}
			#loop through to add ranks for easy grouping
			previous_stat = -1
			previous_rank = -1
			borough_wards.each do |ward|
				if previous_stat == -1
					previous_stat = ward[:ranking_stat_value]
					ward[:in_borough_rank] = 0
					previous_rank = 0
 				else
 					if previous_stat == ward[:ranking_stat_value]
 						ward[:in_borough_rank] = previous_rank
 					else
 						previous_stat = ward[:ranking_stat_value]
 						previous_rank = previous_rank + 1
 						ward[:in_borough_rank] = previous_rank
 					end

				end

			end
			borough_sorted_ward_list[borough_ID] = {:borough_rank => borough_rank_hash[borough_ID], :ward_list => borough_wards, :num_ward_ranks => previous_rank}
		end


		#assemble into useful structure
		return_list = {:factors => ward_per_rank_factor_data, :borough_list => borough_sorted_ward_list}
	end




	#Takes in a 	
	# def map_feature_collater(for_boroughs, primary_factor, request_url_base)
	# 	map_features 	= Array.new
	# 	ranking_array 	= Array.new

	# 	#construct factor data url
	# 	request_url = request_url_base + primary_factor.to_s + "/"
	# 	if for_boroughs then 
	# 		request_url += "false"
	# 	else
	# 		request_url += "true"
	# 	end


	# 	#grab data from the server
	# 	request = open(request_url) 

	# 	parsed_data = ""
	# 	request.each_line do |response|
	# 		parsed_data = JSON.parse(response)
	# 	end

	# 	#Pass through parsed JSON, structuring for the JS
	# 	parsed_data.each do |location_group|
	# 		feature_group 					= Hash.new
	# 		feature_group["locations"] 		= location_group['location']
	# 		feature_group["factors"] 		= Hash.new
	# 		feature_group["primary_factor"] = primary_factor


	# 		#Add in the value of each factor to the location list
	# 		location_group.each do |key, value|
	# 			if key != "location" then
	# 				feature_group["factors"][key] = value
	# 			end
	# 		end
	# 		map_features.push(feature_group)

	# 		#add to ranking array
	# 		ranking_array << {:array_id => (map_features.length - 1), :primary_value => feature_group["factors"][primary_factor] }
	# 	end

	# 	#rank by the primary factor
	# 	rank_count = 0
	# 	ranking_array.sort_by{|hsh| hsh[:primary_value]}.each do |rank|
	# 		map_features[rank[:array_id]]["rank"] = rank_count
	# 		rank_count += 1
	# 	end

	# 	map_features
	# end
end









#Ruby













