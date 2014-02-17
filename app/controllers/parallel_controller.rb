class ParallelController < ApplicationController
	include ApplicationHelper 
	def single_boro
		

		#@objs = LondonReducedBoroughRegion.get_borough("GREATER_LONDON_AUTHORITY")
		#gon.boroughs = @objs

		base_factor_url = "http://localhost:8080/oneFactor/"
		max_ranks = 10

		@param = params[:factor]
		gon.hide_wards = true
		gon.one_factor = true
		gon.parallel = true

		#@objs_wards = LondonReducedWardRegion.get_borough("GREATER_LONDON_AUTHORITY")
		#gon.wards = @objs_wards

		gon.feature_groups = Hash.new
		gon.feature_groups[:boroughs] = map_feature_collater(true, 1, base_factor_url)

		#Now we want to go through and add a 'grouped' ranking
		#We do this by going through and finding the difference between the ranked parameters

		#group_ranks(map_feature_collater(true, primary_factor, base_factor_url), max_ranks)
		#--------------------------------------------------
		#  				WARD DATA COLLATION	
		#--------------------------------------------------

		gon.feature_groups[:wards] = map_feature_collater(false, 1, base_factor_url)


	end
end
