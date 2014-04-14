class StreetMapController < ApplicationController
	include ApplicationHelper 

	def one_factor

		#@objs = LondonReducedBoroughRegion.get_borough("GREATER_LONDON_AUTHORITY")
		#gon.boroughs = @objs
		max_ranks = 8

		input_factor_num = params[:factor]
		input_year = params[:year]
		gon.hide_wards = true
		gon.one_factor = true
		gon.street_map = true
		@primary_factor = 0
		@year = 2012

		#, grab the factor information
		
		factor_info_params = { :method => "factorList"}
		@factor_info = parse_factor_list(URL_requester(BACKEND_URL, factor_info_params))
		gon.factor_info = @factor_info

		gon.feature_groups = Hash.new

		#dodgy parameter handling

		if(input_factor_num.to_i < 0 or input_factor_num.to_i > @factor_info.length - 1 or input_factor_num == nil) then
			@primary_factor = 0
		else
			@primary_factor = input_factor_num.to_i
		end

		if [2008, 2009, 2010, 2011, 2012].include?(input_year.to_i)
			@year = input_year.to_i
		else
			@year = 2012
		end


		boro_req_params = { :method => "oneFactor",
						:factor_number => @primary_factor,
						:get_wards => false,
						:combine => true,
						:get_all_factors => true,
						:year => @year}
		# ward_req_params = { :method => "oneFactor",
		# 				:factor_number => @primary_factor,
		# 				:get_wards => true,
		# 				:combine => true,
		# 				:get_all_factors => true}

		#--------------------------------------------------
		#          		BOROUGH DATA COLLATION
		#--------------------------------------------------

		boro_request_data = URL_requester(BACKEND_URL, boro_req_params)
		# ward_request_data = URL_requester(BACKEND_URL, ward_req_params)

		gon.feature_groups = Hash.new

		gon.feature_groups[:boroughs] = group_ranks(map_feature_collater(true, @primary_factor, boro_request_data), max_ranks)
		
		# gon.feature_groups[:wards] = map_feature_collater(false, @primary_factor, ward_request_data)

		#Grab some info for the keys
		@rank_values = Hash.new

		#Get name of primary factor
		factor_name = ""
		@factor_info.each do |factor|
			if factor[:factor_id] == @primary_factor.to_i then
				factor_name = factor[:factor_name]
			end
		end
		gon.feature_groups[:boroughs].each do |boro_group|
			rank = boro_group["adj_rank"]
			@rank_values[rank] = boro_group["factors"][get_factor_name(boro_group["primary_factor"])].round(4)
		end

		#Test hover thing.
	end

	def group_ranks(collated_features, reduce_to)
		diff_list = Hash.new
		no_ranks_to_remove = collated_features.length - reduce_to
		ranking_factor_name = get_factor_name(collated_features[0]['primary_factor'])

		#First, we sort the list into rank order
		sorted_features = collated_features.sort_by{|cf| cf['factors'][ranking_factor_name]}

		#Now get a list of indices and their diff to the next feature
		factor_diff_list = Array.new
		for i in 0...(sorted_features.length-1)
			curr_feat = sorted_features[i]
			next_feat = sorted_features[i+1]
			#puts "AT " + i.to_s + " R " + curr_feat['rank'].to_s + " " + curr_feat['factors'][ranking_factor_name].to_s + " " + next_feat['factors'][ranking_factor_name].to_s
			#We just want the diff, not the sign
			factor_diff_list << {
				:index => i,
				:diff => (curr_feat['factors'][ranking_factor_name] - next_feat['factors'][ranking_factor_name]).abs
			}
		end
		
		#Now sort this list based on difference
		#First, we're going to merge anything with 0's, since this is an insignificant border
		remove_rank_list = Array.new
		factor_diff_list.sort_by{|hash| hash[:diff]}.each do |sdl|
			if sdl[:diff] == 0
				remove_rank_list << sdl[:index]
				puts 'Adding ' + sdl[:index].to_s + " for remov " + sdl[:diff].to_s
			#Then, we take any others we need. If we've already got enough, we skip this bit
			elsif !(no_ranks_to_remove <= 0 or no_ranks_to_remove <= remove_rank_list.size) and sdl[:diff] > 0
				remove_rank_list << sdl[:index]
				puts 'Adding ' + sdl[:index].to_s + " for remov " + sdl[:diff].to_s
			end
		end

		#Now we sort the removal list
		sorted_removal_list = remove_rank_list.sort
		puts sorted_removal_list.to_s

		#We set the first feature to rank 0
		sorted_features[0]['adj_rank'] = 0
		adj_rank = 0
		#Now we move through, only iterating the rank whenever we encounter something *not* in 
		#our removal list
		for i in 1...(sorted_features.length)
			sorted_features[i]['adj_rank'] = adj_rank
			if not sorted_removal_list.include?(i)
				adj_rank += 1
			end
			
		end

		sorted_features
	end


	# def two_factor
	# 	require 'open-uri' 
	# 			#@objs = LondonReducedBoroughRegion.get_borough("GREATER_LONDON_AUTHORITY")
	# 	#gon.boroughs = @objs

	# 	base_factor_url = "http://localhost:8080/oneFactor/"
	# 	@factor_1 = params[:factor_one]
	# 	@factor_2 = params[:factor_two]

	# 	@hide_wards = false;
	# 	gon.street_map = true

	# 	#@objs_wards = LondonReducedWardRegion.get_borough("GREATER_LONDON_AUTHORITY")
	# 	#gon.wards = @objs_wards

	# 	gon.feature_groups = Hash.new

	# 	#dodgy parameter handling
	# 	if(@factor_1.to_i < 0 or @factor_1.to_i > 7 or @factor_1 == nil) then
	# 		primary_factor = 0
	# 	else
	# 		primary_factor = @factor_1
	# 	end

	# 	if(@factor_2.to_i < 0 or @factor_2.to_i > 7 or @factor_2 == nil) then
	# 		secondary_factor = 0
	# 	else
	# 		secondary_factor = @factor_2
	# 	end


	# 	#
	# 	# For each ward, attach a borough_rank variable
	# 	# it can then grab the colour and adjust based on that?
	# 	# Index into layer to grab rules, get colour based on that
	# 	# Then permute
	# 	#build up local cache of first 4 letters of id => base colour




	# 	#--------------------------------------------------
	# 	#          		BOROUGH DATA COLLATION
	# 	#--------------------------------------------------

	# 	gon.feature_groups[:boroughs] = map_feature_collater(true, primary_factor, base_factor_url)

	# 	#--------------------------------------------------
	# 	#  				WARD DATA COLLATION	
	# 	#--------------------------------------------------

	# 	gon.feature_groups[:wards] = map_feature_collater(false, primary_factor, base_factor_url)

	# 	gon.one_factor = false
	# 	#puts secondary_factor
	# 	gon.relation_list = relate_wards_to_boroughs(gon.feature_groups[:wards], gon.feature_groups[:boroughs], secondary_factor)
	# end

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













