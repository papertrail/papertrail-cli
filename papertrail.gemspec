require File.expand_path('../lib/papertrail/version', __FILE__)

Gem::Specification.new do |spec|
  spec.name        = 'papertrail'
  spec.version     = Papertrail::VERSION
  spec.summary     = "Command-line client for Papertrail hosted log management service."
  spec.description = "Command-line client for Papertrail hosted log management service. Tails and searches app server logs and system syslog. Supports Boolean search and works with grep and pipe output (Unix)."
  spec.authors     = ['Papertrail']
  spec.email       = 'troy@sevenscale.com'
  spec.homepage    = 'http://github.com/papertrail/papertrail-cli'
  spec.licenses    = ['MIT']

  spec.add_dependency 'addressable'
  spec.add_dependency 'yajl-ruby'
  spec.add_dependency 'chronic'
  spec.add_dependency 'faraday', [ '>= 0.6', '< 0.9' ]
  spec.add_dependency 'faraday_middleware', '~> 0.8.4'

  spec.bindir      = 'bin'
  spec.executables = %w(papertrail papertrail-add-system
                        papertrail-remove-system papertrail-add-group
                        papertrail-join-group)
  spec.default_executable = 'papertrail'

  spec.files =  %w(Gemfile LICENSE README.md papertrail.gemspec)
  spec.files += Dir.glob('bin/*')
  spec.files += Dir.glob('examples/*')
  spec.files += Dir.glob('lib/**/*.rb')
  spec.files += Dir.glob('man/*')

  spec.required_rubygems_version = '>= 1.3.6'
end
