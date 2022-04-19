# frozen_string_literal: true

Gem::Specification.new do |spec|
  spec.name          = 'restclient-rackish'
  spec.version       = '1.0'
  spec.authors       = ['Alipio de Paula']
  spec.email         = ['alipiodepaula@gmail.com']
  spec.license       = 'MIT'

  spec.summary       = 'Rack-inspired middleware stack for RestClient'
  spec.description   = 'Rack-inspired middleware stack for RestClient'
  spec.homepage      = 'https://github.com/alipio/restclient-rackish'
  spec.required_ruby_version = Gem::Requirement.new('>= 2.3.0')

  spec.metadata['homepage_uri'] = spec.homepage
  spec.metadata['changelog_uri'] = 'https://github.com/alipio/restclient-rackish/blob/master/CHANGELOG.md'

  # Specify which files should be added to the gem when it is released.
  # The `git ls-files -z` loads the files in the RubyGem that have been added into git.
  spec.files = Dir.chdir(File.expand_path(__dir__)) do
    `git ls-files -z`.split("\x0").reject { |f| f.match(%r{\A(?:test|spec|features)/}) }
  end
  spec.bindir        = 'exe'
  spec.executables   = spec.files.grep(%r{\Aexe/}) { |f| File.basename(f) }
  spec.require_paths = ['lib']

  # Uncomment to register a new dependency of your gem
  spec.add_dependency 'rack', '~> 2.1'
  spec.add_dependency 'rest-client', '~> 2.1'

  spec.add_development_dependency 'awesome_print'
  spec.add_development_dependency 'byebug', '~> 10.0'
  spec.add_development_dependency 'rake', '~> 13.0'
  spec.add_development_dependency 'rspec', '~> 3.0'
  spec.add_development_dependency 'rubocop', '~> 0.81'
end
