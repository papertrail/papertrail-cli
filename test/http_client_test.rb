require 'test_helper'

class HttpClientTest < Minitest::Test
  describe "http methods" do
    let(:http) { Papertrail::HttpClient.new({}) }
    def test_cli_version_present_in_http_methods
      skip if RUBY_VERSION < '1.9'
      # if webmock.disable_net_connect intervenes with a stack trace,
      # we know the http methods are not sending cli_version in params
      stub_request(:get, /https:\/\/papertrailapp.com\/api\/v1\/some-path\?cli_version=#{Papertrail::VERSION}/).to_return(:status => 200, :body => "", :headers => {})
      http.get("some-path")

      stub_request(:post, "https://papertrailapp.com/api/v1/some-path").with(:body => "cli_version=#{Papertrail::VERSION}").to_return(:status => 200, :body => "", :headers => {})
      http.post("some-path", {})


      stub_request(:put, "https://papertrailapp.com/api/v1/some-path").with(:body => "cli_version=#{Papertrail::VERSION}").to_return(:status => 200, :body => "", :headers => {})
      http.put("some-path", {})

      stub_request(:delete, /https:\/\/papertrailapp.com\/api\/v1\/some-path\?cli_version=#{Papertrail::VERSION}/).to_return(:status => 200, :body => "", :headers => {})
      http.delete("some-path")
    end
  end
end