# papertrail command-line tail & search client for Papertrail log management service

[![Build Status](https://travis-ci.org/papertrail/papertrail-cli.svg?branch=master)](https://travis-ci.org/papertrail/papertrail-cli)

Small standalone [binary] to retrieve, search, and tail recent app
server log and system syslog messages from [Papertrail].

Supports optional Boolean search queries and polling for new events
(like "tail -f"). Example:

    $ papertrail -f "(www OR db) (nginx OR pgsql) -accepted"

Output is line-buffered so it can be fed into a pipe, like for grep.
ANSI color codes are rendered in color on suitable terminals; see below for
additional colorization options.

The [Connection] class can be used by other apps to perform one-off
API searches or follow (tail) events matching a given query. Interface
may change.

Also includes `papertrail-add-system`, `papertrail-remove-system`,
`papertrail-add-group`, and `papertrail-join-group` binaries, which
invoke the corresponding Papertrail [HTTP API] call.


## Quick Start

    $ [sudo] gem install papertrail
    $ echo "token: 123456789012345678901234567890ab" > ~/.papertrail.yml
    $ papertrail

Retrieve the token from Papertrail [User Profile].

The API token can also be passed in the `PAPERTRAIL_API_TOKEN`
environment variable instead of a configuration file. Example:

    $ export PAPERTRAIL_API_TOKEN='abc123'
    $ papertrail


## Installation

Install the gem (details on [RubyGems]), which includes a binary called
"papertrail":

    $ [sudo] gem install papertrail


## Configuration

Create ~/.papertrail.yml containing your API token, or specify the
path to that file with -c. Example (from
examples/papertrail.yml.example):

    token: 123456789012345678901234567890ab

Retrieve token from Papertrail [User Profile]. For compatibility with
older config files, `username` and `password` keys are also supported.

You may want to alias "pt" to "papertrail", like:

    echo "alias pt=papertrail" >> ~/.bashrc

## Usage & Examples

    $ papertrail --help
    papertrail - command-line tail and search for Papertrail log management service
        -h, --help                       Show usage
        -f, --follow                     Continue running and printing new events (off)
            --min-time MIN               Earliest time to search from
            --max-time MAX               Latest time to search from
        -d, --delay SECONDS              Delay between refresh (2)
        -c, --configfile PATH            Path to config (~/.papertrail.yml)
        -g, --group GROUP                Group to search
        -S, --search SEARCH              Saved search to search
        -s, --system SYSTEM              System to search
        -j, --json                       Output raw JSON data (off)
            --color [program|system|all|off]
                                         Attribute(s) to colorize based on (program)
            --force-color                Force use of ANSI color characters even on non-tty outputs (off)
        -V, --version                    Display the version and exit

      Usage:
        papertrail [-f] [--min-time time] [--max-time time] [-g group] [-S search]
          [-s system] [-d seconds] [-c papertrail.yml] [-j] [--color attributes]
          [--force-color] [--] [query]

      Examples:
        papertrail -f
        papertrail something
        papertrail 1.2.3 Failure
        papertrail -s ns1 "connection refused"
        papertrail -f "(www OR db) (nginx OR pgsql) -accepted"
        papertrail -f -g Production --color all "(nginx OR pgsql) -accepted"
        papertrail --min-time 'yesterday at noon' --max-time 'today at 4am' -g Production
        papertrail -- -redis

      More: https://github.com/papertrail/papertrail-cli
            https://papertrailapp.com/


### Count, pivot, and summarize

To count the number of matches, pipe to `wc -l`. For example, count how
many logs contained `Failure` in the last minute:

    $ papertrail --min-time '1 minute ago' Failure | wc -l
    42

Output only the program/file name (which is output as field 5):

    $ papertrail --min-time '1 minute ago' | cut -f 5 -d ' '
    passenger.log:
    sshd:
    app/web.2:

Count by source/system name (field 4):

    $ papertrail --min-time '1 minute ago' | cut -f 4 -d ' ' | sort | uniq -c
      98 www42
      39 acmedb-core01
      2 fastly

For sum, mean, and statistics, see
[datamash](http://www.gnu.org/software/datamash/) and [one-liners](https://www.gnu.org/software/datamash/alternatives/).

### Colors

ANSI color codes are retained, so log messages which are already colorized
will automatically render in color on ANSI-capable terminals.

By default, the CLI will colorize the non-body portion of each log message
based on the value of the program attribute. 5 colors are available, so colors
may not be unique. When the sending system name is more important than the
program, use `--color=system` to colorize based on its value. Use `--color=all`
to colorize based on both together.

For content-based colorization, pipe through [lnav]. Install `lnav` from your
preferred package repository, such as `brew install lnav` or
`apt-get install lnav`, then:

    $ papertrail -f | lnav
    $ papertrail --min-time "1 hour ago" error | lnav

### Redirecting output

Since output is line-buffered, pipes and output redirection will automatically
work:

    $ papertrail | less
    $ papertrail --min-time '2016-01-15 10:00:00' > logs.txt

If you frequently pipe output to a certain command, create a function which
accepts optional arguments, invokes `papertrail` with any arguments, and pipes
output to that command. For example, this `pt` function will pipe to `lnav`:

    $ function pt() { papertrail -f -d 5 $* | lnav; }

Add the `function` line to your `~/.bashrc`. It can be invoked with search
parameters:

    $ pt 1.2.3 Failure

### UTF-8 (non-English searches)

When searching in a language other than English, if you get no matches, you
may need to explicitly tell Ruby to use UTF-8. Ruby 1.9 honors the `LANG`
shell environment variable, and your shell may not set it to `UTF-8`.

To test, try:

    ruby -E:UTF-8 -S papertrail your_search

If that works, add `-E:UTF-8` to the `RUBYOPT` variable to set the encoding
at invocation. For example, to persist that in a `.bashrc`:

    export RUBYOPT="-E:UTF-8"

### Negation-only queries

Unix shells handle arguments beginning with hyphens (`-`) differently
([why](http://unix.stackexchange.com/questions/11376/what-does-double-dash-mean)).
Usually this is moot because most searches start with a positive match.
To search only for log messages without a given string, use `--`. For
example, to search for `-whatever`, run:

    papertrail -- -whatever

### Time zones

Times are interpreted in the client itself, which means it uses the time
zone that your local PC is set to. Log timestamps are also output in the
same local PC time zone.

When providing absolute times, append `UTC` to provide the input time in
UTC. For example, regardless of the local PC time zone, this will show
messages beginning from 1 PM UTC:

    papertrail --min-time "2014-04-27 13:00:00 UTC"

Output timestamps will still be in the local PC time zone.

### Quoted phrases

Because the Unix shell parses and strips one set of quotes around a
phrase, to search for a phrase, wrap the string in both single-quotes
and double-quotes. For example:

    papertrail -f '"Connection reset by peer"'

Use one set of double-quotes and one set of single-quotes. The order
does not matter as long as the pairs are consistent.

Note that many phrases are unique enough that searching for the
words yields the same results as searching for the quoted phrase. As a
result, quoting strings twice is often not actually necessary. For
example, these two searches are likely to yield the same log messages,
even though one is for 4 words (AND) while the other is for a phrase:

    papertrail -f Connection reset by peer
    papertrail -f '"Connection reset by peer"'

### Multiple API tokens

To use multiple API tokens (such as for separate home and work Papertrail
accounts), create a `.papertrail.yml` configuration file in each project's
working directory and invoke the CLI in that directory. The CLI checks for
`.papertrail.yml` in the current working directory prior to using
`~/.papertrail.yml`.

Alternatively, use shell aliases with different `-c` paths. For example:

    echo "alias pt1='papertrail -c /path/to/papertrail-home.yml'" >> ~/.bashrc
    echo "alias pt2='papertrail -c /path/to/papertrail-work.yml'" >> ~/.bashrc


## Add/Remove Systems, Create Group, Join Group

In addition to tail and search with the `papertrail` binary, the gem includes
4 other binaries which wrap other parts of Papertrail's [HTTP API] to explicitly
add or remove a system, to create a new group, and to join a system to a group.

In most cases, configuration is automatic and these are not not necessary.

To see usage, run any of these commands with `--help`: `papertrail-add-system`,
`papertrail-remove-system`, `papertrail-add-group`, `papertrail-join-group`.


## Releasing

### Build

1. Bump `VERSION` in `lib/papertrail.rb`
2. Build the new gem: `$ rake build`

### Install & Test

1. Install built gem: `$ gem install pkg/papertrail-0.9.17.gem`
2. Check version in rubygems: `$ gem list papertrail`
4. Verify installed version matches: `$ which papertrail && papertrail --version`
4. Test: `$ papertrail test search string`
5. Uninstall local gem `$ gem uninstall papertrail`

### Release

1. Release: `$ rake release`
2. Check latest published version: `$ gem list --versions --remote papertrail`
3. Install release version: `$ gem install papertrail`
4. Verify installed version matches: `$ which papertrail && papertrail --version`
5. Test: `$ papertrail test search string`
6. Party! :tada: :balloon: :confetti_ball:


## Contribute

Testing:

Run all the tests with `rake`

To run the tests when files save, run `bundle exec guard` (requires ruby version >= 2.2.5).

Bug report:

1. See whether the issue has already been reported:
   http://github.com/papertrail/papertrail-cli/issues/
2. If you don't find one, create an issue with a repro case.

Enhancement or fix:

1. Fork the project:
   http://github.com/papertrail/papertrail-cli
2. Make your changes with tests.
3. Commit the changes without changing the Rakefile or other files unrelated
to your enhancement.
4. Send a pull request.

[binary]: https://github.com/papertrail/papertrail-cli/blob/master/bin/papertrail
[Papertrail]: http://papertrailapp.com/
[Connection]: https://github.com/papertrail/papertrail-cli/blob/master/lib/papertrail/connection.rb
[HTTP API]: http://help.papertrailapp.com/kb/how-it-works/http-api
[User Profile]: https://papertrailapp.com/account/profile
[RubyGems]: https://rubygems.org/gems/papertrail-cli
[lnav]: http://lnav.org/
[escape characters]: http://en.wikipedia.org/wiki/ANSI_escape_code#Colors
