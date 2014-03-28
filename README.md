# papertrail command-line tail & search client for Papertrail log management service

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

    $ papertrail -h
    papertrail - command-line tail and search for Papertrail log management service
        -h, --help                       Show usage
        -f, --follow                     Continue running and print new events (off)
        -d, --delay SECONDS              Delay between refresh (2)
        -c, --configfile PATH            Path to config (~/.papertrail.yml)
        -s, --system SYSTEM              System to search
        -g, --group GROUP                Group to search
        -j, --json                       Output raw json data
        --min-time MIN                   Earliest time to search from.
        --max-time MAX                   Latest time to search from.


    Usage: 
      papertrail [-f] [-s system] [-g group] [-d seconds] [-c papertrail.yml] [-j] [--min-time mintime] [--max-time maxtime] [query]

    Examples:
      papertrail -f
      papertrail something
      papertrail --min-time "20 minutes ago" 1.2.3 Failure
      papertrail -s ns1 "connection refused"
      papertrail -f "(www OR db) (nginx OR pgsql) -accepted"
      papertrail -f -g Production "(nginx OR pgsql) -accepted"
      papertrail -g Production --min-time 'yesterday at noon' --max-time 'today at 4am'

    Includes 4 binaries to change Papertrail settings: papertrail-add-system, papertrail-remove-system,
      papertrail-add-group, papertrail-leave-group. Run with --help or see README.

    More: http://papertrailapp.com/
  

### Colors

ANSI color codes are retained, so log messages which are already colorized 
will automatically render in color on ANSI-capable terminals.

To manually colorize monochrome logs, pipe through [colortail] or 
[MultiTail]. We recommend `colortail``:

    $ sudo gem install colortail

Save [colortailrc] as `~/.colortailrc` and edit it to enable:

    $ papertrail -f -d 5 | colortail -g papertrail

### Shorthand

If you're using bash, create a function that accepts arguments, then
invoke `pt` with optional search operators:

    $ function pt() { papertrail -f -d 5 $* | colortail -g papertrail; }
    $ pt 1.2.3 Failure

Add the function line to your `~/.bashrc`.

### Advanced

For complete control, pipe through anything capable of inserting ANSI
control characters. Here's an example that colorizes 3 fields separately
(the first 15 characters for the date, a word for the hostname, and a
word for the program name):

    $ papertrail | perl -pe 's/^(.{15})(.)([\S]+)(.)([\S]+)/\e[1;31;43m\1\e[0m\2\e[1;31;43m\3\e[0m\4\e[1;31;43m\5\e[0m/g'

the `1;31;43` are bold (1), foreground red (31), background yellow (43),
and can be any ANSI [escape characters].

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


## Add/Remove Systems, Create Group, Join Group

In addition to tail and search with the `papertrail` binary, the gem includes 
4 other binaries which wrap other parts of Papertrail's [HTTP API] to explicitly 
add or remove a system, to create a new group, and to join a system to a group.

In most cases, configuration is automatic and these are not not necessary.

To see usage, run any of these commands with `--help`: `papertrail-add-system`, 
`papertrail-remove-system`, `papertrail-add-group`, `papertrail-join-group`.


## Contribute

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
[User Profile]: https://papertrailapp.com/user/edit
[RubyGems]: https://rubygems.org/gems/papertrail-cli
[colortail]: http://rubydoc.info/gems/colortail
[colortailrc]: https://github.com/papertrail/papertrail-cli/wiki/colortailrc
[MultiTail]: http://www.vanheusden.com/multitail/index.html
[escape characters]: http://en.wikipedia.org/wiki/ANSI_escape_code#Colors
