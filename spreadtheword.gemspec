
lib = File.expand_path("../lib", __FILE__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)
require "spreadtheword/version"

Gem::Specification.new do |spec|
  spec.name          = "spreadtheword"
  spec.version       = Spreadtheword::VERSION
  spec.authors       = ["Minqi Pan"]
  spec.email         = ["pmq2001@gmail.com"]

  spec.summary       = %q{Automatically generate a release-note document based on git commit messages.}
  spec.description   = %q{Automatically generate a release-note document based on git commit messages.}
  spec.homepage      = "https://github.com/pmq20/spreadtheword"
  spec.license       = "MIT"

  # Specify which files should be added to the gem when it is released.
  # The `git ls-files -z` loads the files in the RubyGem that have been added into git.
  spec.files         = Dir.chdir(File.expand_path('..', __FILE__)) do
    `git ls-files -z`.split("\x0").reject { |f| f.match(%r{^(test|spec|features)/}) }
  end
  spec.bindir        = "exe"
  spec.executables   = spec.files.grep(%r{^exe/}) { |f| File.basename(f) }
  spec.require_paths = ["lib"]
  spec.add_dependency 'gitlab', '~> 4.3.0'
  spec.add_dependency 'wrike3', '~> 0.4.0'
  spec.add_dependency 'google-cloud-translate', '~> 1.2'
  spec.add_dependency 'activesupport', '>= 5.2', '< 7.0'
  spec.add_dependency 'nokogiri', '~> 1.8'
  spec.add_dependency 'pry', '~> 0.11.3'
  spec.add_development_dependency "bundler", "~> 1.16"
  spec.add_development_dependency "rake", "~> 10.0"
end
