require_relative "lib/stratocaster/version"

Gem::Specification.new do |spec|
  spec.name        = "stratocaster"
  spec.version     = Stratocaster::VERSION
  spec.authors     = ["Johan Halse"]
  spec.email       = ["johan@hal.se"]
  spec.homepage    = "https://github.com/johanhalse/stratocaster"
  spec.summary     = "Another flippin image uploader"
  spec.description = "Imagine having images on Rails without fucking everything up"
  spec.license     = "MIT"

  # Prevent pushing this gem to RubyGems.org. To allow pushes either set the "allowed_push_host"
  # to allow pushing to a single host or delete this section to allow pushing to any host.
  spec.metadata["allowed_push_host"] = "https://rubygems.org"

  spec.required_ruby_version = ">= 3.0.0"

  spec.metadata["homepage_uri"] = spec.homepage
  spec.metadata["source_code_uri"] = "https://github.com/johanhalse/stratocaster"
  spec.metadata["changelog_uri"] = "https://github.com/johanhalse/stratocaster/CHANGELOG.md"

  spec.files = Dir.chdir(File.expand_path(__dir__)) do
    Dir["{app,config,db,lib}/**/*", "MIT-LICENSE", "Rakefile", "README.md"]
  end

  spec.add_dependency "rails", ">= 7.0.0.0"
  spec.metadata["rubygems_mfa_required"] = "true"
end
