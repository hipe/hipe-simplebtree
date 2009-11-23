# this file was originally copy-pasted from webrat's Thorfile.  Thank you Bryan Helmkamp!
module GemHelpers

  def generate_gemspec
    $LOAD_PATH.unshift(File.expand_path(File.join(File.dirname(__FILE__), "lib")))
    require "hipe-simplebtree"
    
    Gem::Specification.new do |s|    
      s.name      = 'hipe-simplebtree'
      s.version   = Hipe::SimpleBTree::VERSION
      s.required_rubygems_version = Gem::Requirement.new("> 1.3.1") if s.respond_to? :required_rubygems_version=
      s.authors   = ["Mark Meves"]
      s.email     = "mark.meves@gmail.com"
      s.homepage  = "http://github.com/hipe/hipe-simplebtree"
      s.date      = %q{2009-11-23}  
      s.summary   = %q{Simple pure-ruby port of Ozawa's RBTree'}  
      s.description  = <<-EOS.strip
      This is a pure-ruby port of Takuma Ozawa's RBTree.  (it has an identical
      interface and uses the identical unit tests from his version 0.3.0,
      however it is *not* a Red-Black tree.) It's intended for doing lookups and 
      not for doing lots of insertions or deletions.  Please see RBTree docs
      for a sense of how this is supposed to be used. 
      (This one runs the unit tests about 15% slower than Ozawa's C-version,
      and 80% less lines of code ;) 
      EOS
      
      # s.rubyforge_project = "webrat"

      require "git"
      repo = Git.open(".")

      s.files      = normalize_files(repo.ls_files.keys - repo.lib.ignored_files)
      s.test_files = normalize_files(Dir['spec/**/*.rb'] - repo.lib.ignored_files)

      s.has_rdoc = 'yard'  # trying out arg[0]/lsegal's doc tool
      #s.extra_rdoc_files = %w[README.rdoc MIT-LICENSE.txt History.txt]
      #s.extra_rdoc_files = %w[MIT-LICENSE.txt History.txt]

      #s.add_dependency "nokogiri", ">= 1.2.0"
      #s.add_dependency "rack", ">= 1.0"
    end
  end

  def normalize_files(array)
    # only keep files, no directories, and sort
    array.select do |path|
      File.file?(path)
    end.sort
  end

  # Adds extra space when outputting an array. This helps create better version
  # control diffs, because otherwise it is all on the same line.
  def prettyify_array(gemspec_ruby, array_name)
    gemspec_ruby.gsub(/s\.#{array_name.to_s} = \[.+?\]/) do |match|
      leadin, files = match[0..-2].split("[")
      leadin + "[\n    #{files.split(",").join(",\n   ")}\n  ]"
    end
  end

  def read_gemspec
    @read_gemspec ||= eval(File.read("hipe-simplebtree.gemspec"))
  end

  def sh(command)
    puts command
    system command
  end
end

class Default < Thor
  include GemHelpers

  desc "gemspec", "Regenerate hipe-simplebtree.gemspec"
  def gemspec
    File.open("hipe-simplebtree.gemspec", "w") do |file|
      gemspec_ruby = generate_gemspec.to_ruby
      gemspec_ruby = prettyify_array(gemspec_ruby, :files)
      gemspec_ruby = prettyify_array(gemspec_ruby, :test_files)
      gemspec_ruby = prettyify_array(gemspec_ruby, :extra_rdoc_files)

      file.write gemspec_ruby
    end

    puts "Wrote gemspec to hipe-simplebtree.gemspec"
    read_gemspec.validate
  end

  desc "build", "Build a hipe-simplebtree gem"
  def build
    sh "gem build hipe-simplebtree.gemspec"
    FileUtils.mkdir_p "pkg"
    FileUtils.mv read_gemspec.file_name, "pkg"
  end

  desc "install", "Install the latest built gem"
  def install
    sh "gem install --local pkg/#{read_gemspec.file_name}"
  end

  desc "release", "Release the current branch to GitHub and Gemcutter"
  def release
    gemspec
    build
    Release.new.tag
    Release.new.gem
  end
end

class Release < Thor
  include GemHelpers

  desc "tag", "Tag the gem on the origin server"
  def tag
    release_tag = "v#{read_gemspec.version}"
    sh "git tag -a #{release_tag} -m 'Tagging #{release_tag}'"
    sh "git push origin #{release_tag}"
  end

  desc "gem", "Push the gem to Gemcutter"
  def gem
    sh "gem push pkg/#{read_gemspec.file_name}"
  end
end

#************ the below added by mark************
class Spec < Thor
  desc "crazy", "try to pull in the latest rbtree test file,\n"+
  "                                    modify it and save it."
  def crazy    
    require 'pp'
    @gem_basename = 'rbtree'
    @my_version = Gem::Version.new('0.2.9')
    dep = Gem::Dependency.new @gem_basename, Gem::Requirement.default
    
    specs = Gem.source_index.search dep
    local_tuples = specs.map do |spec|
      [[spec.name, spec.version, spec.original_platform, spec], :local]
    end
    local_tuples.extend Crazy
    puts "local #{@gem_basename} gem(s) currently installed:\n" + local_tuples.print
    if (t=local_tuples.max_tuple and t[0][1] > @my_version)
      begin; make_test_file(t); rescue => e; puts e.message; end
    else
      puts "your testfile is probably up to date."
    end

    print "\nShould we check for newer versions of #{@gem_basename} remotely? (y/n):";
    if ('y'==$stdin.gets.strip)
      begin
        puts "attempting to fetch remote info about #{@gem_basename}..."
        fetcher = Gem::SpecFetcher.fetcher
        remote_tuples = fetcher.find_matching dep, 'all versions', 'match platform', 'prerelease'
        puts "done attempting remote"      
      rescue Gem::RemoteFetcher::FetchError => e
        puts "Failed To Connect? (will try local cache) "+e.message
        require 'rubygems/source_info_cache'
        dep.name = '' if dep.name == //
        specs = Gem::SourceInfoCache.search_with_source dep, false, all
        remote_tuples = specs.map do |spec, source_uri|
          [[spec.name, spec.version, spec.original_platform, spec],
           source_uri]
        end
      end
      remote_tuples.extend Crazy 
      puts "remote #{@gem_basename} gems found:"+remote_tuples.print
      if (t = remote_tuples.max_tuple and t[0][1] > @my_version)
        str = t[0][1].to_s
        puts "The remote version of #{@gem_basename} (#{str}) is more recent than "+
        "the test file in version control. (#{@my_version})  Consider updating your #{@gem_basename} gem."
      end
    end
    puts 'done.';
  end
  def make_test_file tuple
    dir_basename = tuple[0][0]+'-'+tuple[0][1].to_s
    filename = File.dirname(__FILE__)+'/test-'+tuple[0][1].to_s+'.rb'
    if File.exists? filename
      puts %{\n\nFile already exists: #{File.basename filename}. No need to run script?}
      return
    end
    path = File.expand_path("#{File.dirname(__FILE__)}/../#{dir_basename}/test.rb")
    raise "sorry, couldn't find test file to copy: #{path}" unless File.exist? path
    contents = nil
    File.open(path,'r'){ |fh| contents = fh.read }
    unless md = %r{\Arequire "\./rbtree"(.+)class MultiRBTreeTest <.+\Z}m.match(contents)
      raise "sorry, failed to parse file contents."
    end
    File.open filename, 'w+' do |fh|
      msg = %{#Generated #{Time.now.strftime('%Y/%m/%d %I:%M:%S%p')} by #{__FILE__}}
      fh.write %{require 'rubygems'\nrequire 'hipe-simplebtree'\n\n}+md[1].gsub('RBTree','Hipe::SimpleBTree')
    end
    puts %{\n\nGenerated test file.  Try running "ruby #{File.basename(filename)}" and keep your fingers crossed!}
  end
end

module Crazy
  def print
    return '[none]' if count == 0
    lines = []
    self.each{|t| lines << %{#{t[0][0]} #{t[0][1]}} }
    lines * "\n"
  end
  def max_tuple
    self.inject{|left,right| left[0][1] > right[0][1] ? left : right }
  end
end

#arr = Gem.source_index.find_name('gem_basename')
#list = Gem::CommandManager.instance['list']    
