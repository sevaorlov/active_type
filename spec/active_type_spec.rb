require 'active_type/active_type' 
require 'active_record'

describe "ActiveType" do

  let(:connection_hash) { { 
    adapter: 'postgresql',
    database: 'test-active-type',
    host: 'localhost',
    username: 'postgres',
    password: 'postgres',        
  } }

  before(:all) do
    ActiveRecord::Base.establish_connection(connection_hash)
    ActiveRecord::Base.connection.execute <<-SQL
      DROP TYPE IF EXISTS Address CASCADE;
      DROP TABLE IF EXISTS people CASCADE;
      CREATE TYPE Address AS (city varchar, street varchar, zip varchar);
      CREATE TABLE people (id serial NOT NULL, name varchar, address Address, CONSTRAINT people_pkey PRIMARY KEY (id ));

      DROP TYPE IF EXISTS ManyDataTypesType CASCADE;
      DROP TABLE IF EXISTS manytypesmodel CASCADE;
      CREATE TYPE ManyDataTypesType AS (binary_type bytea, boolean_type boolean, date_type date, datetime_type timestamp, decimal_type decimal, float_type float, integer_type integer, string_type character varying, text_type text, time_type time, timestamp_type timestamp);
      CREATE TABLE manytypesmodel (id serial NOT NULL, name varchar, many_data_types_type ManyDataTypesType, CONSTRAINT manytypesmodel_pkey PRIMARY KEY (id ));
    SQL
  end

  describe "with db" do 
    class Address < ActiveType
      property :city
      property :street
      property :postal_code
    end
        
    class Person < ActiveRecord::Base
       attr_accessible :name, :address
       serialize :address, Address
    end

    it "should work :)" do
      person = Person.create!(name: 'Ivan Groznij', address: Address.new( city: 'Moscow'))
      person.reload
      person.address.city.should == 'Moscow'
    end
  end

  describe "serialization" do
  
    class SomeType < ActiveType
      property :pr1
      property :pr2
      property :pr3
    end
    
    class SomeAnotherType < ActiveType
      property :one
      property :two
      property :three
    end

    class SomeThirdType < ActiveType
      property :one
      property :two
      property :three
    end
    
    it "serialize a type" do             
      type = SomeType.new
      type.pr1 = 'pr1_text'
      type.pr2 = 'pr2_text'
      type.pr3 = 'pr3_text'
      SomeType.dump(type).should eql('("pr1_text","pr2_text","pr3_text")')
    end
          
    it "deserialize a type" do         
      type = SomeAnotherType.load("(moskow,mohovaya,28)")
      type.one.should eql("moskow") 
      type.two.should eql("mohovaya")
      type.three.should eql("28")
    end
          
    it "raise error when properties not equal on deserialization" do          
      expect{SomeThirdType.load("(moskow,mohovaya,28,sometext)")}.to raise_error
    end
  end 

  describe "with types" do 

    class ManyDataTypesType < ActiveType
      property :binary_type, :binary
      property :boolean_type, :boolean
      property :date_type, :date
      property :datetime_type, :datetime
      property :decimal_type, :decimal
      property :float_type, :float
      property :integer_type, :integer
      property :string_type, :string
      property :text_type, :text
      property :time_type, :time
      property :timestamp_type, :timestamp
    end

    class ManyTypesModel < ActiveRecord::Base
      attr_accessible :name, :many_data_types_type
      serialize :many_data_types_type, ManyDataTypesType
    end

  end 
  
end
