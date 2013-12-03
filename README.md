# Papertrail CLI

A command-line tail & search client for the [Papertrail] log management
service. [Retrieve, search, and tail][tail] recent logs and [manage systems
and groups][systems-groups]. Supports Boolean search queries and has a follow
option similar to `tail -f` which watches for new events.

## Quick Start

```bash
$ [sudo] gem install papertrail
$ echo "token: 123456789012345678901234567890ab" > ~/.papertrail.yml
$ papertrail
```


## Installation

Install [the Ruby gem][gem] which includes the `papertrail` executable.

```bash
$ [sudo] gem install papertrail
```

Create a `~/.papertrail.yml` file containing the API token retrieved from the
[user profile].

```yaml
$ echo "token: 123456789012345678901234567890ab" > ~/.papertrail.yml
```

Optionally, a bash alias could save some typing.

```bash
echo "alias pt=papertrail" >> ~/.bashrc
```


## Usage & Examples

```bash
$ papertrail -f
$ papertrail Error
$ papertrail --min-time "20 minutes ago" 1.2.3 Failure
$ papertrail -s ns1 "connection refused"
$ papertrail -f "(www OR db) (nginx OR pgsql) -accepted"
$ papertrail -f -g Production "(nginx OR pgsql) -accepted"
$ papertrail -g Production --min-time 'yesterday at noon' --max-time 'today at 4am'
```

Use the `--help` switch to see [full usage details][full-usage].

Output is line-buffered so it can be piped into another program like grep.
[ANSI color codes][ansi] are rendered in color on suitable terminals. See
below for additional [colorization options][colors].

### Colors

Log messages which contain [ANSI color codes][ansi] will be rendered correctly
by capable terminals. To manually colorize monochrome logs, pipe through
[colortail] or [MultiTail]. Using `colortail`, create a
[`~/.colortailrc` file][colortailrc] to match and colorize logs.

```bash
$ [sudo] gem install colortail
$ papertrail -f -d 5 | colortail -g papertrail
```

Using bash, a function can be created to call `papertrail` and pipe through
`colortail` by default. Add the following function to `~/.bashrc`:

```bash
function pt() { papertrail -f -d 5 $_ | colortail -g papertrail }
```

Use the `pt` function as you would the `papertrail` executable. Arguments will
be passed through.

```bash
$ pt Error
$ pt --min-time "20 minutes ago" 1.2.3 Failure
```

### Advanced

For complete control, pipe through anything capable of inserting ANSI
control characters. Here's an example that colorizes 3 fields separately
(the first 15 characters for the date, a word for the hostname, and a
word for the program name):

```bash
$ papertrail | perl -pe 's/^(.{15})(.)([\S]+)(.)([\S]+)/\e[1;31;43m\1\e[0m\2\e[1;31;43m\3\e[0m\4\e[1;31;43m\5\e[0m/g'
```

_The ANSI color code `1;31;43` stands for bold (1), foreground red (31),
background yellow (43)._

### UTF-8 (non-English searches)

If no matches are returned when searching in a language other than English, it
may be necessary to explicitly tell Ruby to use UTF-8. Ruby 1.9 honors the
`LANG` shell environment variable and this may not be set to `UTF-8`. To test,
try:

```bash
$ ruby -E:UTF-8 -S papertrail your_search
```

If that works, add `-E:UTF-8` to the `RUBYOPT` variable to set the encoding at
invocation. For example, to persist in bash, add the following to `~/.bashrc`:

```bash
export RUBYOPT="-E:UTF-8"
```

### Negation-only queries

Unix shells handle [arguments beginning with hyphens (`-`)
differently][bash-double-dash]. Usually, this isn't an issue because most
searches start with a positive match. To search only for log messages without
a given string, use `--`. For example, to search for `-Error`, run:

```bash
$ papertrail -- -Error
```

### Full Usage

```bash
Usage: papertrail [-f] [-s system] [-g group] [-d seconds] [-c papertrail.yml]
                  [-j] [--min-time mintime] [--max-time maxtime] [query]

Arguments:
    -h, --help                       Show usage
    -f, --follow                     Continue running and print new events (off)
    -d, --delay SECONDS              Delay between refresh (2)
    -c, --configfile PATH            Path to config (~/.papertrail.yml)
    -s, --system SYSTEM              System to search
    -g, --group GROUP                Group to search
    -j, --json                       Output raw json data
        --min-time MIN               Earliest time to search from.
        --max-time MAX               Latest time to search from.
```


## Systems & Groups

The gem includes other executables to add or remove a system, create a new
group, and add a system to a group: `papertrail-add-system`,
`papertrail-remove-system`, `papertrail-add-group`, `papertrail-join-group`
Pass the `--help` switch to any of those executables for detailed usage and
examples.


## Contribute

### Reporting a Bug

1. Search [the project issues][issues] to see if this bug has already been
   reported.
2. Create a new issue with details on how to reproduce the error.

### Enhancement or Fix

1. Fork the project.
2. Make your changes without modifying unrelated files.
3. Send a pull request.


[Papertrail]: http://papertrailapp.com/
[user profile]: https://papertrailapp.com/user/edit
[gem]: https://rubygems.org/gems/papertrail-cli
[colortail]: http://rubydoc.info/gems/colortail
[colortailrc]: https://github.com/papertrail/papertrail-cli/wiki/colortailrc
[MultiTail]: http://www.vanheusden.com/multitail/index.html
[ansi]: http://en.wikipedia.org/wiki/ANSI_escape_code#Colors
[tail]: #usage--examples
[systems-groups]: #systems--groups
[colors]: #colors
[bash-double-dash]: http://unix.stackexchange.com/questions/11376/what-does-double-dash-mean
[issues]: http://github.com/papertrail/papertrail-cli/issues
[full-usage]: #full-usage
