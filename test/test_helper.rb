require 'minitest/unit'
require 'minitest/autorun'
require 'minitest/pride' # Color!
require 'mocha/mini_test'

require 'pp'

class Minitest::Test
  extend Minitest::Spec::DSL # Add let blocks
end

require './lib/papertrail'