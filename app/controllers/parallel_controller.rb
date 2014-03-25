class ParallelController < ApplicationController
	include ApplicationHelper 
	def boroughs
		base_factor_url = "http://localhost:9113"
		max_ranks = 10

		@param = params[:factor]
		gon.hide_wards = true
		gon.one_factor = true
		gon.parallel = true
		gon.para_boros = true

		req_params = { :method => "oneFactor",
						:factor_number => 1,
						:get_wards => false,
						:combine => false,
						:get_all_factors => true}

		request_data = URL_requester(base_factor_url, req_params)

		gon.feature_groups = Hash.new
		gon.feature_groups[:boroughs] = map_feature_collater(true, 1, request_data)
	end

	def wards		
		base_factor_url = "http://localhost:9113"

		max_ranks = 10

		@param = params[:factor]
		gon.hide_wards = true
		gon.one_factor = true
		gon.parallel = true
		gon.para_boros = false

		req_params = { :method => "oneFactor",
						:factor_number => 1,
						:get_wards => true,
						:combine => false,
						:get_all_factors => true}

		request_data = URL_requester(base_factor_url, req_params)
		print request_data

		gon.feature_groups = Hash.new
		#--------------------------------------------------
		#  				WARD DATA COLLATION	
		#--------------------------------------------------

		gon.feature_groups[:wards] = map_feature_collater(false, 1, request_data)


	end
end
