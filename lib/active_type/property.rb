require 'active_record'

class Property
  include ActiveRecord::ConnectionAdapters 
 
  attr_accessor :name, :type

  def initialize name, type
    @name = name
    @array = (type.to_s[0] == "_")
    type[0] = '' if @array
    @type = convert_type type
    #p "new property #{@name}, #{@type}, array=#{@array}"
  end

  # cast value to an appropriate instance
  def type_cast value
    #p "cast #{value} to #{@type}"
    column.type_cast value       
  end
    
  def var_name
    "@#{@name}"
  end  

  def array?
    @array
  end

  def nested?
    if @nested.nil?
      @nested = column.type.nil?
      @column = nil if @nested
    end
    @nested
  end

  private
  def column
    @column ||= PostgreSQLColumn.new(@name, nil, @type)    
  end

  def convert_type t
    case t.to_s
    when "bool"
      return "boolean"
    end
    return t
  end
  
end
