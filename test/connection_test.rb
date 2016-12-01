require 'test_helper'

class ConnectionTest < Minitest::Test
  let(:connection_options) { { :token => 'dummy' } }
  let(:connection) { Papertrail::Connection.new(connection_options) }
  let(:search_query) { connection.search_query }

  def test_search
    search_query.expects(:search_results).with('something', {})
    connection.search('something')
  end
end
