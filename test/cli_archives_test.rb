require 'test/unit'
require 'webmock/test_unit'
require 'papertrail/cli_archives'

class ArchivesTest < Test::Unit::TestCase

  def test_archives
    ARGV << "--newest 7"
    svc = Papertrail::CliArchives.new
    
    archives_list = [{"start"=>"2015-11-14T00:00:00Z", "end"=>"2015-11-14T23:59:59Z", "filename"=>"2015-11-14.tsv.gz", "filesize"=>9165, "_links"=>{"download"=>{"href"=>"https://papertrailapp.com/api/v1/archives/2015-11-14/download"}}},
                     {"start"=>"2015-11-13T00:00:00Z", "end"=>"2015-11-13T23:59:59Z", "filename"=>"2015-11-13.tsv.gz", "filesize"=>10963, "_links"=>{"download"=>{"href"=>"https://papertrailapp.com/api/v1/archives/2015-11-13/download"}}},
                     {"start"=>"2015-11-12T00:00:00Z", "end"=>"2015-11-12T23:59:59Z", "filename"=>"2015-11-12.tsv.gz", "filesize"=>10589, "_links"=>{"download"=>{"href"=>"https://papertrailapp.com/api/v1/archives/2015-11-12/download"}}},
                     {"start"=>"2015-11-11T00:00:00Z", "end"=>"2015-11-11T23:59:59Z", "filename"=>"2015-11-11.tsv.gz", "filesize"=>11502, "_links"=>{"download"=>{"href"=>"https://papertrailapp.com/api/v1/archives/2015-11-11/download"}}},
                     {"start"=>"2015-11-10T00:00:00Z", "end"=>"2015-11-10T23:59:59Z", "filename"=>"2015-11-10.tsv.gz", "filesize"=>9006, "_links"=>{"download"=>{"href"=>"https://papertrailapp.com/api/v1/archives/2015-11-10/download"}}},
                     {"start"=>"2015-11-09T00:00:00Z", "end"=>"2015-11-09T23:59:59Z", "filename"=>"2015-11-09.tsv.gz", "filesize"=>9588, "_links"=>{"download"=>{"href"=>"https://papertrailapp.com/api/v1/archives/2015-11-09/download"}}},
                     {"start"=>"2015-11-08T00:00:00Z", "end"=>"2015-11-08T23:59:59Z", "filename"=>"2015-11-08.tsv.gz", "filesize"=>10677, "_links"=>{"download"=>{"href"=>"https://papertrailapp.com/api/v1/archives/2015-11-08/download"}}},]

    stub_request(:get, "https://papertrailapp.com/api/v1/archives.json").
      to_return(body: archives_list)

    stub_request(:get, "https://papertrailapp.com/api/v1/archives/{date}/download").
      to_return(body: "")

    svc.run

    archives_list.each do |archive|
      assert_requested :get, archive["_links"]["download"]
    end

  end
end
