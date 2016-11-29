require 'test_helper'

class TestConnection < Minitest::Test
  let(:connection_options) { { token: 'dummy' } }
  let(:connection) { Papertrail::Connection.new(connection_options) }

  def test_query
    Papertrail::SearchQuery.expects(:new).with(connection, 'something', {})
    connection.query('something')
  end
end
