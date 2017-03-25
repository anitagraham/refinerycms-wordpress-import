source "http://rubygems.org"

ruby '2.3.1'

# Bundle edge Rails instead: gem 'rails', github: 'rails/rails'
gem 'rails', '~>4.2'

gemspec

gem 'refinerycms', git: 'https://github.com/refinery/refinerycms', branch:'3-0-stable'
gem 'refinerycms-blog', git: 'https://github.com/refinery/refinerycms-blog'
gem 'refinerycms-authentication-devise', '~> 1.0.4'
gem 'acts-as-taggable-on'
gem 'globalize'

gem 'shortcode', '0.1.2'

group :development, :test do
  gem 'factory_girl_rails'
  gem 'generator_spec'

  gem 'guard-rspec'
  gem 'ffi'
  gem 'guard-bundler'
  gem 'fakeweb'
  gem 'libnotify' if  RUBY_PLATFORM =~ /linux/i
  gem 'byebug'
end

group :test do
  gem 'sqlite3'
  gem 'rspec-html-matchers'
end

# Load local gems according to Refinery developer preference.
if File.exist? local_gemfile = File.expand_path('../.gemfile', __FILE__)
  eval File.read(local_gemfile)
end

