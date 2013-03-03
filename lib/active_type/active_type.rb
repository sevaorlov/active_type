require 'active_type/property'
require 'active_record'

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
    get_type_properties_from_db

    # remove braces and quotes, that comes from db with strings
    str = str.gsub(/[\(\)\"]/,"")
    # store all arrays 
    arrays =[]
    str = str.gsub(/{.+?}/) do |item|       
      arrays << item.gsub(/[{}]/, "")      
      item = arrays.length - 1
    end
    
    vals = str.split(",", -1)
    #p "load values: #{vals.to_s}"    

    if vals.length != get_properties.length
      raise "ActiveType properties doesnt match db type properties! Expected: #{get_properties.length} Got: #{vals.length}"
    end
    
    i = 0
    inst = self.new
    get_properties.each do |property|
      value = vals[i]
      if property.array?
	value = arrays[value.to_i]
	raise "Wrong input for casting an array!" if value.nil?
	value = value.split(",").collect{ |item| property.type_cast(item) }	
      else
	value = property.type_cast(value)
      end
      
      inst.instance_variable_set(property.var_name, value)
      i += 1
    end
    inst
  end

  # serialize type object
  def self.dump inst
    get_type_properties_from_db

    str = '('
    get_properties.each do |property|
      if inst.instance_variable_defined?(property.var_name)
	v = inst.instance_variable_get(property.var_name)
	if property.array? 	  
	  raise "Property that is marked as array is not realy an array!" if !v.kind_of?(Array)
	  v = v.collect{ |item| item.to_s }.to_s	
	  v[0]="{"
	  v[v.length-1]="}"
	end      
	# TODO: escape all symbols
	v = v.to_s.gsub(/,/, "\,") if v.kind_of? String
	str << "\"#{v}\","
      else
	str << ","
      end
    end        
    str.chop << ')'        
  end

  private
  # gets type properties from db
  def self.get_type_properties_from_db
    
    if get_properties.empty?

      table = self.name.gsub(/[^0-9A-Za-z]/, '').downcase
      p "get type properties from table: #{table}"

      result = ActiveRecord::Base.connection.execute <<-SQL
	SELECT a.attname, t.typname
        FROM pg_class c JOIN pg_attribute a ON c.oid = a.attrelid JOIN pg_type t ON a.atttypid = t.oid
        WHERE c.relname = '#{table}';
      SQL
  
      p "got #{result.num_tuples} results"
      result.each do |field|
        property field["attname"], field["typname"]
	#p " #{field["attname"]} : #{field["typname"]}"
      end
    end
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
