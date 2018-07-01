<h1 align="center" style="border-bottom: none;">Spread the Word</h1>
<h3 align="center">Automatically generate a release-note document based on git commit messages</h3>
<p align="center">
<a href="https://travis-ci.org/pmq20/spreadtheword">
  <img alt="Build Status" src="https://travis-ci.org/pmq20/spreadtheword.svg?branch=master" />
</a>
<a href="https://ci.appveyor.com/project/pmq20/spreadtheword/branch/master">
  <img alt="Build Status" src="https://ci.appveyor.com/api/projects/status/xdb4p03gvrjr0m6m?svg=true" />
</a>
<a href="https://codecov.io/gh/pmq20/spreadtheword">
  <img alt="codecov" src="https://codecov.io/gh/pmq20/spreadtheword/branch/master/graph/badge.svg" />
</a>
<a href="https://snyk.io/test/github/pmq20/spreadtheword">
  <img src="https://snyk.io/test/github/pmq20/spreadtheword/badge.svg" alt="Known Vulnerabilities" data-canonical-src="https://snyk.io/test/github/pmq20/spreadtheword?targetFile=Frontend%2Fpackage.json" style="max-width:100%;">
</a>
<a href="http://isitmaintained.com/project/pmq20/spreadtheword">
  <img alt="Average time to resolve an issue" src="http://isitmaintained.com/badge/resolution/pmq20/spreadtheword.svg" />
</a>
<a href="http://isitmaintained.com/project/pmq20/spreadtheword">
  <img alt="Percentage of issues still open" src="http://isitmaintained.com/badge/open/pmq20/spreadtheword.svg" />
</a>
</p>

## Features

* Multiple projects are supported, which means git messages from multiple repositories can be merged to produce a unified release document
* Multiple output formats are supported, e.g. LaTeX
* Integrates with Wrike and GitLab to fetch developement task titles
* Integrates with Google Translate to automatically translate messages to English

## Commit Message Conventions

- `{W1}` menas Wrike task `XXX` as in Wrike's permalink `https://www.wrike.com/open.htm?id=XXX`. Eg. `{W4123780} fix config files`
- `{#1}` means issue #1 of Gitlab. Eg. `{#63} add backend code for fields`
- `{prj#1}` means issue #1 of Gitlab project `prj`. Eg. `{UI#1} add code for forms`

## Usage

    spreadtheword [PROJECT 1] [PROJECT 2]...[PROJECT N] [OPTION 1] [OPTION 2]...[OPTION N]
          --author=STRING              Specifies the author of the output document. Default: user.name of git config
          --console                    If present, start the console after spreadtheword initializes.
          --google-translate-key=STRING
                                      Specifies a Google Translate API access key and translate commit messages that contain non-ASCII characters to English.
      -h, --help                       Prints this help and exit
          --gitlab-endpoint=URL        Specifies GitLab API endpoint URL.
          --gitlab-token=STRING        Specifies the OAuth access token of your GitLab.
          --quiet                      If present, spreadtheword would not output anything to stderr.
          --since=TAG/COMMIT-SHA1      Specifies the begining from which the git commits will be fetched. Default: the first commit
          --title=STRING               Specifies the title of the output document. Default: "Relase Notes"
      -v, --version                    Prints the version of spreadtheword and exit
          --wrike-token=STRING         Specifies the access token of your Wrike API app.

## Notes

* If no projects were provided, the current directory would be used as the sole project directory;
* If multiple projects were provided, the git commit messages of those projects would be merged;
* If no options were specified, their default (see below) will be used.

## Example

    spreadtheword                                     \
      /projects/X                                     \
      /projects/Y                                     \
      --since=v1.5                                    \
      --title="Your Project v1.6 Release Notes"       \
      --author="Your Company, Inc."                   \
      --google-translate-key="XXX"                    \
      --gitlab-endpoint="https://example.net/api/v4"  \
      --gitlab-token="XXX"                            \
      --wrike-token="XXX"                             \
      > v1.6.tex

Hint: you might need to set environment variable `LANG=en_US.UTF-8` to support wide characters of git log messages.

## License

MIT

## See Also

- [gitlab](https://github.com/narkoz/gitlab): Ruby client and CLI for GitLab API.
- [wrike3](https://github.com/morshedalam/wrike3): Ruby client for the Wrike API V3.
- [google-cloud-translate](https://github.com/GoogleCloudPlatform/google-cloud-ruby/tree/master/google-cloud-translate): the official library for Google Cloud Translation API.
