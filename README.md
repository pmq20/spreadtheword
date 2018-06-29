<h1 align="center" style="border-bottom: none;">Spread the Word</h1>
<h3 align="center">Generate a release-note document of LaTeX format based on git commit messages</h3>
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

* Integrates with Wrike and GitLab to fetch developement task titles
* Integrates with Google Translate to automatically translate messages to English

## Usage

    spreadtheword [OPTION]...
      -v, --version                    Prints the version of rubyc and exit
      -h, --help                       Prints this help and exit
          --root=DIR                   The path to the root of your project. Default: current directory
          --title=STRING               Specifies the title of the output document. Default: "Relase Notes"
          --author=STRING              Specifies the author of the output document. Default: user.name of git config
          --wrike-id=STRING            Specifies the OAuth Client ID of your Wrike API app.
          --wrike-token=STRING         Specifies the access token of your Wrike API app.

## License

MIT

## See Also

- [gitlab](https://github.com/narkoz/gitlab): Ruby client and CLI for GitLab API.
- [wrike3](https://github.com/morshedalam/wrike3): Ruby client for the Wrike API V3.
- [google-cloud-translate](https://github.com/GoogleCloudPlatform/google-cloud-ruby/tree/master/google-cloud-translate): the official library for Google Cloud Translation API.
