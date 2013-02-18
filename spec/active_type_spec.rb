require 'active_type'

describe "ActiveType" do
  class Address < ActiveType
     property :city
     property :street
     property :postal_code
  end
  
  
  class Person < ActiveRecord::Base
     serialize Address
  end
  
  let(:connection_hash) { {database: 'test-active-type'} }

  before(:all) do
     ActiveRecord::Base.establish_connection(connection_hash)
     ActiveRecord::Base.connection.execute <<-SQL
        DROP TYPE IF EXISTS Address;
        DROP TABLE IF EXISTS people;
        CREATE TYPE Address (city varchar, street varchar, zip varchar);
        CREATE TABLE people ( name varchar, address Address);
     SQL
  end
  
  it "should work :)" do
    person = Person.create!( name: 'Ivan Groznij', address: Address.new( city: 'Moscow'))
    person.reload
    person.address.city.should == 'Moscow'
  end
  
  it "serialize a type" do
    ActiveType.add_properties [:pr1, :pr2, :pr3] 
    type = ActiveType.new
    type.pr1 = "pr1_text"
    type.pr2 = "pr2_text"
    type.pr3 = "pr3_text"
    ActiveType.dump(type).should eql('("pr1_text","pr2_text","pr3_text")')
  end

  it "deserialize a type" do
    ActiveType.add_properties [:one, :two, :three]
    type = ActiveType.load("(moskow,mohovaya,28)")
    type.one.should eql("moskow") 
    type.two.should eql("mohovaya")
    type.three.should eql("28")
  end

  it "raise error when properties not equal on deserialization" do 
    ActiveType.add_properties [:one, :two, :three]
    expect{ActiveType.load("(moskow,mohovaya,28,sometext)")}.to raise_error
  end
end
