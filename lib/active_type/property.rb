require 'active_record'

class Property
  include ActiveRecord::ConnectionAdapters 
 
  attr_accessor :name, :type

  def initialize name, type
    @name = name
    @type = type
  end

  def type_cast value
    c = PostgreSQLColumn.new @name, "", @type
    c.type_cast value    
  end
end
