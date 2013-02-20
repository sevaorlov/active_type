require 'active_type/active_type' 
require 'active_record'

describe "ActiveType" do

  describe "with db" do 
    class Address < ActiveType
       properties :city, :street, :postal_code
    end
        
    class Person < ActiveRecord::Base
       attr_accessible :name, :address
       serialize :address, Address
    end
      
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
      SQL
    end
      
    it "should work :)" do
      person = Person.create!(name: 'Ivan Groznij', address: Address.new( city: 'Moscow'))
      person.reload
      person.address.city.should == 'Moscow'
    end
  end

  describe "serialization" do
  
    class SomeType < ActiveType
      properties :pr1, :pr2, :pr3
    end
    
    class SomeAnotherType < ActiveType
      properties :one, :two, :three
    end

    class SomeThirdType < ActiveType
      properties :one, :two, :three
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
  
end
