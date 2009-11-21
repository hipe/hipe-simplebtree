require File.expand_path(File.dirname(__FILE__) + "/../spec_helper")
describe "btree" do
  it "should be able to contruct an empty btree" do
    tree = SimpleBtree.new
  end
end
