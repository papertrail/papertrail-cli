require 'test_helper'

class SearchQueryTest < Minitest::Test
  let(:connection_options) { { :token => 'dummy' } }
  let(:connection) { Papertrail::Connection.new(connection_options) }
  let(:search_query) { Papertrail::SearchQuery.new }
  let(:get_response) { OpenStruct.new(:body => { 'max_id' => 122, 'events' => [] }) }
  let(:api_url) { Papertrail::SearchQuery.api_url }

  def test_sets_min_id_for_subsequent_requests_with_max_id
    connection.expects(:get).with(api_url, {}).returns(get_response)
    search_query.search_results(connection)
    connection.expects(:get).with(api_url, { :min_id => 122 }).returns(get_response)
    search_query.search_results(connection)
  end
end
