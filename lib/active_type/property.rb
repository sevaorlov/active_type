require 'active_record'
require 'active_type/postgresql_array_parser'

class Property
  include ActiveRecord::ConnectionAdapters

  attr_accessor :name

  def initialize(name, type)
    @name = name
    @array = (type.to_s[0] == '_')
    type[0] = '' if @array
    @type = convert_type type
    #p "new property #{@name}, #{@type}, array=#{@array}"
  end

  def serialize(value)
    res = ''
    if !value.nil?
      if nested?
        res = get_nested_class(type).dump value
        res = res.gsub(/^\(/, '"(').gsub(/\)$/, ')"')
      elsif array?
        if !value.kind_of?(Array)
          raise 'Property that is marked as array is not realy an array!'
        end
        res = value.collect { |item| item.to_s }.to_s
        res[0] = '"{'
        res[-1] = '}"'
      else
        res = PGconn.quote_ident(value.to_s.gsub(/,/, '\,'))
      end
    end
    res
  end

  def deserialize(value)
    res = ''
    if nested?
      res = get_nested_class(type).load value
    elsif array?
      res = parser.parse_pg_array(value).
        collect { |item| type_cast(item) }
    else
      res = type_cast value
    end
    res
  end

  private

  # cast value to an appropriate instance
  def type_cast(value)
    #p "cast #{value} to #{@type}"
    column.type_cast value
  end

  def array?
    @array
  end

  def nested?
    column.type.nil?
  end

  def type
    @type
  end

  def column
    @column ||= PostgreSQLColumn.new(@name, nil, @type)
  end

  def convert_type(t)
    case t.to_s
    when 'bool'
      return 'boolean'
    end
    return t
  end

  #returns nested type class by its name
  def get_nested_class(type_name)
    type_name.camelize.constantize
  end

  #parser for postgresql array parsing
  def parser
    @parser ||= MyPostgresParser.new
  end
end
