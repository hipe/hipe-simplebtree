module Hipe
  # Experimental *simple* b-tree -- the only purpose of this for now is to 
  # impleement a method for "find the index of the first element in the array 
  # that is greater than a provided element." It won't be efficient or useful
  # for adding/removes lots of nodes, only for providing the above service.
  # It is presumed that it will be slower than RBTrees (Red-Black tree), but 
  # faster than scanning all the elements of a sorted array to find this index.
  class SimpleBTree

    # @param [Array] array an array sorted or not sorted whose values represent the values
    #   of the nodes of the tree.  Values need not be unique.
    # @yield [left,right] a code block that stipulates your comparison 
    #   algorithm for using in sorting, exactly like Array#sort
    # @example 
    #   tree = Hipe::SimpleBTree.new(['alpha','gamma','beta']){|x,y| x <=> y}
    #   puts tree.to_array
    def initialize(array=nil, &sorter)
      @array = array || []
      @sorter = sorter || Proc.new {|left,right| left <=> right}
      @sorted = false      
    end
    
    def to_array
      sort!
      @array.clone
    end
    
    # @private
    # left public for testing only
    def sort!
      unless @sorted
        @array.sort!(&@sorter)
        @sorted = true
      end
    end
  end
end