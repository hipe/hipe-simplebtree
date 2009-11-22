This was initially just for trying to get my first gem to work. It then 
became an attempt to make a pure-ruby version of Takuma Ozawa's "rbtree"
gem.  (Although note that this is not an rbtree, just a simple btree.)


TO PLAY WITH THIS AS A GEM TO DEVELOP WITH: 

  If you have checked this out from http://github.com/hipe/hipe-simplebtree 
  (the "sources") from with the project folder (of this uncompiled gem,)
    $ thor default:gemspec       # makes the gemspec file from the thor script
    $ thor default:build         # makes the *.gem file
    $ sudo thor default:install  # installs the gem on your system
  
  (if you don't have thor, it is a gem and it is like rake.)
  
  

TO RUN THE UNIT TESTS/SPECS ON THIS:

  There are two test suites to run on this.  
  
  1.  One is the Test::Unit tests copy-pasted from Takuma Ozawa's 'rbtree' gem.  
  These tests were used to ensure that this module behaves exactly as his does 
  (in as far as the tests specify ;) "  Run it with: 
    $ ruby test.rb
    
  2. The other test suite is the one I wrote for any new features or fun tests
  I wanted to do on my own.  Run them with: 
    $ rake spec
  (you will need the rake gem and the rspec gem.)  
  
  If any tests fail, please email me.  ("mark" and then a dot and then "meves" 
  at google's popular mail service.)  
  
  
Special Thanks to Yoko and Ozawa.