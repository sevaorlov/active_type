require 'active_record'
:A
require 'active_type/property'
require 'active_type/postgresql_array_parser'

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

    str[0]="{"
    str[-1]="}"
    values = parser.parse_pg_array(str)
    #p "load: #{self.name}, #{values.to_s}"

    if values.length != get_properties.length
      raise "ActiveType properties doesnt match db type properties! Expected: #{self.name} #{get_properties.length} Got: #{values.length}"
    end

    i = 0
    inst = self.new
    get_properties.each do |property|
      value = values[i]
      if property.nested?
        value = get_nested_class(property.type).load value 
      elsif property.array?
        value = parser.parse_pg_array(value).collect{ |item| property.type_cast(item) } 
      else
        value = property.type_cast(value)
      end

      inst.send("#{property.name}=", value)
      i += 1
    end
    inst
  end

  # serialize type object
  def self.dump inst
    get_type_properties_from_db

    str = "("
    get_properties.each do |property|
      value = inst.send(property.name)
      if !value.nil?
        if property.nested?
          value = get_nested_class(property.type).dump value
          value = value.gsub(/^\(/,"\"(").gsub(/\)$/,")\"")
        elsif property.array?
          raise "Property that is marked as array is not realy an array!" if !value.kind_of?(Array)
          value = value.collect{ |item| item.to_s }.to_s
          value[0]="\"{"
          value[-1]="}\""
        else
          value = PGconn.quote_ident(value.to_s.gsub(/,/,"\,"))
        end
        str << value
      end
      str << ","
    end
    str.chop << ")"
  end

  private
  # gets type properties from db
  def self.get_type_properties_from_db

    if get_properties.empty?

      type_name = PGconn.escape_string(self.name.underscore)
      p "get type properties from type: #{type_name}"

      result = ActiveRecord::Base.connection.execute <<-SQL
        SELECT a.attname, t.typname
        FROM pg_class c JOIN pg_attribute a ON c.oid = a.attrelid JOIN pg_type t ON a.atttypid = t.oid
        WHERE c.relname = '#{type_name}';
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
    class_eval { attr_accessor name}
    (@props ||=  []) << Property.new(name, type)
  end

  # returns type object properties
  def self.get_properties
    @props ||= []
  end

  # returns parser for postgresql array parsing
  def self.parser
    @parser ||= MyPostgresParser.new
  end

  # returns nested type class by its name
  def self.get_nested_class type_name
    type_name.camelize.constantize
  end
end
