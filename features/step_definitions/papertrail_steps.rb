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
            :headers => {"Content-Type"=>"application/json; charset=utf-8"})
  eoruby
end

Given /^the following systems:$/ do |systems|
  url = "https://papertrailapp.com/api/v1/systems.json"
  stub_request(url, systems.hashes.to_json)
  @systems = systems.hashes
end

Given /^the following events:$/ do |logs|
  search_url = "https://papertrailapp.com/api/v1/events/search.json"
  stub_request(search_url, { :events => logs.hashes }.to_json)

  @systems.each do |system|
    system_id = system['id']
    url = "#{search_url}?system_id=#{system_id}"
    events = logs.hashes.select {|ev| ev[:source_id] == system_id }
    stub_request(url, { :events => events }.to_json)
  end
end

When /^I papertrail(?: with '([^']*)')?$/ do |params|
  stubbing_file = 'noweb.rb'
  write_file(stubbing_file, <<-ruby
    require 'webmock'
    include WebMock::API
    #{@stubbed_requests.join("\n")}
    ruby
  )

  cmd = "ruby -rbundler/setup -rwebmock -r./#{stubbing_file} -- ../../bin/papertrail #{params}"
  run_simple(cmd)
end
