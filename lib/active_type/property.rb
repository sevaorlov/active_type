require 'active_record'

class Property
  include ActiveRecord::ConnectionAdapters 
 
  attr_accessor :name, :type, :column

  def initialize name, type
    @name = name
    @type = type
  end

  # cast value to an appropriate instance
  def type_cast value
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
  
end
