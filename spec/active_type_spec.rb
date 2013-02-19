require 'active_type/active_type' 
require 'active_record'

describe "ActiveType" do

  describe "with db" do 
    class Address < ActiveType
       properties :city, :street, :postal_code
    end
        
    class Person < ActiveRecord::Base
       serialize :address, Address
       attr_accessor :name
    end
      
    let(:connection_hash) { { 
      adapter: 'postgresql',
      database: 'test-active-type',
      host: 'localhost',
      username: 'postgres',
      password: 'qwe324012',        
    } }

    before(:all) do
      ActiveRecord::Base.establish_connection(connection_hash)
      ActiveRecord::Base.connection.execute <<-SQL
	DROP TYPE IF EXISTS Address CASCADE;
        DROP TABLE IF EXISTS people CASCADE;
        CREATE TYPE Address AS (city varchar, street varchar, zip varchar);
        CREATE TABLE people ( name varchar, address Address);
      SQL
    end
      
    it "should work :)" do
      person = Person.create!( name: 'Ivan Groznij', address: Address.new( city: 'Moscow'))
      person.reload
      person.address.city.should == 'Moscow'
    end
  end

  describe "serialization" do
  
    class SomeType < ActiveType
      properties :pr1, :pr2, :pr3
    end
    
    it "serialize a type" do             
      type = SomeType.new
      type.pr1 = 'pr1_text'
      type.pr2 = 'pr2_text'
      type.pr3 = 'pr3_text'
      SomeType.dump(type).should eql('("pr1_text","pr2_text","pr3_text")')
    end
          
    it "deserialize a type" do         
      type = SomeType.load("(moskow,mohovaya,28)")
      type.pr1.should eql("moskow") 
      type.pr2.should eql("mohovaya")
      type.pr3.should eql("28")
    end
          
    it "raise error when properties not equal on deserialization" do          
      expect{SomeType.load("(moskow,mohovaya,28,sometext)")}.to raise_error
    end
  end  
  
end
