Given /^papertrail is configured correctly$/ do
  @expected_token = '1234mysecrettoken456'
  write_file('.papertrail.yml', "token: #{@expected_token}")
end

def stub_request(url, body)
  @stubbed_requests ||= []
  @stubbed_requests << <<-eoruby
    stub_request(:get, '#{url}').
      with(:headers =>
           { 'X-Papertrail-Token'=> '#{@expected_token}'}).
            to_return(:status => 200,
            :body => #{body.inspect},
            :headers => {})
  eoruby
end

Given /^the following server log:$/ do |logs|
  url = "https://papertrailapp.com/api/v1/events/search.json"
  stub_request(url, { :events => logs.hashes }.to_json)
end

When /^I papertrail$/ do
  stubbing_file = 'noweb.rb'
  write_file(stubbing_file, <<-ruby
    require 'webmock'
    include WebMock::API
    #{@stubbed_requests.join('\n')}
    ruby
  )

  cmd = "ruby -rbundler/setup -rwebmock -r./#{stubbing_file} ../../bin/papertrail"
  run_simple(cmd)
end
