Gem::Specification.new do |s|
  s.name = 'logstash-output-initialstate'
  s.version = '0.9.0'
  s.licenses = ['Apache License (2.0)']
  s.summary = 'Outout data to Initial State.'
  s.description = 'This gem is a Logstash plugin required to be installed on top of the Logstash core pipeline using $LS_HOME/bin/logstash-plugin install gemname. This gem is not a stand-alone program'
  s.authors = ['Andre Baskin']
  s.email = 'andre@ito-inc.com'
  s.homepage = 'http://www.elastic.co/guide/en/logstash/current/index.html'
  s.require_paths = ['lib']

  # Files
  s.files = Dir['lib/**/*','spec/**/*','vendor/**/*','*.gemspec','*.md','CONTRIBUTORS','Gemfile','LICENSE','NOTICE.TXT']
   # Tests
  s.test_files = s.files.grep(%r{^(test|spec|features)/})

  # Special flag to let us know this is actually a logstash plugin
  s.metadata = { 'logstash_plugin' => 'true', 'logstash_group' => 'output' }

  # Gem dependencies
  s.add_runtime_dependency 'logstash-core-plugin-api', '>= 1.60', '< 3.0.0'
  s.add_runtime_dependency 'httparty', '~> 0.14', '>= 0.14.0'
  s.add_runtime_dependency 'json', '~> 1.8', '>= 1.8.3'
  s.add_development_dependency 'logstash-devutils', '~> 0.0', '>= 0.0.16'
  #s.add_runtime_dependency 'logstash-codec-plain', '~> 0.0'
  #s.add_runtime_dependency 'logstash-core', '>= 2.0.0', '< 3.0.0'
end
