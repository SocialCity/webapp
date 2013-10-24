class LondonReducedBoroughRegion
  include Mongoid::Document

  def self.get_borough(borough_name)
  	LondonReducedBoroughRegion.where("record.DESCRIPTIO" => borough_name)
  end

  def get_first
  	LondonReducedBoroughRegion.findOne()
  end
end
