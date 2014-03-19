require 'rake/testtask'

task :default => :ci
task :spec => :test
Rake::TestTask.new do |t|
  t.libs << 'spec'
  t.pattern = "spec/**/*_spec.rb"
end

task :ci => ['fedora:download', 'fedora:start', :test]

namespace :fedora do
  url = 'https://github.com/futures/fcrepo4/releases/download/fcrepo-4.0.0-alpha-3/'
  filename = 'fcrepo-webapp-4.0.0-alpha-3-jetty-console.war'
  download_path = "fedora/"
  port = 8080

  desc "Download FC4"
  task :download do
    system "curl -L #{url}#{filename} -o #{download_path}#{filename}"
  end

  desc "Start FC4"
  task :start do
    $LOAD_PATH << 'lib'
    require 'fedora'
    Fedora.start(download_path + filename)
  end

end
