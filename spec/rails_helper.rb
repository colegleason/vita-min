# This file is copied to spec/ when you run 'rails generate rspec:install'
ENV["RAILS_ENV"] ||= "test"
require File.expand_path("../config/environment", __dir__)

require "spec_helper"
require "capybara/rails"
require "capybara/rspec"
require "selenium/webdriver"
require "webdrivers"
Dir[Rails.root.join("spec/support/**/*.rb")].each { |f| require f }
Dir[Rails.root.join("lib/strategies/**/*.rb")].each { |f| require f }

# Set CHROME=true to run specs with a visible Chrome window
if ENV.fetch("CHROME", false)
  Capybara.javascript_driver = :selenium_chrome
  Capybara.default_max_wait_time = 10
else
  Capybara.javascript_driver = :selenium_chrome_headless
end
Capybara.server = :puma, { Silent: true }
Capybara.server_port = 9887 + ENV['TEST_ENV_NUMBER'].to_i

# Prevent database truncation if the environment is production
abort("The Rails environment is running in production mode!") if Rails.env.production?
require "rspec/rails"


# Add additional requires below this line. Rails is not loaded until this point!

# Requires supporting ruby files with custom matchers and macros, etc, in
# spec/support/ and its subdirectories. Files matching `spec/**/*_spec.rb` are
# run as spec files by default. This means that files in spec/support that end
# in _spec.rb will both be required and run as specs, causing the specs to be
# run twice. It is recommended that you do not name files matching this glob to
# end with _spec.rb. You can configure this pattern with the --pattern
# option on the command line or in ~/.rspec, .rspec or `.rspec-local`.
#
# The following line is provided for convenience purposes. It has the downside
# of increasing the boot-up time by auto-requiring all files in the support
# directory. Alternatively, in the individual `*_spec.rb` files, manually
# require only the support files necessary.
#
# Dir[Rails.root.join('spec', 'support', '**', '*.rb')].each { |f| require f }

# Checks for pending migrations and applies them before tests are run.
# If you are not using ActiveRecord, you can remove these lines.
begin
  ActiveRecord::Migration.maintain_test_schema!
rescue ActiveRecord::PendingMigrationError => e
  puts e.to_s.strip
  exit 1
end
RSpec.configure do |config|
  # Remove this line if you're not using ActiveRecord or ActiveRecord fixtures
  config.fixture_path = "#{::Rails.root}/spec/fixtures"

  config.include Rails.application.routes.url_helpers
  # If you're not using ActiveRecord, or you'd prefer not to run each of your
  # examples within a transaction, remove the following line or assign false
  # instead of true.
  config.use_transactional_fixtures = true

  config.include Warden::Test::Helpers
  config.include Devise::Test::ControllerHelpers, type: :controller
  config.include ChannelHelpers, type: :channel

  # RSpec Rails can automatically mix in different behaviours to your tests
  # based on their file location, for example enabling you to call `get` and
  # `post` in specs under `spec/controllers`.
  #
  # You can disable this behaviour by removing the line below, and instead
  # explicitly tag your specs with their type, e.g.:
  #
  #     RSpec.describe UsersController, :type => :controller do
  #       # ...
  #     end
  #
  # The different available types are documented in the features, such as in
  # https://relishapp.com/rspec/rspec-rails/docs
  config.infer_spec_type_from_file_location!

  # Filter lines from Rails gems in backtraces.
  config.filter_rails_from_backtrace!
  # arbitrary gems may also be filtered via:
  # config.filter_gems_from_backtrace("gem name")

  config.before(:all) do
    # Create client support org
    VitaPartner.find_or_create_by!(name: "GYR National Organization")
  end

  config.before(:each) do
    stub_request(:post, /.*api\.twilio\.com.*/).to_return(status: 200, body: "", headers: {})
    stub_request(:post, "https://api.mixpanel.com/track").to_return(status: 200, body: "", headers: {})
    # Stub required credentials to prevent need for RAILS_MASTER_KEY in test
    allow(EnvironmentCredentials).to receive(:dig).and_call_original
    allow(EnvironmentCredentials).to receive(:dig).with(:db_encryption_key).and_return('any-32-character-string-here!!!!')
    # Stub valid_email2's network-dependent functionality per https://github.com/micke/valid_email2
    allow_any_instance_of(ValidEmail2::Address).to receive(:valid_mx?) { true }
    # Stub DNS implementation to avoid network calls from test suite; valid_email2 uses this
    fake_dns = instance_double(Resolv::DNS)
    allow(fake_dns).to receive(:open) { raise StandardError, "Cannot use DNS from test suite" }
    allow(fake_dns).to receive(:close)
    allow(Resolv::DNS).to receive(:new).and_return(fake_dns)
  end

  if ENV['CAPYBARA_WALKTHROUGH_SCREENSHOTS']
    CapybaraWalkthroughScreenshots.hook!(config)
  end
end

Shoulda::Matchers.configure do |config|
  config.integrate do |with|
    with.test_framework :rspec
    with.library :rails
  end
end
