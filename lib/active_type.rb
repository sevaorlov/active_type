require 'active_record'
require 'active_type/property'
require 'active_type/postgresql_array_parser'

class ActiveType

  def initialize(hash=nil)
    if hash
      hash.each do |key, value|
        instance_variable_set("@#{key}", value)
      end
    end
  end

  # deserialize type object
  def self.load str

    values = parser.parse_pg_array(str.gsub(/^\(/, '{').gsub(/\)$/, '}'))
    #p "load: #{self.name}, #{values.to_s}"

    if values.length != get_properties.length
      raise "ActiveType properties
      doesnt match db type properties! Expected: #{self.name}
      #{get_properties.length} Got: #{values.length}"
    end

    inst = self.new
    get_properties.each_with_index.each do |property, i|
      inst.send("#{property.name}=", property.deserialize(values[i]))
    end
    inst
  end

  # serialize type object
  def self.dump inst

    str = '('
    str << get_properties.map do |property|
      value = inst.send(property.name)
      property.serialize(value)
    end.join(",")
    str << ')'
  end

  private
  # gets type properties from db
  def self.get_type_properties_from_db

    type_name = PGconn.escape_string(self.name.underscore)
    p "get type properties from type: #{type_name}"

    result = ActiveRecord::Base.connection.execute <<-SQL
    SELECT a.attname,
    t.typname FROM pg_class c JOIN pg_attribute a
    ON c.oid = a.attrelid JOIN
    pg_type t ON a.atttypid = t.oid WHERE c.relname = '#{type_name}';
    SQL

    p "got #{result.num_tuples} results"
    result.each do |field|
      property field['attname'], field['typname']
      #p " #{field["attname"]} : #{field["typname"]}"
    end
  end

  # adds new property with its type
  def self.property(name, type=:string)
    class_eval { attr_accessor name }
    (@props ||=  []) << Property.new(name, type)
  end

  # returns type object properties
  def self.get_properties
    get_type_properties_from_db if @props.nil?
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
