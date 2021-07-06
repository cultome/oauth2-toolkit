# frozen_string_literal: true

require_relative "lib/oath2_toolkit/version"
# =>
Gem::Specification.new do |spec|
  spec.name          = "oath2_toolkit"
  spec.version       = Oath2Toolkit::VERSION
  spec.authors       = ["Carlos Soria"]
  spec.email         = ["csoria@cultome.io"]

  spec.summary       = "A very basic OAuth2 client for testing purposes"
  spec.description   = "A very basic OAuth2 client for testing purposes"
  spec.homepage      = "https://github.com/cultome/oauth2-toolkit"
  spec.license       = "MIT"
  spec.required_ruby_version = Gem::Requirement.new(">= 2.4.0")

  spec.metadata["allowed_push_host"] = "TODO: Set to 'http://mygemserver.com'"

  spec.metadata["homepage_uri"] = spec.homepage
  spec.metadata["source_code_uri"] = "https://github.com/cultome/oauth2-toolkit"
  spec.metadata["changelog_uri"] = "https://github.com/cultome/oauth2-toolkit"

  # Specify which files should be added to the gem when it is released.
  # The `git ls-files -z` loads the files in the RubyGem that have been added into git.
  spec.files = Dir.chdir(File.expand_path(__dir__)) do
    `git ls-files -z`.split("\x0").reject { |f| f.match(%r{\A(?:test|spec|features)/}) }
  end
  spec.bindir        = "exe"
  spec.executables   = spec.files.grep(%r{\Aexe/}) { |f| File.basename(f) }
  spec.require_paths = ["lib"]
end
