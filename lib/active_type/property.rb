require 'active_record'

class Property
  include ActiveRecord::ConnectionAdapters 
 
  attr_accessor :name, :type, :column

  def initialize name, type
    @name = name
    @type = convert_type type
  end

  # cast value to an appropriate instance
  def type_cast value
    #p "cast #{value} to #{@type}"
    column.type_cast value    
  end
    
  def var_name
    "@#{@name}"
  end  

  private
  def column
    @column = PostgreSQLColumn.new(@name, nil, @type) if @column.nil?
    @column
  end

  # sometimes
  def convert_type t
    case t.to_s
    when "bool"
      return "boolean"
    end
    return t
  end
  
end
