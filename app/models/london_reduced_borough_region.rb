class LondonReducedBoroughRegion
  include Mongoid::Document

  def self.get_borough(borough_name)
  	LondonReducedBoroughRegion.where("record.DESCRIPTIO" => borough_name)
  end

  def self.get_by_system_id(system_id)
  	LondonReducedBoroughRegion.where("record.SystemID" => Regexp.new(system_id)).entries
  end

  def get_first
  	LondonReducedBoroughRegion.findOne()
  end
end
