# frozen_string_literal: true

require "openssl"

module JetEmail
  WEBHOOK_TOLERANCE_SECONDS = 300

  module Webhooks
    class << self
      # List all webhooks.
      #
      # @return [Hash] List of webhooks
      def list
        path = "webhooks"
        JetEmail::Request.new(path, {}, "get").perform
      end

      # Get a single webhook.
      #
      # @param uuid [String] Webhook UUID
      # @return [Hash] Webhook details
      def get(uuid)
        path = "webhooks/#{uuid}"
        JetEmail::Request.new(path, {}, "get").perform
      end

      # Create a webhook.
      #
      # @param params [Hash] Webhook parameters
      # @option params [String] :name Required. Webhook name
      # @option params [String] :url Required. Webhook URL
      # @option params [Array<String>] :events Required. Event types to subscribe to
      # @return [Hash] Created webhook
      def create(params)
        path = "webhooks"
        JetEmail::Request.new(path, params, "post").perform
      end

      # Update a webhook.
      #
      # @param params [Hash] Webhook parameters
      # @option params [String] :uuid Required. Webhook UUID
      # @return [Hash] Updated webhook
      def update(params)
        path = "webhooks"
        JetEmail::Request.new(path, params, "patch").perform
      end

      # Delete a webhook.
      #
      # @param uuid [String] Webhook UUID
      # @return [Hash] Deletion confirmation
      def remove(uuid)
        path = "webhooks/#{uuid}"
        JetEmail::Request.new(path, {}, "delete").perform
      end

      # Query webhook events.
      #
      # @param params [Hash] Query filters
      # @return [Hash] Matching webhook events
      def query(params = {})
        path = "webhooks/query"
        JetEmail::Request.new(path, params, "post").perform
      end

      # Replay a webhook event.
      #
      # @param params [Hash] Replay parameters
      # @option params [String] :event_id Event ID to replay
      # @option params [String] :source_uid Source UID to replay
      # @return [Hash] Replay confirmation
      def replay(params)
        path = "webhooks/replay"
        JetEmail::Request.new(path, params, "post").perform
      end

      # Verify a webhook signature.
      #
      # @param payload [String] Raw request body
      # @param signature [String] X-Webhook-Signature header value
      # @param timestamp [String] X-Webhook-Timestamp header value
      # @param secret [String] Your webhook secret
      # @param tolerance [Integer] Max age in seconds (default: 300)
      # @return [Boolean] true if valid
      # @raise [JetEmail::Error] if verification fails
      def verify(payload:, signature:, timestamp:, secret:, tolerance: WEBHOOK_TOLERANCE_SECONDS)
        raise JetEmail::Error.new("Payload cannot be empty") if payload.nil? || payload.empty?
        raise JetEmail::Error.new("Signature cannot be empty") if signature.nil? || signature.empty?
        raise JetEmail::Error.new("Timestamp cannot be empty") if timestamp.nil? || timestamp.to_s.empty?
        raise JetEmail::Error.new("Secret cannot be empty") if secret.nil? || secret.empty?

        ts = timestamp.to_i
        diff = (Time.now.to_i - ts).abs
        if tolerance > 0 && diff > tolerance
          raise JetEmail::Error.new("Webhook timestamp is outside tolerance (#{diff}s)")
        end

        expected = "sha256=" + OpenSSL::HMAC.hexdigest("SHA256", secret, payload)
        unless secure_compare(expected, signature)
          raise JetEmail::Error.new("Webhook signature verification failed")
        end

        true
      end

      private

      def secure_compare(a, b)
        return false if a.nil? || b.nil? || a.bytesize != b.bytesize

        bytes_a = a.unpack("C*")
        result = 0
        b.each_byte.with_index { |byte, i| result |= byte ^ bytes_a[i] }
        result.zero?
      end
    end
  end
end
