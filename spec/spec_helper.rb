# frozen_string_literal: true

require "jetemail"
require "webmock/rspec"

WebMock.disable_net_connect!

RSpec.configure do |config|
  config.before(:each) do
    JetEmail.api_key = "transactional_test_key_123"
  end

  config.after(:each) do
    JetEmail.api_key = nil
  end
end
