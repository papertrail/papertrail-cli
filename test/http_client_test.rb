require 'test_helper'

class HttpClientTest < Minitest::Test
  let(:http) { Papertrail::HttpClient.new({}) }
  describe "http methods" do

    def test_cli_version_present_in_http_methods
      return if RUBY_VERSION < '2.0'
      # if webmock.disable_net_connect intervenes with a stack trace,
      # we know the http methods are not sending cli_version in params
      stub_request(:get, "https://papertrailapp.com/api/v1/some-path?cli_version=#{Papertrail::VERSION}&").to_return(:status => 200, :body => '', :headers => {})
      http.get('some-path')

      stub_request(:post, "https://papertrailapp.com/api/v1/some-path?cli_version=#{Papertrail::VERSION}&").to_return(:status => 200, :body => '', :headers => {})
      http.post('some-path', {})


      stub_request(:put, "https://papertrailapp.com/api/v1/some-path?cli_version=#{Papertrail::VERSION}&").to_return(:status => 200, :body => '', :headers => {})
      http.put('some-path', {})

      stub_request(:delete, "https://papertrailapp.com/api/v1/some-path?cli_version=#{Papertrail::VERSION}&").to_return(:status => 200, :body => '', :headers => {})
      http.delete('some-path')
    end
  end
  describe "build_nested_query" do
    def test_value_accepts_hash
      assert_equal(http.send(:build_nested_query, {}), "")
      assert_equal(http.send(:build_nested_query, {:a => 1}), "a=1")
    end
    def test_value_accepts_array
      assert_equal(http.send(:build_nested_query, []), "")
      assert_equal(http.send(:build_nested_query, [1,2]), "%5B%5D=1&%5B%5D=2")
    end
  end
end