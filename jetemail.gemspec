# frozen_string_literal: true

require_relative "lib/jetemail/version"

Gem::Specification.new do |spec|
  spec.name          = "jetemail"
  spec.version       = JetEmail::VERSION
  spec.summary       = "The Ruby and Rails SDK for jetemail.com"
  spec.description   = "Ruby SDK for the JetEmail transactional email service."
  spec.homepage      = "https://github.com/jetemail/jetemail-ruby"
  spec.license       = "MIT"

  spec.author        = "JetEmail"
  spec.email         = "support@jetemail.com"

  spec.metadata = {
    "homepage_uri" => spec.homepage,
    "source_code_uri" => "https://github.com/jetemail/jetemail-ruby",
    "changelog_uri" => "https://github.com/jetemail/jetemail-ruby/blob/main/CHANGELOG.md",
    "bug_tracker_uri" => "https://github.com/jetemail/jetemail-ruby/issues"
  }

  spec.files         = Dir["*.{md,txt}", "{lib}/**/*", "LICENSE"]
  spec.require_path  = "lib"
  spec.required_ruby_version = ">= 2.6"

  spec.add_dependency "httparty", "~> 0.21"

  spec.add_development_dependency "rspec", "~> 3.0"
  spec.add_development_dependency "webmock", "~> 3.0"
end
