require 'active_type/property'

class ActiveType

  def initialize hash=nil 

    if hash
      hash.each do |key, value|
        instance_variable_set("@#{key}", value)
      end
    end
  end

  def self.load str
    vals = str[1, str.length-2].split(",")
    raise "Wrong type attributes!" if vals.length != get_properties.length

    i = 0
    type = self.new
    get_properties.each do |property|
      type.send "#{property.name}=", vals[i]
      i += 1
    end
    type
  end

  def self.dump type
    str = '('
    first = true
    get_properties.each do |property|          
      if !first
	str << ','
      else
        first = false
      end
      property_name = "@#{property.name}"
      v = (type.instance_variable_defined?(property_name) ? type.instance_variable_get(property_name) : '')
      str << "\"#{v}\""
    end
    str << ')'
  end
  
  def self.property(name, type=:string)

    if !self.class.instance_variable_defined?(:@props)
      self.class.class_eval { attr_accessor :props}
    end      

    class_eval { attr_accessor name}
    (@props ||=  []) << Property.new(name, type)
  end 

  def self.get_properties
    (@props ||= [])
  end

end
