require 'ruby-debug'

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
    end

    # @see Hash::[]
    def self.[](*args)
      self.new.send(:init_with_brackets, args)
    end

    attr_accessor :cmp_proc

    # the unless method_defined? below are so we can reload this file from irb

    alias_method :hash_set, %s{[]=}      unless method_defined? :hash_set

    alias_method :hash_delete, :delete   unless method_defined? :hash_delete
    
    alias_method :hash_keys, :keys       unless method_defined? :hash_keys

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

    def readjust proc1=nil, &proc2
      raise ArgumentError.new("wrong number of arguments - 2 for 1") if proc2 && proc1
      @cmp_proc = proc1 || proc2
      sort_keys!
    end

    def first
      k = @sorted_keys.first
      clone = get_cloned_key k
      [clone, self[k]]
    end

    def last
      k = @sorted_keys.last
      clone = get_cloned_key k
      [clone, self[k]]
    end

    def get_cloned_key key
      @clones ||= {}
      unless @clones.has_key? key
        # not sure what the test is trying to accomplish here
        @clones[key] = key.instance_of?(String) ? key.clone.freeze : key
      end
      @clones[key]
    end

    def == (other)
      super && @sorted_keys == other.sorted_keys && @cmp_proc == other.cmp_proc
    end

    def each &proc
      return _enumerate(proc){ |k| [k, self[k]] }
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
        Hipe::SimpleBTree[eaches]  #* we don't know what to do about default & default proc & sort :{note4}
      else
        each
      end
    end

    def reject &proc
      return each unless block_given?
      guy = select{ |k,v| ! proc.call(k,v) }
      ( guy.size == self.size ) ? nil : guy
    end

    def ERASE_pretty_print(pp)
      els = []
      @sorted_keys.each do |k|
        PP.singleline_pp(k, s=''); s << '=>'; PP.pp(self[k],x=''); s<<x.strip;
        els << s
      end
      str = els.join('; ')
      str = els.join(";\n") if str.length > 79
      pp.pp 'gim "famour" '  # %<{#{str}}>
    end

    def []= k, value
      raise TypeError.new("can't modify simplebtree in iteration") if @locked_stack > 0
      use_key = k
      if (!has_key?(k))
        my_keys = @sorted_keys.dup # only because ..
        my_keys << use_key
        my_keys.sort!(&@cmp_proc) # we want this to throw type comparison error
        @sorted_keys = my_keys
      end
      super use_key, value
    end

    def pop
      if @sorted_keys.size == 0
        ret = default_proc ? default_proc.call(self, nil) : default
      else
        key = @sorted_keys.pop
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
                                                  
    def clear;      super; @sorted_keys.clear;    end
                                                  
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
    
    alias_method :hash_inspect, :inspect unless method_defined? :hash_inspect
    
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

    protected

    attr_accessor :sorted_keys

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

    def _enumerate(their_proc=nil,&my_proc)
      return @sorted_keys.map{|k| [k,self[k]]} if their_proc.nil?
      @locked_stack += 1
      @sorted_keys.each do |k|
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
  end # class
end # Hipe


# {note1}: DONE consider making this descend from Hash
# {node2}: when to copy over cmp_proc et all? when not to?
# {note3}: DONE reafactor iterators to all use _enumerate
# {note4}: (deep copy questions)
# {note5}: when we are running this from irb we only want to do alias-method once