require 'rake/testtask'

task :default => :test
Rake::TestTask.new do |t|
  t.libs << 'spec'
  t.pattern = "spec/**/*_spec.rb"
end

namespace :fedora do
  url = 'https://github.com/futures/fcrepo4/releases/download/fcrepo-4.0.0-alpha-3/'
  filename = 'fcrepo-webapp-4.0.0-alpha-3-jetty-console.war'
  download_path = "fedora/"

  desc "Download FC4"
  task :download do
    system "curl -L #{url}#{filename} -o #{download_path}#{filename}"
  end

  desc "Start FC4"
  task :start do
    require 'childprocess'
    process = ChildProcess.build("java", "-jar", download_path + filename)
    process.detach = true
    process.start
  end
end
