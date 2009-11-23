require File.expand_path(File.dirname(__FILE__) + "/../spec_helper")
describe "btree" do
  it "should be able to contruct an empty btree" do
    tree = Hipe::SimpleBTree.new
  end
  
  it "should construct given a sort proc and sort a simple list of keys" do
    tree = Hipe::SimpleBTree[{'gamma'=>1,'alpha'=>1,'beta'=>1}]
    tree.cmp_proc = Proc.new{|a,b| (a<=>b)*-1 }
    arr = tree.to_a
    arr.should == [['gamma',1],['beta',1],['alpha',1]]
  end
  
  it "should be able to make a tree with an odd number of several items and get stats." do
    ks = %w(jim jason bob yoko sam sarah dillenger escape plan frank will)    
    arr = ks.zip(Array.new(ks.size, true))
    t = Hipe::SimpleBTree[arr]
    t.stats.should == {:height=>4, :min_height=>4, :num_nodes=>11}
  end
  
end
