require 'bundler'
require 'rspec/core/rake_task'
Bundler::GemHelper.install_tasks


RSpec::Core::RakeTask.new(:spec)

ZIP_URL = "https://github.com/projecthydra/hydra-jetty/archive/fedora-4a4.zip"
require 'jettywrapper'

task default: :ci

task ci: 'jetty:unzip' do
  jetty_params = Jettywrapper.load_config('test')
  error = Jettywrapper.wrap(jetty_params) do
    Rake::Task[:spec].invoke
  end
  raise "test failures: #{error}" if error
end
