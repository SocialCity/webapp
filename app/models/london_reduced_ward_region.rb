class LondonReducedWardRegion
  include Mongoid::Document

  def self.get_borough(borough_name)
  	LondonReducedWardRegion.where("record.DESCRIPTIO" => borough_name)
  end

  def self.get_by_system_id_list(list)
    LondonReducedBoroughRegion.in("record.SystemID" => list).entries
  end

  def get_first
  	LondonReducedWardRegion.findOne()
  end

end
