def setup_environment
  # Configure Rails Environment
  ENV["RAILS_ENV"] ||= 'test'

  require File.expand_path("../dummy/config/environment", __FILE__)

  require 'rspec/rails'
  require 'capybara/rspec'
  require "database_cleaner"

  #ActionMailer::Base.delivery_method = :test
  #ActionMailer::Base.perform_deliveries = true
  #ActionMailer::Base.default_url_options[:host] = "test.com"

  # require "custom_matchers.rb"

  Rails.backtrace_cleaner.remove_silencers!

  # Run any available migration
  ActiveRecord::Migrator.migrate File.expand_path("../dummy/db/migrate/", __FILE__)

  RSpec.configure do |config|
    # Remove this line if you don't want RSpec's should and should_not
    # methods or matchers
    require 'rspec/expectations'
    include RSpecHtmlMatchers

    config.include RSpec::Matchers

    config.mock_with :rspec
    config.filter_run :focus => true
    config.run_all_when_everything_filtered = true
    config.include FactoryGirl::Syntax::Methods

    config.before(:suite) do
      DatabaseCleaner.strategy = :transaction
      DatabaseCleaner.clean_with(:truncation)
    end

    # config.before(:each) do
      # DatabaseCleaner.start
    # end

    # config.after(:each) do
      # DatabaseCleaner.clean
    # end

  end
end

def each_run
  Rails.cache.clear
  ActiveSupport::Dependencies.clear
  FactoryGirl.reload

  # Requires supporting files with custom matchers and macros, etc,
  # in ./support/ and its subdirectories including factories.
  ([Rails.root.to_s] | ::Refinery::Plugins.registered.pathnames).map{|p|
    Dir[File.join(p, 'spec', 'support', '**', '*.rb').to_s]
  }.flatten.sort.each do |support_file|
    require support_file
  end

  # It isn't really a engine, per se.
  puts Rails.root.join("../support/**/*.rb")
  Dir[Rails.root.join("../support/**/*.rb")].each {|f| require f}

end

# If spork is available in the Gemfile it'll be used but we don't force it.
unless (begin; require 'spork'; rescue LoadError; nil end).nil?
  Spork.prefork do
    # Loading more in this block will cause your tests to run faster. However,
    # if you change any configuration or code from libraries loaded here, you'll
    # need to restart spork for it take effect.
    setup_environment
  end

  Spork.each_run do
    # This code will be run each time you run your specs.
    each_run
  end
else
  setup_environment
  each_run
end

