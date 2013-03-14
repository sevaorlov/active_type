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
      DROP TYPE IF EXISTS address CASCADE;
      DROP TABLE IF EXISTS people CASCADE;
      CREATE TYPE address AS (city varchar, street varchar, zip varchar);
      CREATE TABLE people (id serial NOT NULL, name varchar, address address, CONSTRAINT people_pkey PRIMARY KEY (id ));

      DROP TYPE IF EXISTS many_data_types_type CASCADE;
      DROP TABLE IF EXISTS many_types_models CASCADE;
      CREATE TYPE many_data_types_type AS (binary_type bytea, boolean_type boolean, date_type date, datetime_type timestamp, decimal_type decimal, float_type float, integer_type integer, string_type varchar, text_type text, time_type time, timestamp_type timestamp);
      CREATE TABLE many_types_models (id serial NOT NULL, name varchar, mdtt many_data_types_type, CONSTRAINT manytypesmodel_pkey PRIMARY KEY (id ));
      
      DROP TYPE IF EXISTS project CASCADE;
      DROP TABLE IF EXISTS companies CASCADE;
      CREATE TYPE project AS (name varchar, started timestamp, new_project boolean, employees_number integer, some_time time, something bytea, project_type varchar);
      CREATE TABLE companies (id serial NOT NULL, name varchar, project project, CONSTRAINT company_pkey PRIMARY KEY (id ));
      
      DROP TYPE IF EXISTS type_with_array CASCADE;
      DROP TABLE IF EXISTS model_with_arrays CASCADE;
      CREATE TYPE type_with_array AS (str varchar, binary_array bytea[], boolean_array boolean[], date_array date[], datetime_array timestamp[], decimal_array decimal[], float_array float[], integer_array integer[], string_array varchar[], text_array text[], time_array time[], timestamp_array timestamp[]);
      CREATE TABLE model_with_arrays (id serial NOT NULL, name varchar, twa type_with_array, CONSTRAINT modelwitharray_pkey PRIMARY KEY (id ));

      --DROP TYPE IF EXISTS child_child_child_type CASCADE;
      --DROP TYPE IF EXISTS child_child_type CASCADE;
      DROP TYPE IF EXISTS child_type1 CASCADE;
      DROP TYPE IF EXISTS child_type2 CASCADE;
      DROP TYPE IF EXISTS parent_type CASCADE;
      DROP TABLE IF EXISTS some_models CASCADE;      
      --CREATE TYPE child_child_child_type AS (name varchar);
      --CREATE TYPE child_child_type AS (name varchar, some_string varchar);
      --, ccc child_child_child_type);
      CREATE TYPE child_type1 AS (name varchar, some_date date);
      --, child_child child_child_child_type);
      CREATE TYPE child_type2 AS (name varchar, some_boolean boolean);
      CREATE TYPE parent_type AS (name varchar, some_datetime timestamp, child1 child_type1, child2 child_type2);
      CREATE TABLE some_models (id serial NOT NULL, name varchar, parent_type parent_type, CONSTRAINT somemodel_pkey PRIMARY KEY (id));
    SQL
  end

  describe "with db" do 
    class Address < ActiveType
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
    end

    class ManyTypesModel < ActiveRecord::Base
      attr_accessible :name, :mdtt
      serialize :mdtt, ManyDataTypesType
    end
    
    class Project < ActiveType
    end

    class Company < ActiveRecord::Base
      attr_accessible :name, :project
      serialize :project, Project
    end
            
    it "should work" do
      binary_var = "some string for binary type"
      boolean_var = true
      date_var = Date.new(2011, 11, 3)
      datetime_var = Time.new(2012, 12, 21, 12, 11, 9)
      decimal_var = BigDecimal.new("0.0001")
      float_var = 104.21
      integer_var = 318
      string_var = "some random string"
      text_var = "some random, very long text"
      # It is always 01.01.2000, it is hard code in class Column
      time_var = Time.new(2000, 01, 01, 12, 11, 5)
      timestamp_var = Time.new(1999, 4, 14)    

      mdtt = ManyDataTypesType.new(binary_type: binary_var, boolean_type: boolean_var, 
          date_type: date_var, datetime_type: datetime_var, decimal_type: decimal_var, 
          float_type: float_var, integer_type: integer_var, string_type: string_var, 
          text_type: text_var, time_type: time_var, timestamp_type: timestamp_var)
      many_model = ManyTypesModel.create!(name: 'some random name', mdtt: mdtt)
      many_model.reload
      
      many_model.mdtt.binary_type.class.should == binary_var.class
      many_model.mdtt.boolean_type.class.should == boolean_var.class
      many_model.mdtt.date_type.class.should == date_var.class
      many_model.mdtt.datetime_type.class.should == datetime_var.class
      many_model.mdtt.decimal_type.class.should == decimal_var.class
      many_model.mdtt.float_type.class.should == float_var.class
      many_model.mdtt.integer_type.class.should == integer_var.class
      many_model.mdtt.string_type.class.should == string_var.class
      many_model.mdtt.text_type.class.should == text_var.class
      many_model.mdtt.time_type.class.should == time_var.class
      many_model.mdtt.timestamp_type.class.should == timestamp_var.class
         
      #ActiveRecord::Base.connection.unescape_bytea(many_model.mdtt.binary_type.gsub(/\\\\/,"\\")).should == binary_var
      #many_model.mdtt.binary_type.should == binary_var
      many_model.mdtt.boolean_type.should == boolean_var
      many_model.mdtt.date_type.should == date_var
      many_model.mdtt.datetime_type.should == datetime_var
      many_model.mdtt.decimal_type.should == decimal_var
      many_model.mdtt.float_type.should == float_var
      many_model.mdtt.integer_type.should == integer_var
      many_model.mdtt.string_type.should == string_var
      many_model.mdtt.text_type.should == text_var
      many_model.mdtt.time_type.should == time_var
      many_model.mdtt.timestamp_type.should == timestamp_var
    end
    
    it "should work even if they are empty" do
      project_name = "ONETWO"
      project_type = "startup"
      expect { Company.create!(name: 'Cool Company', project: Project.new( name:  project_name, project_type: project_type))}.to_not raise_error
      company = Company.last
      company.project.name.should == project_name    
      company.project.project_type == project_type   
    end
  end 
  
  describe "with arrays" do 
  
    class TypeWithArray < ActiveType  
    end

    class ModelWithArray < ActiveRecord::Base
      attr_accessible :name, :twa
      serialize :twa, TypeWithArray
    end

    it "should work" do
      str = "telephone"
      integer_array = [1, 2, 3, 4, 5]
      boolean_array = [true, false, false, true]
      date_array = [Date.new(2012,1,2), Date.new(2010,5,4), Date.new(1995,9,1)]
      binary_array = ["one", "two", "three"]
      datetime_array = [Time.new(2012, 12, 21, 12, 11, 9), Time.new(2013, 9, 11, 15, 11, 9)]
      decimal_array = [BigDecimal.new("0.0001"), BigDecimal.new("0.0002"), BigDecimal.new("0.0005")]
      float_array = [1.54, 5.44, 6.44, 6.99]
      string_array = ["string with comma", "string comma comma", "string with words"]
      text_array = ["text text textext text text", "text text"]
      time_array = [Time.new(2000, 01, 01, 12, 11, 5),  Time.new(2000, 01, 01, 12, 11, 5), Time.new(2000, 01, 01, 12, 11, 5)]
      timestamp_array = [Time.new(1999, 4, 14), Time.new(1999, 4, 14), Time.new(1999, 4, 14)]
      twa = TypeWithArray.new(str: str, integer_array: integer_array, boolean_array: boolean_array,date_array: date_array, 
	binary_array: binary_array, datetime_array: datetime_array, decimal_array: decimal_array, float_array: float_array,
	string_array: string_array, text_array: text_array, time_array: time_array, timestamp_array: timestamp_array)
      model = ModelWithArray.create!(name: 'wonderfull name', twa: twa)
      model.reload
      model.twa.str.should == str
      model.twa.integer_array.should == integer_array
      model.twa.boolean_array.should == boolean_array
      model.twa.date_array.should == date_array
      #model.twa.binary_array.should == binary_array
      model.twa.datetime_array.should == datetime_array
      model.twa.decimal_array.should == decimal_array
      model.twa.float_array.should == float_array
      model.twa.string_array.should == string_array
      model.twa.text_array.should == text_array
      model.twa.time_array.should == time_array
      model.twa.timestamp_array.should == timestamp_array
    end

  end

  describe "with nested types" do
    
    class ChildChildChildType < ActiveType 
    end

    class ChildChildType < ActiveType 
    end
    
    class ChildType1 < ActiveType
    end
    
    class ChildType2 < ActiveType
    end
    
    class ParentType < ActiveType
    end
    
    class SomeModel < ActiveRecord::Base
      attr_accessible :parent_type, :name
      serialize :parent_type, ParentType
    end
    
    it "should work" do
      child_child_name = "childchildname"
      some_string = "some string for child child"
      some_model_name = "some model name"
      parent_name = "parent_name"
      child1_name = "child1 name"
      child2_name = "child2 name"
      some_boolean = true
      some_date = Date.new(2012,1,2)
      some_datetime = Time.new(2012, 12, 21, 12, 11, 9)
      ccc_name = "one one one"
      
      ccc = ChildChildChildType.new(name: ccc_name)
      child_child = ChildChildType.new(name: child_child_name, some_string: some_string)#, ccc: ccc)
      child1 = ChildType1.new(name: child1_name, some_date: some_date)#, child_child: child_child)
      child2 = ChildType2.new(name: child2_name, some_boolean: some_boolean)
      parent = ParentType.new(name: parent_name, some_datetime: some_datetime, child1: child1, child2: child2)
      model = SomeModel.create!(name: some_model_name, parent_type: parent)
      model.reload
      
      model.name.should == some_model_name
      
      model.parent_type.name.should == parent_name
      model.parent_type.some_datetime.should == some_datetime
      model.parent_type.child1.name.should == child1_name
      model.parent_type.child1.some_date.should == some_date
      #model.parent_type.child1.child_child.name.should == child_child_name
      #model.parent_type.child1.child_child.some_string.should == some_string
      #model.parent_type.child1.child_child.ccc.name.should = ccc_name

      model.parent_type.child2.name.should == child2_name
      model.parent_type.child2.some_boolean.should == some_boolean    
    end    
  end

end 
