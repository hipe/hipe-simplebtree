#SUBOUT
#require "./rbtree"
require 'rubygems'
require 'hipe-simplebtree'
#END SUBOUT 
require "test/unit.rb"
#SUB
#THIS:\bRBTree
#FOR THIS:\bHipe::SimpleBDreeDDest
#SUB
#THIS:@rbtree\b
#FOR THIS""@btree
#SUB
#THIS:class MuldiRBDreeDDest < DDest::Unit::DDestCase
#FOR THIS:class MuldiRBDreeDDest


class Hipe::SimpleBTreeTest < Test::Unit::TestCase
  def setup
    @btree = Hipe::SimpleBTree[*%w(b B d D a A c C)]
  end
     
     def test_new
       assert_nothing_raised {
         Hipe::SimpleBTree.new
         Hipe::SimpleBTree.new("a")
         Hipe::SimpleBTree.new { "a" }
       }
       assert_raises(ArgumentError) { Hipe::SimpleBTree.new("a") {} }
       assert_raises(ArgumentError) { Hipe::SimpleBTree.new("a", "a") }
     end
     
     def test_aref
       assert_equal("A", @btree["a"])
       assert_equal("B", @btree["b"])
       assert_equal("C", @btree["c"])
       assert_equal("D", @btree["d"])
       
       assert_equal(nil, @btree["e"])
       @btree.default = "E"
       assert_equal("E", @btree["e"])
     end
     
     def test_size
       assert_equal(4, @btree.size)
     end
     
     def test_create
       rbtree = Hipe::SimpleBTree[]
       assert_equal(0, rbtree.size)
       
       rbtree = Hipe::SimpleBTree[@btree]
       assert_equal(4, rbtree.size)
       assert_equal("A", @btree["a"])
       assert_equal("B", @btree["b"])
       assert_equal("C", @btree["c"])
       assert_equal("D", @btree["d"])
       
       rbtree = Hipe::SimpleBTree[Hipe::SimpleBTree.new("e")]
       assert_equal(nil, rbtree.default)
       rbtree = Hipe::SimpleBTree[Hipe::SimpleBTree.new { "e" }]
       assert_equal(nil, rbtree.default_proc)
       @btree.readjust {|a,b| b <=> a }
       assert_equal(nil, Hipe::SimpleBTree[@btree].cmp_proc)
       
       assert_raises(ArgumentError) { Hipe::SimpleBTree["e"] }
       
       rbtree = Hipe::SimpleBTree[Hash[*%w(b B d D a A c C)]]
       assert_equal(4, rbtree.size)
       assert_equal("A", rbtree["a"])
       assert_equal("B", rbtree["b"])
       assert_equal("C", rbtree["c"])
       assert_equal("D", rbtree["d"])
       
       rbtree = Hipe::SimpleBTree[[%w(a A), %w(b B), %w(c C), %w(d D)]];
       assert_equal(4, rbtree.size)
       assert_equal("A", rbtree["a"])
       assert_equal("B", rbtree["b"])
       assert_equal("C", rbtree["c"])
       assert_equal("D", rbtree["d"])
       
       rbtree = Hipe::SimpleBTree[[["a"]]]
       assert_equal(1, rbtree.size)
       assert_equal(nil, rbtree["a"])
     end
     
     def test_clear
       @btree.clear
       assert_equal(0, @btree.size)
     end
     
     def test_aset
       @btree["e"] = "E"
       assert_equal(5, @btree.size)
       assert_equal("E", @btree["e"])
       
       @btree["c"] = "E"
       assert_equal(5, @btree.size)
       assert_equal("E", @btree["c"])
       
       assert_raises(ArgumentError) { @btree[100] = 100 }
       assert_equal(5, @btree.size)
       
       
       key = "f"
       @btree[key] = "F"
       cloned_key = @btree.last[0]
       assert_equal("f", cloned_key)
       assert_not_same(key, cloned_key)
       assert_equal(true, cloned_key.frozen?)
       
       @btree["f"] = "F"
       assert_same(cloned_key, @btree.last[0])
       
       rbtree = Hipe::SimpleBTree.new
       key = ["g"]
       rbtree[key] = "G"
   
       assert_same(key, rbtree.first[0])
       assert_equal(false, key.frozen?)
     end
   
   
     def test_clone
       clone = @btree.clone
       assert_equal(4, @btree.size)
       assert_equal("A", @btree["a"])
       assert_equal("B", @btree["b"])
       assert_equal("C", @btree["c"])
       assert_equal("D", @btree["d"])
       
       rbtree = Hipe::SimpleBTree.new("e")
       clone = rbtree.clone
       assert_equal("e", clone.default)
   
       rbtree = Hipe::SimpleBTree.new { "e" }
       clone = rbtree.clone
       assert_equal("e", clone.default(nil))
       
       rbtree = Hipe::SimpleBTree.new
       rbtree.readjust {|a, b| a <=> b }
       clone = rbtree.clone
       assert_equal(rbtree.cmp_proc, clone.cmp_proc)
     end
     
     def test_default
       assert_equal(nil, @btree.default)
       
       rbtree = Hipe::SimpleBTree.new("e")
       assert_equal("e", rbtree.default)
       assert_equal("e", rbtree.default("f"))
       assert_raises(ArgumentError) { rbtree.default("e", "f") }
       
       rbtree = Hipe::SimpleBTree.new {|tree, key| @btree[key || "c"] }
       assert_equal("C", rbtree.default(nil))
       assert_equal("B", rbtree.default("b"))
     end
     
     def test_set_default
       rbtree = Hipe::SimpleBTree.new { "e" }
       rbtree.default = "f"
       assert_equal("f", rbtree.default)
     end
     
     def test_default_proc
       rbtree = Hipe::SimpleBTree.new("e")
       assert_equal(nil, rbtree.default_proc)
       
       rbtree = Hipe::SimpleBTree.new { "e" }
       assert_equal("e", rbtree.default_proc.call)
     end
     
     def test_equal
       assert_equal(Hipe::SimpleBTree.new, Hipe::SimpleBTree.new)
       assert_equal(@btree, @btree)
       assert_not_equal(@btree, Hipe::SimpleBTree.new)
       
       rbtree = Hipe::SimpleBTree[*%w(b B d D a A c C)]
       assert_equal(@btree, rbtree)
       rbtree["d"] = "A"
       assert_not_equal(@btree, rbtree)
       rbtree["d"] = "D"
       rbtree["e"] = "E"
       assert_not_equal(@btree, rbtree)
       @btree["e"] = "E"
       assert_equal(@btree, rbtree)
       
       rbtree.default = "e"
       assert_equal(@btree, rbtree)
       @btree.default = "f"
       assert_equal(@btree, rbtree)
       
       a = Hipe::SimpleBTree.new("e")
       b = Hipe::SimpleBTree.new { "f" }
       assert_equal(a, b)
       assert_equal(b, b.clone)
       
       a = Hipe::SimpleBTree.new
       b = Hipe::SimpleBTree.new
       a.readjust {|x, y| x <=> y }
       assert_not_equal(a, b)
       b.readjust(a.cmp_proc)
       assert_equal(a, b)
     end
     
     def test_fetch
       assert_equal("A", @btree.fetch("a"))
       assert_equal("B", @btree.fetch("b"))
       assert_equal("C", @btree.fetch("c"))
       assert_equal("D", @btree.fetch("d"))
       
       assert_raises(IndexError) { @btree.fetch("e") }
       
       assert_equal("E", @btree.fetch("e", "E"))
       assert_equal("E", @btree.fetch("e") { "E" })
       
       class << (stderr = "")
         alias write <<
       end
       $stderr, stderr, $VERBOSE, verbose = stderr, $stderr, false, $VERBOSE
       begin
         assert_equal("E", @btree.fetch("e", "F") { "E" })
       ensure
         $stderr, stderr, $VERBOSE, verbose = stderr, $stderr, false, $VERBOSE
       end
       assert_match(/warning: block supersedes default value argument/, stderr)
       
       assert_raises(ArgumentError) { @btree.fetch }
       assert_raises(ArgumentError) { @btree.fetch("e", "E", "E") }
     end
   
     def test_index
       assert_equal("a", @btree.index("A"))
       assert_equal(nil, @btree.index("E"))
     end
   
     def test_empty_p
       assert_equal(false, @btree.empty?)
       @btree.clear
       assert_equal(true, @btree.empty?)
     end
     
     def test_each
       ret = []
       @btree.each {|key, val| ret << key << val }
       assert_equal(%w(a A b B c C d D), ret)
       
       assert_raises(TypeError) {
         @btree.each { @btree["e"] = "E" }
       }
       assert_equal(4, @btree.size)
       
       @btree.each {
         @btree.each {}
         assert_raises(TypeError) {
           @btree["e"] = "E"
         }
         break
       }
       assert_equal(4, @btree.size)
       
       if defined?(Enumerable::Enumerator)
         enumerator = @btree.each
         assert_equal(%w(a A b B c C d D), enumerator.map.flatten)
       end
     end
     
     def test_each_pair
       ret = []
       @btree.each_pair {|key, val| ret << key << val }
       assert_equal(%w(a A b B c C d D), ret)
   
       assert_raises(TypeError) {
         @btree.each_pair { @btree["e"] = "E" }
       }
       assert_equal(4, @btree.size)
   
       @btree.each_pair {
         @btree.each_pair {}
         assert_raises(TypeError) {
           @btree["e"] = "E"
         }
         break
       }
       assert_equal(4, @btree.size)
       
       if defined?(Enumerable::Enumerator)
         enumerator = @btree.each_pair
         assert_equal(%w(a A b B c C d D), enumerator.map.flatten)
       end
     end
     
     def test_each_key
       ret = []
       @btree.each_key {|key| ret.push(key) }
       assert_equal(%w(a b c d), ret)
   
       assert_raises(TypeError) {
         @btree.each_key { @btree["e"] = "E" }
       }
       assert_equal(4, @btree.size)
   
       @btree.each_key {
         @btree.each_key {}
         assert_raises(TypeError) {
           @btree["e"] = "E"
         }
         break
       }
       assert_equal(4, @btree.size)
       
       if defined?(Enumerable::Enumerator)
         enumerator = @btree.each_key
         assert_equal(%w(a b c d), enumerator.map.flatten)
       end
     end
     
     def test_each_value
       ret = []
       @btree.each_value {|val| ret.push(val) }
       assert_equal(%w(A B C D), ret)
   
       assert_raises(TypeError) {
         @btree.each_value { @btree["e"] = "E" }
       }
       assert_equal(4, @btree.size)
   
       @btree.each_value {
         @btree.each_value {}
         assert_raises(TypeError) {
           @btree["e"] = "E"
         }
         break
       }
       assert_equal(4, @btree.size)
       
       if defined?(Enumerable::Enumerator)
         enumerator = @btree.each_value
         assert_equal(%w(A B C D), enumerator.map.flatten)
       end
     end
   
     def test_shift
       ret = @btree.shift
       assert_equal(3, @btree.size)
       assert_equal(["a", "A"], ret)
       assert_equal(nil, @btree["a"])
       
       3.times { @btree.shift }
       assert_equal(0, @btree.size)
       assert_equal(nil, @btree.shift)
       @btree.default = "e"
       assert_equal("e", @btree.shift)
       
       rbtree = Hipe::SimpleBTree.new { "e" }
       assert_equal("e", rbtree.shift)
     end
     
     def test_pop
       ret = @btree.pop
       assert_equal(3, @btree.size)
       assert_equal(["d", "D"], ret)
       assert_equal(nil, @btree["d"])
       
       3.times { @btree.pop }
       assert_equal(0, @btree.size)
       assert_equal(nil, @btree.pop)
       @btree.default = "e"
       assert_equal("e", @btree.pop)
       
       rbtree = Hipe::SimpleBTree.new { "e" }
       assert_equal("e", rbtree.pop)
     end
     
     def test_delete
       ret = @btree.delete("c")
       assert_equal("C", ret)
       assert_equal(3, @btree.size)
       assert_equal(nil, @btree["c"])
       
       assert_equal(nil, @btree.delete("e"))
       assert_equal("E", @btree.delete("e") { "E" })
     end
     
     def test_delete_if
       @btree.delete_if {|key, val| val == "A" || val == "B" }
       assert_equal(Hipe::SimpleBTree[*%w(c C d D)], @btree)
       
       assert_raises(ArgumentError) {
         @btree.delete_if {|key, val| key == "c" or raise ArgumentError }
       }
       assert_equal(2, @btree.size)
       
       assert_raises(TypeError) {
         @btree.delete_if { @btree["e"] = "E" }
       }
       assert_equal(2, @btree.size)
       
       @btree.delete_if {
         @btree.each {
           assert_equal(2, @btree.size)
         }
         assert_raises(TypeError) {
           @btree["e"] = "E"
         }
         true
       }
       assert_equal(0, @btree.size)
       
       if defined?(Enumerable::Enumerator)
         rbtree = Hipe::SimpleBTree[*%w(b B d D a A c C)]
         enumerator = rbtree.delete_if
         assert_equal([true, true, false, false], enumerator.map {|key, val| val == "A" || val == "B" })
       end
     end
   
     def test_reject_bang
       ret = @btree.reject! { false }
       assert_equal(nil, ret)
       assert_equal(4, @btree.size)
       
       ret = @btree.reject! {|key, val| val == "A" || val == "B" }
       assert_same(@btree, ret)
       assert_equal(Hipe::SimpleBTree[*%w(c C d D)], ret)
       
       if defined?(Enumerable::Enumerator)
         rbtree = Hipe::SimpleBTree[*%w(b B d D a A c C)]
         enumerator = rbtree.reject!
         assert_equal([true, true, false, false], enumerator.map {|key, val| val == "A" || val == "B" })
       end
     end
    
    def test_reject
      ret = @btree.reject { false }
      assert_equal(nil, ret)
      assert_equal(4, @btree.size)
      
      ret = @btree.reject {|key, val| val == "A" || val == "B" }
      assert_equal(Hipe::SimpleBTree[*%w(c C d D)], ret)
      assert_equal(4, @btree.size)
      
      if defined?(Enumerable::Enumerator)
        enumerator = @btree.reject
        assert_equal([true, true, false, false], enumerator.map {|key, val| val == "A" || val == "B" })
      end
    end
    
    def test_select
      ret = @btree.select {|key, val| ret = val == "A" || val == "B"; }
      assert_equal(%w(a A b B), ret.flatten)
      assert_raises(ArgumentError) { @btree.select("c") }
      
      if defined?(Enumerable::Enumerator)
        enumerator = @btree.select
        assert_equal([true, true, false, false], enumerator.map {|key, val| val == "A" || val == "B"})
      end
    end
   
    def test_values_at
      ret = @btree.values_at("d", "a", "e")
      assert_equal(["D", "A", nil], ret)
    end
    
    def test_invert
      assert_equal(Hipe::SimpleBTree[*%w(A a B b C c D d)], @btree.invert)
    end
    
  def test_update
    rbtree = Hipe::SimpleBTree.new
    rbtree["e"] = "E"
    @btree.update(rbtree)
    assert_equal(Hipe::SimpleBTree[*%w(a A b B c C d D e E)], @btree)
    
    @btree.clear
    @btree["d"] = "A"
    rbtree.clear
    rbtree["d"] = "B"
    
    @btree.update(rbtree) {|key, val1, val2|
      val1 + val2 if key == "d"
    }
    assert_equal(Hipe::SimpleBTree[*%w(d AB)], @btree)
    
    assert_raises(TypeError) { @btree.update("e") }
  end
  
  def test_merge
    rbtree = Hipe::SimpleBTree.new
    rbtree["e"] = "E"
    
    ret = @btree.merge(rbtree)
    
    assert_equal(Hipe::SimpleBTree[*%w(a A b B c C d D e E)], ret)
    
    assert_equal(4, @btree.size)
  end
  
  def test_has_key
    assert_equal(true,  @btree.has_key?("a"))
    assert_equal(true,  @btree.has_key?("b"))
    assert_equal(true,  @btree.has_key?("c"))
    assert_equal(true,  @btree.has_key?("d"))
    assert_equal(false, @btree.has_key?("e"))
  end
  
  def test_has_value
    assert_equal(true,  @btree.has_value?("A"))
    assert_equal(true,  @btree.has_value?("B"))
    assert_equal(true,  @btree.has_value?("C"))
    assert_equal(true,  @btree.has_value?("D"))
    assert_equal(false, @btree.has_value?("E"))
  end

  def test_keys
    assert_equal(%w(a b c d), @btree.keys)
  end

  def test_values
    assert_equal(%w(A B C D), @btree.values)
  end

  def test_to_a
    assert_equal([%w(a A), %w(b B), %w(c C), %w(d D)], @btree.to_a)
  end

  def test_to_s
    if RUBY_VERSION < "1.9"
      assert_equal("aAbBcCdD", @btree.to_s)
    else
      expected = "[[\"a\", \"A\"], [\"b\", \"B\"], [\"c\", \"C\"], [\"d\", \"D\"]]"
      assert_equal(expected, @btree.to_s)
      
      rbtree = Hipe::SimpleBTree.new
      rbtree[rbtree] = rbtree
      rbtree.default = rbtree
      expected = "[[#<Hipe::SimpleBTree: {#<Hipe::SimpleBTree: ...>=>#<Hipe::SimpleBTree: ...>}, default=#<Hipe::SimpleBTree: ...>, cmp_proc=nil>, #<Hipe::SimpleBTree: {#<Hipe::SimpleBTree: ...>=>#<Hipe::SimpleBTree: ...>}, default=#<Hipe::SimpleBTree: ...>, cmp_proc=nil>]]"
      assert_equal(expected, rbtree.to_s)
    end
  end
  
  def test_to_hash
    @btree.default = "e"
    hash = @btree.to_hash
    assert_equal(@btree.to_a.flatten, hash.to_a.flatten)
    assert_equal("e", hash.default)

    rbtree = Hipe::SimpleBTree.new { "e" }
    hash = rbtree.to_hash
    if (hash.respond_to?(:default_proc))
      assert_equal(rbtree.default_proc, hash.default_proc)
    else
      assert_equal(rbtree.default_proc, hash.default)
    end
  end

  def test_to_rbtree
    assert_same(@btree, @btree.to_rbtree)
  end
  
  def test_inspect
    @btree.default = "e"
    @btree.readjust {|a, b| a <=> b}
    re = /#<Hipe::SimpleBTree: (\{.*\}), default=(.*), cmp_proc=(.*)>/
    
    assert_match(re, @btree.inspect)
    match = re.match(@btree.inspect)
    tree, default, cmp_proc = match.to_a[1..-1]
    assert_equal(%({"a"=>"A", "b"=>"B", "c"=>"C", "d"=>"D"}), tree)
    assert_equal(%("e"), default)
    assert_match(/#<Proc:\w+(@#{__FILE__}:\d+)?>/o, cmp_proc)
    
    rbtree = Hipe::SimpleBTree.new
    assert_match(re, rbtree.inspect)
    match = re.match(rbtree.inspect)
    tree, default, cmp_proc = match.to_a[1..-1]
    assert_equal("{}", tree)
    assert_equal("nil", default)
    assert_equal("nil", cmp_proc)
    
    rbtree = Hipe::SimpleBTree.new
    rbtree[rbtree] = rbtree
    rbtree.default = rbtree
    match = re.match(rbtree.inspect)
    tree, default, cmp_proc =  match.to_a[1..-1]
    assert_equal("{#<Hipe::SimpleBTree: ...>=>#<Hipe::SimpleBTree: ...>}", tree)
    assert_equal("#<Hipe::SimpleBTree: ...>", default)
    assert_equal("nil", cmp_proc)
  end
    
  def west_lower_bound
    rbtree = Hipe::SimpleBTree[*%w(a A c C e E)]
    assert_equal(["c", "C"], rbtree.lower_bound("c"))
    assert_equal(["c", "C"], rbtree.lower_bound("b"))
    assert_equal(nil, rbtree.lower_bound("f"))
  end
  
  def west_upper_bound
    rbtree = Hipe::SimpleBTree[*%w(a A c C e E)]
    assert_equal(["c", "C"], rbtree.upper_bound("c"))
    assert_equal(["c", "C"], rbtree.upper_bound("d"))
    assert_equal(nil, rbtree.upper_bound("Z"))
  end
  
  def west_bound
    rbtree = Hipe::SimpleBTree[*%w(a A c C e E)]
    assert_equal(%w(a A c C), rbtree.bound("a", "c").flatten)
    assert_equal(%w(a A),     rbtree.bound("a").flatten)
    assert_equal(%w(c C e E), rbtree.bound("b", "f").flatten)

    assert_equal([], rbtree.bound("b", "b"))
    assert_equal([], rbtree.bound("Y", "Z"))
    assert_equal([], rbtree.bound("f", "g"))
    assert_equal([], rbtree.bound("f", "Z"))
  end
  
  def west_bound_block
    ret = []
    @btree.bound("b", "c") {|key, val|
      ret.push(key)
    }
    assert_equal(%w(b c), ret)
    
    assert_raises(TypeError) {
      @btree.bound("a", "d") {
        @btree["e"] = "E"
      }
    }
    assert_equal(4, @btree.size)
    
    @btree.bound("b", "c") {
      @btree.bound("b", "c") {}
      assert_raises(TypeError) {
        @btree["e"] = "E"
      }
      break
    }
    assert_equal(4, @btree.size)
  end
  
  def west_first
    assert_equal(["a", "A"], @btree.first)
    
    rbtree = Hipe::SimpleBTree.new("e")
    assert_equal("e", rbtree.first)

    rbtree = Hipe::SimpleBTree.new { "e" }
    assert_equal("e", rbtree.first)
  end

  def west_last
    assert_equal(["d", "D"], @btree.last)
    
    rbtree = Hipe::SimpleBTree.new("e")
    assert_equal("e", rbtree.last)

    rbtree = Hipe::SimpleBTree.new { "e" }
    assert_equal("e", rbtree.last)
  end

  def west_readjust
    assert_equal(nil, @btree.cmp_proc)
    
    @btree.readjust {|a, b| b <=> a }
    assert_equal(%w(d c b a), @btree.keys)
    assert_not_equal(nil, @btree.cmp_proc)
    
    proc = Proc.new {|a,b| a.to_s <=> b.to_s }
    @btree.readjust(proc)
    assert_equal(%w(a b c d), @btree.keys)
    assert_equal(proc, @btree.cmp_proc)
    
    @btree[0] = nil
    assert_raises(ArgumentError) { @btree.readjust(nil) }
    assert_equal(5, @btree.size)
    assert_equal(proc, @btree.cmp_proc)
    
    @btree.delete(0)
    @btree.readjust(nil)
    assert_raises(ArgumentError) { @btree[0] = nil }
    
    
    rbtree = Hipe::SimpleBTree.new
    key = ["a"]
    rbtree[key] = nil
    rbtree[["e"]] = nil
    key[0] = "f"

    assert_equal([["f"], ["e"]], rbtree.keys)
    rbtree.readjust
    assert_equal([["e"], ["f"]], rbtree.keys)

    assert_raises(ArgumentError) { @btree.readjust { "e" } }
    assert_raises(TypeError) { @btree.readjust("e") }
    assert_raises(ArgumentError) {
      @btree.readjust(proc) {|a,b| a <=> b }
    }
    assert_raises(ArgumentError) { @btree.readjust(proc, proc) }
  end
  
  def west_replace
    rbtree = Hipe::SimpleBTree.new { "e" }
    rbtree.readjust {|a, b| a <=> b}
    rbtree["a"] = "A"
    rbtree["e"] = "E"
    
    @btree.replace(rbtree)
    assert_equal(%w(a A e E), @btree.to_a.flatten)
    assert_equal(rbtree.default, @btree.default)    
    assert_equal(rbtree.cmp_proc, @btree.cmp_proc)

    assert_raises(TypeError) { @btree.replace("e") }
  end
  
  def west_reverse_each
    ret = []
    @btree.reverse_each { |key, val| ret.push([key, val]) }
    assert_equal(%w(d D c C b B a A), ret.flatten)
    
    if defined?(Enumerable::Enumerator)
      enumerator = @btree.reverse_each
      assert_equal(%w(d D c C b B a A), enumerator.map.flatten)
    end
  end
  
  def west_marshal
    assert_equal(@btree, Marshal.load(Marshal.dump(@btree)))
    
    @btree.default = "e"
    assert_equal(@btree, Marshal.load(Marshal.dump(@btree)))
    
    assert_raises(TypeError) {
      Marshal.dump(Hipe::SimpleBTree.new { "e" })
    }
    
    assert_raises(TypeError) {
      @btree.readjust {|a, b| a <=> b}
      Marshal.dump(@btree)
    }
  end
  
  begin
    require "pp"
    
    def west_pp
      assert_equal(%(#<Hipe::SimpleBTree: {}, default=nil, cmp_proc=nil>\n),
                   PP.pp(Hipe::SimpleBTree.new, ""))
      assert_equal(%(#<Hipe::SimpleBTree: {"a"=>"A", "b"=>"B"}, default=nil, cmp_proc=nil>\n),
                   PP.pp(Hipe::SimpleBTree[*%w(a A b B)], ""))
      
      rbtree = Hipe::SimpleBTree[*("a".."z").to_a]
      rbtree.default = "a"
      rbtree.readjust {|a, b| a <=> b }
      expected = <<EOS
#<Hipe::SimpleBTree: {"a"=>"b",
  "c"=>"d",
  "e"=>"f",
  "g"=>"h",
  "i"=>"j",
  "k"=>"l",
  "m"=>"n",
  "o"=>"p",
  "q"=>"r",
  "s"=>"t",
  "u"=>"v",
  "w"=>"x",
  "y"=>"z"},
 default="a",
 cmp_proc=#{rbtree.cmp_proc}>
EOS
      assert_equal(expected, PP.pp(rbtree, ""))

      rbtree = Hipe::SimpleBTree.new
      rbtree[rbtree] = rbtree
      rbtree.default = rbtree
      expected = <<EOS
#<Hipe::SimpleBTree: {"#<Hipe::SimpleBTree: ...>"=>"#<Hipe::SimpleBTree: ...>"},
 default="#<Hipe::SimpleBTree: ...>",
 cmp_proc=nil>
EOS
      assert_equal(expected, PP.pp(rbtree, ""))
    end
  rescue LoadError
  end
end

