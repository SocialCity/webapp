class FrontController < ApplicationController
  def map
  	@objs = DistrictBoroughUnitaryRegion.get_borough "GREATER_LONDON_AUTHORITY"
  	gon.objects = @objs
  end
end
