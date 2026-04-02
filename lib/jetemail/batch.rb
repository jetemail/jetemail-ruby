# frozen_string_literal: true

module JetEmail
  module Batch
    class << self
      # Send a batch of up to 100 emails.
      #
      # @param emails [Array<Hash>] Array of email parameter hashes (same schema as Emails.send)
      # @return [Hash] Response with :summary and :results keys
      def send(emails = [])
        path = "email-batch"
        JetEmail::Request.new(path, { emails: emails }, "post").perform
      end
    end
  end
end
