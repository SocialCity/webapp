class DistrictBoroughUnitaryRegion
  include Mongoid::Document

  def get_borough(borough_name)
  	DistrictBoroughUnitaryRegion.where("record.name" => borough_name)
  end

  def self.get_first
  	DistrictBoroughUnitaryRegion.findOne()
  end
end
