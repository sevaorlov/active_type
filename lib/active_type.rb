require "active_type/version"

module ActiveType
  
  class TypeClass
    @@properties = []

    def self.load str
      vals = str[1, str.length-2].split(",")
      raise "Wrong type attributes!" if vals.length != @@properties.length

      i = 0
      type = self.new
      @@properties.each do |property|
        type.send "#{property}=", vals[i]
	i += 1
      end
      type
    end

    def self.dump type
      str = '('
      first = true
      type.instance_variables.each do |property|          
	if !first
	  str << ','
	else
	  first = false
	end
	str << "\"#{type.instance_variable_get(property)}\""
      end
      str << ')'      
    end
  
    def self.add_properties arr
      @@properties = []   
      arr.each do |property|
	class_eval { attr_accessor property}
	@@properties << property
      end
    end
  end

end
