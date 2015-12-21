## This is the rakegem gemspec template. Make sure you read and understand
## all of the comments. Some sections require modification, and others can
## be deleted if you don't need them. Once you understand the contents of
## this file, feel free to delete any comments that begin with two hash marks.
## You can find comprehensive Gem::Specification documentation, at
## http://docs.rubygems.org/read/chapter/20
Gem::Specification.new do |s|
  s.specification_version = 2 if s.respond_to? :specification_version=
  s.required_rubygems_version = Gem::Requirement.new(">= 0") if s.respond_to? :required_rubygems_version=
  s.rubygems_version = '1.3.5'

  ## Leave these as is they will be modified for you by the rake gemspec task.
  ## If your rubyforge_project name is different, then edit it and comment out
  ## the sub! line in the Rakefile
  s.name              = 'papertrail'
  s.version           = '0.9.12'
  s.date              = '2015-12-20'
  s.rubyforge_project = 'papertrail'

  ## Make sure your summary is short. The description may be as long
  ## as you like.
  s.summary     = "Command-line client for Papertrail hosted log management service."
  s.description = "Command-line client for Papertrail hosted log management service. Tails and searches app server logs and system syslog. Supports Boolean search and works with grep and pipe output (Unix)."

  ## List the primary authors. If there are a bunch of authors, it's probably
  ## better to set the email to an email list or something. If you don't have
  ## a custom homepage, consider using your GitHub URL or the like.
  s.authors  = ['Papertrail']
  s.email    = 'troy@sevenscale.com'
  s.homepage = 'http://github.com/papertrail/papertrail-cli'

  ## This gets added to the $LOAD_PATH so that 'lib/NAME.rb' can be required as
  ## require 'NAME.rb' or'/lib/NAME/file.rb' can be as require 'NAME/file.rb'
  s.require_paths = %w[lib]

  ## This sections is only necessary if you have C extensions.
#  s.require_paths << 'ext'
#  s.extensions = %w[ext/extconf.rb]

  ## If your gem includes any executables, list them here.
  s.executables = ["papertrail", "papertrail-add-system", "papertrail-remove-system", "papertrail-add-group", "papertrail-join-group"]
  s.default_executable = 'papertrail'

  ## Specify any RDoc options here. You'll want to add your README and
  ## LICENSE files to the extra_rdoc_files list.
  s.rdoc_options = ["--charset=UTF-8"]
#  s.extra_rdoc_files = %w[README LICENSE]
  s.extra_rdoc_files = []

  ## List your runtime dependencies here. Runtime dependencies are those
  ## that are needed for an end user to actually USE your code.
  s.add_dependency('chronic')

  ## List your development dependencies here. Development dependencies are
  ## those that are only needed during development
  s.add_development_dependency('rake')
  s.add_development_dependency('webmock')

  ## Leave this section as-is. It will be automatically generated from the
  ## contents of your Git repository via the gemspec task. DO NOT REMOVE
  ## THE MANIFEST COMMENTS, they are used as delimiters by the task.
  # = MANIFEST =
  s.files = %w[
    Gemfile
    LICENSE
    README.md
    Rakefile
    bin/papertrail
    bin/papertrail-add-group
    bin/papertrail-add-system
    bin/papertrail-archives
    bin/papertrail-join-group
    bin/papertrail-remove-system
    examples/papertrail.yml.example
    lib/papertrail.rb
    lib/papertrail/cli.rb
    lib/papertrail/cli_add_group.rb
    lib/papertrail/cli_add_system.rb
    lib/papertrail/cli_archives.rb
    lib/papertrail/cli_helpers.rb
    lib/papertrail/cli_join_group.rb
    lib/papertrail/cli_remove_system.rb
    lib/papertrail/connection.rb
    lib/papertrail/event.rb
    lib/papertrail/http_client.rb
    lib/papertrail/okjson.rb
    lib/papertrail/search_query.rb
    lib/papertrail/search_result.rb
    papertrail.gemspec
  ]
  # = MANIFEST =

  ## Test files will be grabbed from the file list. Make sure the path glob
  ## matches what you actually use.
  s.test_files = s.files.select { |path| path =~ /^test\/test_.*\.rb/ }
end
