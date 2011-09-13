if ENV["REPORT"] == "1" then
  require 'simplecov'
  require 'ruby-prof'
  require 'rspec-prof'
  require 'ruby-debug'

  SimpleCov.start do
    add_filter "/spec.rb/"
    coverage_dir "report/coverage"
  end

  class RSpecProf::Profiler
    def initialize options
      @options = default_options.merge(options)
      ENV["RUBY_PROF_MEASURE_MODE"] = options[:measure_mode]
      RubyProf.figure_measure_mode
      STDOUT.puts "initi"
    end

    alias :old_default :default_options
    def default_options
      old = old_default 
      old.merge({
        :directory => './report/profile',
        :printer => RubyProf::GraphHtmlPrinter,
        :stop_block => proc do |result|
          #remove every Rspec method possible.
          result.threads.each do |thread_id, methods|
            begin
              match = /RSpec.*?/
              i = 0
              while i < methods.size
                mi = methods[i]
                method_name = mi.full_name
                if method_name =~ /RSpec.*?/
                  (i += 1; next) if mi.root?
                  methods.delete_at(i)
                  mi.eliminate!
                else
                  i += 1
                end
              end
            end
          end
          result
        end
      })
    end

    def stop
      file = options[:file] + ".html"
      result = RubyProf.stop
      printer_class = options[:printer] 

      with_io(file) do |out|
        if @options[:stop_block].respond_to? :call
          result = @options[:stop_block].call(result)
        end
        printer = printer_class.new(result)
        printer.print(out, :print_file => options[:print_file], :min_percent => options[:min_percent])
      end
    end
  end

  RSpec.configure do |config|
    config.around :each do |example|
      STDOUT.puts example.metadata[:description]
      example.run
    end
  end
else
  module EmptyProfile
    def profile *args
      yield
    end
  end

  RSpec.configure do |config|
    config.extend EmptyProfile 
  end
end

# Requires supporting files with custom matchers and macros, etc,
# in ./support/ and its subdirectories.
Dir["#{File.dirname(__FILE__)}/support/**/*.rb"].each {|f| require f}
