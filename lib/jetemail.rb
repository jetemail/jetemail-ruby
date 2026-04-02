# frozen_string_literal: true

require "httparty"
require "json"

require "jetemail/version"
require "jetemail/errors"
require "jetemail/request"
require "jetemail/emails"
require "jetemail/batch"
require "jetemail/webhooks"

require "jetemail/railtie" if defined?(Rails) && defined?(ActionMailer)

module JetEmail
  class << self
    attr_accessor :api_key

    def configure
      yield self if block_given?
      true
    end
    alias_method :config, :configure
  end
end
