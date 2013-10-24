class FrontController < ApplicationController
  def map
  	@objs = LondonReducedBoroughRegion.get_borough "GREATER_LONDON_AUTHORITY"
  	gon.boroughs = @objs

  	@objs_wards = LondonReducedWardRegion.get_borough "GREATER_LONDON_AUTHORITY"
  	gon.wards = @objs_wards
  end
end
