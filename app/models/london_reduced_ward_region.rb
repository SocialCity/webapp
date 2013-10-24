class LondonReducedWardRegion
  include Mongoid::Document

  def self.get_borough(borough_name)
  	LondonReducedWardRegion.where("record.DESCRIPTIO" => borough_name)
  end

  def get_first
  	LondonReducedWardRegion.findOne()
  end

end
