class ActiveType

  @@props = {}

  def initialize hash=nil 

    if hash
      hash.each do |key, value|
        instance_variable_set("@#{key}", value)
      end
    end
  end

  def self.load str
    vals = str[1, str.length-2].split(",")
    raise "Wrong type attributes!" if vals.length != @@props[self.name].length

    i = 0
    type = self.new
    @@props[self.name].each do |property|
      type.send "#{property}=", vals[i]
      i += 1
    end
    type
  end

  def self.dump type
    str = '('
    first = true
    @@props[self.name].each do |property|          
      if !first
	str << ','
      else
        first = false
      end
      property = "@#{property}"
      v = (type.instance_variable_defined?(property) ? type.instance_variable_get(property) : '')
      str << "\"#{v}\""
    end
    str << ')'
  end
  
  def self.properties *params  
    params.each do |property|
      class_eval { attr_accessor property}
      (@@props[self.name] ||=  []) << property
    end
  end

end
