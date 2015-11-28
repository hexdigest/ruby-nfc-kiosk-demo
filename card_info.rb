require 'bindata'

class CardInfo < BinData::Record
  bit20 :balance
  bit4 :tariff
  bit7 :year
  bit4 :month
  bit5 :day
  
  string :name, read_length: 11

  def to_hash
  	field_names.inject({}) {|h, field| h[field] = send(field); h}
  end

  def from_hash(h)
    h.each do |k,v| 
      v = v.to_i if k != "name"
      send("#{k}=", v)
    end
  end
end
