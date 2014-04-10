class ParallelController < ApplicationController
	include ApplicationHelper 
	def boroughs
		base_factor_url = "http://localhost:9113"
		max_ranks = 10

		input_year = params[:year]
		gon.hide_wards = true
		gon.one_factor = true
		gon.parallel = true
		gon.para_boros = true

		factor_info_params = { :method => "factorList"}
		@factor_info = parse_factor_list(URL_requester(BACKEND_URL, factor_info_params))

		if [2008, 2009, 2010, 2011, 2012].include?(input_year.to_i)
			@year = input_year.to_i
		else
			@year = 2012
		end

		req_params = { :method => "oneFactor",
						:factor_number => 1,
						:get_wards => false,
						:combine => false,
						:get_all_factors => true,
						:year => @year}

		request_data = URL_requester(BACKEND_URL, req_params)

		gon.feature_groups = Hash.new
		gon.feature_groups[:boroughs] = map_feature_collater(true, 1, request_data)

		boro_list = load_boros()
		puts boro_list.class.name
		gon.feature_groups[:boroughs].each do |boro|
			boro_list.each do |bl|
				if bl['code'] == boro['locations'][0]
					boro['name'] = bl['name']
				end
			end
		end
	end

	def wards		
		base_factor_url = "http://localhost:9113"

		max_ranks = 10

		@param = params[:factor]
		gon.hide_wards = true
		gon.one_factor = true
		gon.parallel = true
		gon.para_boros = false
		input_year = params[:year]

		factor_info_params = { :method => "factorList"}
		@factor_info = parse_factor_list(URL_requester(BACKEND_URL, factor_info_params))


		if [2008, 2009, 2010, 2011, 2012].include?(input_year.to_i)
			@year = input_year.to_i
		else
			@year = 2012
		end

		req_params = { :method => "oneFactor",
						:factor_number => 1,
						:get_wards => true,
						:combine => false,
						:get_all_factors => true}

		request_data = URL_requester(BACKEND_URL, req_params)
		#print request_data

		gon.feature_groups = Hash.new
		#--------------------------------------------------
		#  				WARD DATA COLLATION	
		#--------------------------------------------------

		gon.feature_groups[:wards] = map_feature_collater(false, 1, request_data)

		ward_list = load_wards()
		puts ward_list.class.name
		gon.feature_groups[:wards].each do |ward|
			ward_list.each do |wl|
				if wl['code'] == ward['locations'][0]
					ward['name'] = wl['name']
				end
			end
		end
	end

	def devices
		base_factor_url = "http://localhost:9113"
		max_ranks = 10

		@param = params[:factor]
		gon.hide_wards = true
		gon.one_factor = true
		gon.parallel = true
		gon.para_boros = false
		input_year = params[:year]

		factor_info_params = { :method => "factorList"}
		@factor_info = parse_factor_list(URL_requester(BACKEND_URL, factor_info_params))


		if [2008, 2009, 2010, 2011, 2012].include?(input_year.to_i)
			@year = input_year.to_i
		else
			@year = 2012
		end

		req_params = { :method => "hashTagFactors",
						:tag_1 => 1,
						:get_wards => true,
						:combine => false,
						:get_all_factors => true}

		request_data = URL_requester(BACKEND_URL, req_params)
		#print request_data

		gon.feature_groups = Hash.new
		#--------------------------------------------------
		#  				WARD DATA COLLATION	
		#--------------------------------------------------

		gon.feature_groups[:wards] = map_feature_collater(false, 1, request_data)

		ward_list = load_wards()
		puts ward_list.class.name
		gon.feature_groups[:wards].each do |ward|
			ward_list.each do |wl|
				if wl['code'] == ward['locations'][0]
					ward['name'] = wl['name']
				end
			end
		end
	end
end
