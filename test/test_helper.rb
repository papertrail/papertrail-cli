gem "minitest"
require 'minitest/autorun'
require 'minitest/pride' # Color!
require 'mocha/mini_test'
unless RUBY_VERSION < '1.9'
  require 'webmock/minitest'
  WebMock.disable_net_connect!
end

require 'pp'

class Minitest::Test
  extend Minitest::Spec::DSL # Add let blocks
end

require './lib/papertrail'