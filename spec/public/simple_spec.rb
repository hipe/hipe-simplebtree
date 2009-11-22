require File.expand_path(File.dirname(__FILE__) + "/../spec_helper")
describe "btree" do
  it "should be able to contruct an empty btree" do
    tree = Hipe::SimpleBTree.new
  end
  
  it "should construct given a proc and sort a simple array" do
    tree = Hipe::SimpleBTree.new(['gamma','alpha','beta']){|a,b| (a<=>b)*-1 }
    arr = tree.to_array
    arr.should == ['gamma','beta','alpha']
  end
  
  it "shouuld"
  
end
