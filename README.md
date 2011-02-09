# papertrail Command-line tail & search client for Papertrail log management service

Ask [Papertrail] for recent log messages, optionally with a search query (the output
can also be piped through grep). Optionally poll for new events, like tail -f.

Papertrail::SearchClient class can also be used to perform one-off API searches
or follow (tail) events matching a given query (interface may change).


## Installation

Install the gem, which includes a binary called "papertrail":

    gem install papertrail-api


## Configuration

Create ~/.papertrail.yml containing your credentials, or specify the path to 
that file with -c. Example (from examples/papertrail.yml.example):
    username: your@account.com
    password: yourpassword

You may want to alias "trail" to "papertrail", like:
    echo "alias trail=papertrail" >> ~/.bashrc


## Usage & Examples

    $ papertrail -h
    papertrail - command-line tail and search for Papertrail log management service
        -h, --help                       Show usage
        -f, --follow                     Continue running and print new events (off)
        -d, --delay SECONDS              Delay between refresh (30)
        -c, --configfile PATH            Path to config (~/.papertrail.yml)

    Usage: papertrail [-f] [-d seconds] [-c /path/to/papertrail.yml] [query]

    Examples:
      papertrail -f
      papertrail something
      papertrail 1.2.3 Failure
      papertrail -f "(www OR db) (nginx OR pgsql) -accepted"
      papertrail -f -d 10 "ns1 OR 'connection refused'"

    More: http://papertrailapp.com/


## Contribute

Bug report:

1. See whether the issue has already been reported:
   http://github.com/papertrail/papertrail-api/issues/
2. If you don't find one, create an issue with a repro case.

Enhancement or fix:

1. Fork the project:
   http://github.com/papertrail/papertrail-api
2. Make your changes with tests.
3. Commit the changes without changing the Rakefile or other files unrelated 
to your enhancement.
4. Send a pull request.

[Papertrail]: http://papertrailapp.com/
