class DistrictBoroughUnitaryRegion
  include Mongoid::Document

  def self.get_borough(borough_name)
  	DistrictBoroughUnitaryRegion.where("record.DESCRIPTIO" => borough_name)
  end

  def get_first
  	DistrictBoroughUnitaryRegion.findOne()
  end
end
