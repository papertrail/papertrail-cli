require 'test_helper'

class SearchQueryTest < Minitest::Test
  let(:connection_options) { { :token => 'dummy' } }
  let(:connection) { Papertrail::Connection.new(connection_options) }
  let(:api_url) { Papertrail::SearchQuery.api_url }
  let(:default_initial_params) { { :limit => Papertrail::SearchQuery.initial_search_limit } }
  let(:get_response) { OpenStruct.new(:body => { 'max_id' => 122, 'events' => [] }) }

  describe 'default options' do
    let(:search_query) { Papertrail::SearchQuery.new(connection) }
    let(:target_params) do
      {
        :min_id => 122,
        :limit => Papertrail::SearchQuery.subsequent_search_limit
      }
    end

    def test_sets_min_id_for_initial_and_subsequent_requests
      # Test that the first request happens with the default_initial_params
      connection.expects(:get).with(api_url, default_initial_params).returns(get_response)
      search_query.next_results_page
      # And that subsequent requests use the updated min_id and limit
      connection.expects(:get).with(api_url, target_params).returns(get_response)
      search_query.next_results_page
    end
  end

  describe 'passed options' do
    let(:options) do
      {
        :group_id => 12,
        :system_id => 22,
        :min_id => 100,
        :limit => 2
      }
    end
    let(:search_query) { Papertrail::SearchQuery.new(connection, 'some search', options) }
    let(:target_first_params) { options.merge(:q => 'some search') }
    let(:target_subsequent_params) { target_first_params.merge(:min_id => 122) } # Max ID from get_response

    def test_sets_options_from_passed_options_and_ups_min_id
      connection.expects(:get).with(api_url, target_first_params).returns(get_response)
      search_query.next_results_page
      connection.expects(:get).with(api_url, target_subsequent_params).returns(get_response)
      search_query.next_results_page
    end
  end
end