require 'active_type'

describe "ActiveType" do

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
