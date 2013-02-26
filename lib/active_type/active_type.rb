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
      type.send "#{property}=", vals[i]
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
      property = "@#{property}"
      v = (type.instance_variable_defined?(property) ? type.instance_variable_get(property) : '')
      str << "\"#{v}\""
    end
    str << ')'
  end
  
  def self.property(pty, type=:string)

    if !self.class.instance_variable_defined?(:@props)
      self.class.class_eval { attr_accessor :props}
    end      

    class_eval { attr_accessor pty}
    (@props ||=  []) << pty
  end 

  def self.get_properties
    (@props ||= [])
  end

end
