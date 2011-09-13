require 'bundler'
Bundler::GemHelper.install_tasks

require 'rspec/core'
require 'rspec/core/rake_task'

RSpec::Core::RakeTask.new(:spec) do |spec|
  spec.pattern = FileList['spec/**/*_spec.rb']
  spec.rspec_opts = "-d"
end

RSpec::Core::RakeTask.new(:spec_with_report) do |spec|
  spec.fail_on_error = false
  spec.pattern = FileList['spec/**/*_spec.rb']
  spec.rspec_opts = "--format html --out report/tests/report.html"
end

desc "Run all specs, profile the code, and generate a coverage report"
task :report do
  Dir.mkdir "report" unless File.exists? "report"
  Dir.mkdir "report/profile" unless File.exists? "report/profile"
  Dir.mkdir "report/tests" unless File.exists? "report/tests"
  File.open "report/index.html","w" do |f|
    f.write <<-HTML
      <html>
        <body>
          <h1> Status Report </h1>
          <p>
            <a href="coverage/index.html"> Coverage </a>
          </p> 
          <p>
            <a href="profile/profile.graph.html"> Graph Speed Profile </a><br/>
            <a href="profile/profile.stack.html"> Speed Profile </a>
          </p>
          <p>
            <a href="test/report.html"> Test Report </a>
          </p>
        </body>
      </html>
    HTML
  end
  ENV["REPORT"] = "1" 
  Rake::Task[:spec_with_report].invoke
  ENV["REPORT"] = ""
end 

desc "Delete the report directory"
task :clear_report do
  `rm -rf report`
end

task :default => :spec

