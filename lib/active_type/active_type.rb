require 'active_type/property'

class ActiveType

  def initialize hash=nil 
    if hash
      hash.each do |key, value|
        instance_variable_set("@#{key}", value)
      end
    end
  end

  # deserialize type object
  def self.load str    
    # remove braces and quotes, that comes from db with strings
    vals = str.gsub(/[\(\)\"]/,"").split(",", -1)
    
    raise "ActiveType properties doesnt match db type properties!" if vals.length != get_properties.length
    
    i = 0
    inst = self.new
    get_properties.each do |property|
      inst.instance_variable_set(property.var_name, property.type_cast(vals[i]))
      i += 1
    end
    inst
  end

  # serialize type object
  def self.dump inst
    str = '('
    get_properties.each do |property|
      if inst.instance_variable_defined?(property.var_name)
	str << "\"#{inst.instance_variable_get(property.var_name)}\","
      else
	str << ","
      end
    end        
    str.chop << ')'    
  end
  
  # adds new property with its type
  def self.property(name, type=:string)

    if !self.class.instance_variable_defined?(:@props)
      self.class.class_eval { attr_accessor :props}
    end      

    class_eval { attr_accessor name}
    (@props ||=  []) << Property.new(name, type)
  end 

  # returns type object properties
  def self.get_properties
    (@props ||= [])
  end

end
