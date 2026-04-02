# frozen_string_literal: true

module JetEmail
  module Emails
    class << self
      # Send a single email.
      #
      # @param params [Hash] Email parameters
      # @option params [String] :from Required. Sender in "Name <email>" format
      # @option params [String, Array<String>] :to Required. Recipient(s), max 50
      # @option params [String] :subject Required. Email subject
      # @option params [String] :html HTML body (at least one of html/text required)
      # @option params [String] :text Plain text body
      # @option params [String, Array<String>] :cc CC recipient(s), max 50
      # @option params [String, Array<String>] :bcc BCC recipient(s), max 50
      # @option params [String, Array<String>] :reply_to Reply-to address(es), max 50
      # @option params [Hash] :headers Custom email headers
      # @option params [Array<Hash>] :attachments File attachments (base64-encoded)
      # @option params [Boolean] :eu EU-only delivery
      # @return [Hash] Response with :id and :response keys
      def send(params)
        path = "email"
        JetEmail::Request.new(path, params, "post").perform
      end
    end
  end
end
