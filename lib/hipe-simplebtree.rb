module Hipe
  # Experimental *simple* b-tree -- the only purpose of this for now is to
  # implement a method for "find the lowest key that is greater than the provided key"
  # (or find the greatest key that is lower than a provided key)
  # It won't be efficient or useful
  # for adding/removes lots of nodes, only for providing the above service.
  # It is presumed that it will be slower than RBTrees (Red-Black tree), but
  # faster than scanning all the elements of a sorted array to find this index.

  class SimpleBTree < Hash

    # @see Hash#new
    def initialize(*args,&block)
      @locked_stack = 0
      @insepcting = false
      @autosort = true
      super
      @cmp_proc = nil
      @sorted_keys = [] # with a new hash it is always empty, right? (we don't have [] literal construtors)
      @tree = nil
    end

    # @see Hash::[]
    def self.[](*args)
      self.new.send(:init_with_brackets, args)
    end

    attr_accessor :cmp_proc
    
    def cmp_proc= proc
      raise TypeError.new(%{must be proc not "#{proc.class}"}) unless (@cmp_proc = proc).instance_of?(Proc)||(!proc)
      sort_keys!
    end

    # the unless method_defined? below are so we can reload this file from irb
    protected 
      alias_method :hash_set, %s{[]=}      unless method_defined? :hash_set
      alias_method :hash_delete, :delete   unless method_defined? :hash_delete
      alias_method :hash_keys, :keys       unless method_defined? :hash_keys
      alias_method :hash_replace, :replace unless method_defined? :hash_replace    
      alias_method :hash_inspect, :inspect unless method_defined? :hash_inspect
      
    public

    def clone
      clone = self.class.new( &default_proc )
      clone.cmp_proc = self.cmp_proc
      clone.default = self.default unless clone.default_proc # very important! 1 hr. bug
      clone.update_with_hash self
      clone
    end

    def default *args
      ret  =
      if 0==args.size then super
      elsif 2<=args.size then raise ArgumentError.new("expecting 0 or 1 had #{args.size}")
      elsif default_proc.nil? then super
      else
        self.default_proc.call self, args[0]
      end
      ret
    end

    def readjust *args, &proc2
      size = args.size + (proc2 ? 1 : 0)
      raise ArgumentError.new("wrong number of arguments - #{size} for 1") if size > 1
      new_proc = (args.size > 0 && args[0].nil?) ? default_cmp_proc : (proc2 || args[0])
      my_keys = hash_keys
      # try the sort before doing any permanant change because it might throw type comparison error      
      my_keys.sort!(&new_proc) 
      @sorted_keys = my_keys
      @cmp_proc = new_proc
    end

    def default_cmp_proc
      return Proc.new{|x,y| x <=> y}
    end

    def _first_or_last(which)
      if @sorted_keys.size > 0
        k = @sorted_keys.send(which)
        [get_cloned_key(k), self[k]]
      else
        default_proc ? default_proc.call(self) : default
      end
    end
        
    def first; _first_or_last(:first); end

    def last; _first_or_last(:last); end

    def get_cloned_key key
      @clones ||= {}
      unless @clones.has_key? key
        # not sure what the test is trying to accomplish here
        @clones[key] = key.instance_of?(String) ? key.clone.freeze : key
      end
      @clones[key]
    end

    def == (other)
      super && @sorted_keys == other.send(:sorted_keys) && @cmp_proc == other.cmp_proc
    end

    def each &proc
      return _enumerate(proc){ |k| [k, self[k]] }
    end
    
    def reverse_each &proc
      return _enumerate(proc,@sorted_keys.reverse){ |k| [k, self[k]] }
    end

    alias_method :each_pair, :each

    def each_key &proc
      return _enumerate(proc){ |k| k } if block_given?
      @sorted_keys.map{|k| [k] }.each
    end

    def each_value &proc
      return _enumerate(proc){|k| self[k]} if block_given?
      @sorted_keys.map{|k| [self[k]] }.each
    end

    def delete_if
      return each unless block_given?      
      ks = []
      _enumerate(Proc.new{|k,v| ks << k if yield(k,v) }){|k| [k,self[k]]}
      ks.each { |k| hash_delete k }
      if ks.size > 0
        sort_keys!
        self
      else
        nil
      end
    end
    
    alias_method %s{reject!}, :delete_if    

    def select &proc
      if block_given?
        eaches = []
        @sorted_keys.each { |k| eaches << [k,self[k]] if proc.call(k,self[k]) }
        Hipe::SimpleBTree[eaches]  #* we don't know what to do about default & default proc & sort # note 4
      else
        each
      end
    end

    def reject &proc
      return each unless block_given?
      guy = select{ |k,v| ! proc.call(k,v) }
      ( guy.size == self.size ) ? nil : guy
    end
  
    def pretty_print(q)
      mybuff = ''
      if @inspecting
        mybuff << %["#<#{self.class}: ...>"]
      else
        mybuff << %[#<#{self.class}: ]
        @inspecting = true;
        els = @sorted_keys.map do |k|  # @todo learn more about PP to clean this up
          PP.pp(k, s='');s.chop!; s << '=>'; PP.pp(self[k],x=''); s<<x.strip!;
          s
        end
        str = els.join(', ');     br  = " ";      
        if str.length > 79      
          str = els.join(",\n  ");  br  = "\n ";
        end
        br = "\n " if str.include? self.class.to_s # total hack to get it to pass the tests
        PP.pp(default,def_s='')
        PP.pp(cmp_proc,cmp_s='')
        mybuff << %({#{str}},#{br}default=#{def_s.chop},#{br}cmp_proc=#{cmp_s.chop}>)
        @inspecting = false
      end
      q.text(mybuff)
    end
    
    def inspect
      if @inspecting
        %{#<#{self.class.name}: ...>}
      else
        @inspecting = true
        # /#<Hipe::SimpleBTree: (\{.*\}), default=(.*), cmp_proc=(.*)>/      
        ret = %[#<#{self.class.name}: #{hash_inspect}, default=#{default.inspect}, cmp_proc=#{cmp_proc.inspect}>]
        @inspecting = false
        ret
      end
    end    

    def []= k, value
      raise TypeError.new("can't modify simplebtree in iteration") if @locked_stack > 0
      use_key = k
      if (!has_key?(k))
        my_keys = @sorted_keys.dup # the unit test requires this
        my_keys << use_key
        my_keys.sort!(&@cmp_proc) # we want this to throw type comparison error
        @sorted_keys = my_keys
        @tree = nil # we loose a lot of sorted data when we add just one element.  # note 6.
      end
      super use_key, value
    end

    def pop
      if @sorted_keys.size == 0
        ret = default_proc ? default_proc.call(self, nil) : default
      else
        key = @sorted_keys.pop
        @tree = nil
        ret = [key, delete(key)]
      end
      return ret
    end

    def delete key
      unless has_key? key
        ret = block_given? ? yield : nil
      else
        ret = super
        sort_keys!
      end
      ret
    end

    def flatten;    each.flatten;                 end
                                                  
    def clear;      super; @sorted_keys.clear; @tree = nil;  end
                                                  
    def update x;   super x; sort_keys!;          end
                                                  
    def invert;     self.class[super];            end
                                                                                                    
    def keys;       @sorted_keys.dup;             end
    
    def values;     @sorted_keys.map{|k|self[k]}; end
    
    def to_a;       each.to_a;                    end
    
    def to_s;       to_a.to_s;                    end
    
    def merge x; #not sure why super way wouldn't work
      clone = self.class[self]
      x.each do |x,y|
        clone.hash_set(x,y)
      end
      clone.sort_keys!
      clone
    end
    
    def to_rbtree
      self # self.class[self]
    end

    def stats;             tree.stats;              end
                           
    def lower_bound key;   _bound(:lower_bound_index,key)  end
                           
    def upper_bound key;   _bound(:upper_bound_index,key)  end
    
    # @return an array containing key-value pairs between the result of lower_bound 
    # and upper_bound.  If a block is given it calls the block once for each pair. 
    def bound key1, key2=key1
     #require 'ruby-debug'
     #debugger
      return [] unless i1 = tree.lower_bound_index(key1) and i2 = tree.upper_bound_index(key2)  
      if block_given?  #note 9      
        @locked_stack += 1
        (i1..i2).each{ |i| yield @sorted_keys[i], self[@sorted_keys[i]] } 
        @locked_stack -= 1        
      end
      (i1..i2).map{ |i| [@sorted_keys[i], self[@sorted_keys[i]]] }              
    end    

    def replace tree
      unless tree.instance_of? self.class
        raise TypeError.new(%{wrong argument type #{tree.class} (expected #{self.class})}) 
      end
      hash_replace tree
      @cmp_proc = tree.cmp_proc
      @default  = tree.default
      sort_keys!
    end 
    
    def dump
      TypeError.new(%{cannot dump #{self.class} with default proc}) if @default_proc
      TypeError.new(%{cannot dump #{self.class} with compare proc}) if @cmp_proc    
      Marshal.dump(self)
    end
    
    protected

    attr_accessor :sorted_keys
    
    def _bound which, key
      index = tree.send which, key
      index ? [@sorted_keys[index], self[@sorted_keys[index]]] : nil # avoid defaults
    end

    # there are several ways to construct a SimpleBtree with the [] class method.
    # These are identical to the variants of the [] method of the Hash class, plus one more 
    # btree = SimpleBtree[{'a'=>'A', 'b'=>'B'}]       # from a literal hash
    # btree = SimpleBtree['a','A','b','B']            # will result in the same as the first example
    # btree = SimpleBtree[*['a','A','b','B']]         # a different way of saying the above
    # btree = SimpleBtree[hash]                       # deep-copy a hash object (one level deep)    
    # btree = SimpleBtree[simple_btree]               # deep-copy another one (one level deep)
    def init_with_brackets args

      if args.size!=1
        raise ArgumentError.new(%{odd number of arguments for #{self}}) unless args.size % 2 == 0
        use_as_hash = Hash[*args]
      else
        arg = args[0]
        case args[0]
          when SimpleBTree   then use_as_hash = arg
          when Hash          then use_as_hash = arg
          when Array
            # allow construction like this: btree = SimpleBTree[['a'],['b','B'],['c']..]            
            if (arg.size > 0 && arg[0].instance_of?(Array))
              arg.map!{|x| x.size == 1 ? [x[0], nil] : x }
            end
            use_as_hash = Hash[*arg.flatten] # arg might be one- or two-dimensional array
          else
            raise ArgumentError.new("Don't know how to construct with a single argument of class #{args[0].class}")
        end # case 
      end # if-else 
      update_with_hash use_as_hash          
      self
    end

    def _enumerate(their_proc=nil,keys=nil,&my_proc)
      use_keys = keys ? keys : @sorted_keys
      return use_keys.map{|k| [k,self[k]]} if their_proc.nil?
      @locked_stack += 1
      use_keys.each do |k|
        their_proc.call(*my_proc.call(k))  # do we decrement the sak
      end
      @locked_stack -= 1
      self
    end

    def update_with_hash hash
      hash.each{|k,v| hash_set(k,v) }
      sort_keys! # this of course could be improved if it's a copy of a btree
    end

    def sort_keys!
      my_keys = hash_keys
      my_keys.sort!(&@cmp_proc) #might throw type comparison error
      @sorted_keys = my_keys
    end
        
    def tree
      @tree = @sorted_keys.size == 0 ? nil : Tree.new(@sorted_keys, 0, @sorted_keys.size-1,1) if @tree.nil?
      @tree
    end
    
    # just to be incendiary, we don't distinguish among leaf nodes, branch nodes, and root nodes.
    # @private
    class Tree
      def initialize(ary, start_index, end_index, depth=0)
        @depth = depth
        width = end_index - start_index + 1
        value_index = start_index + width / 2 
        value_index -= 1 if depth % 2 == 0 and width % 2 == 0 and width != 1
        @key = ary[value_index]
        @index = value_index # careful to keep it synced with key!
        @left = (value_index == start_index) ? nil : Tree.new(ary, start_index, value_index-1, depth + 1)
        @right = (value_index == end_index)  ? nil : Tree.new(ary, value_index + 1, end_index, depth + 1)       
      end
      
      def stats
        heights = [1]
        mins = [] 
        num_nodes = 1
        ['@left','@right'].each do |name|
          child = instance_variable_get(name)
          if (child)
            stats = child.stats
            heights << stats[:height] + 1
            mins    << stats[:min_height]
            num_nodes += stats[:num_nodes] 
          end
        end
        {
          :height => heights.max,
          :min_height => (mins.size==0) ? 1 : (mins.min + 1),
          :num_nodes => num_nodes
        } 
      end #stats

      # @retrurn the index of the lowest key that is equal to or greater than the given key 
      # (inside of lower boundary). If there is no such key, returns nil.
      def lower_bound_index key
        (@key >= key) ?  ((@left && @left.lower_bound_index(key)) || @index) : (@right && @right.lower_bound_index(key))
      end

      # @return the index of the greatest key that is equal to or lower than the given key 
      # (inside of upper boundary). If there is no such key, returns nil.
      def upper_bound_index key
        (@key <= key) ?  ((@right && @right.upper_bound_index(key)) || @index) : (@left && @left.upper_bound_index(key))
      end

    end # class Tree
  end # class SimpleBTree
end # Hipe


# note 1: DONE consider making this descend from Hash
# note 2: when to copy over cmp_proc et all? when not to?
# note 3: DONE reafactor iterators to all use _enumerate
# note 4: (deep copy questions)
# note 5: when we are running this from irb we only want to do alias-method once
# note 6: i know nothing about efficient ways to re-tree
# note 7: considering making a lazy accessor for sorted_keys like tree
# note 8: these are points to consider if we ever do MultiSimpleBtree
# note 9: there are at least 3 ways we could have done this, with tradeoffs 
#    alternately among code size/duplication, performance when block given, performance
#    when block not given.  The current way is short and fast for when a block is not given.