require 'test_helper'

class SearchQueryTest < Minitest::Test
  let(:connection_options) { { :token => 'dummy' } }
  let(:connection) { Papertrail::Connection.new(connection_options) }
  let(:search_query) { Papertrail::SearchQuery.new }
  let(:get_response) { OpenStruct.new(:body => { 'max_id' => 122, 'events' => [] }) }
  let(:api_url) { Papertrail::SearchQuery.api_url }
  let(:default_initial_params) { { limit: Papertrail::SearchQuery.initial_search_limit } }

  def test_sets_min_id_for_subsequent_requests_with_max_id
    # Also testing that we set the initial_search_limit only for the first request
    connection.expects(:get).with(api_url, default_initial_params).returns(get_response)
    search_query.search_results(connection)
    connection.expects(:get).with(api_url, { :min_id => 122 }).returns(get_response)
    search_query.search_results(connection)
  end

  def test_sets_limit_from_options
    opts = { limit: 2 }
    connection.expects(:get).with(api_url, opts).returns(get_response)
    search_query.search_results(connection, nil, opts)
  end
end
