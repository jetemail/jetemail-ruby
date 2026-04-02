# frozen_string_literal: true

module JetEmail
  class Request
    BASE_URL = ENV["JETEMAIL_BASE_URL"] || "https://api.jetemail.com"

    attr_accessor :body, :verb

    def initialize(path = "", body = {}, verb = "post")
      raise JetEmail::Error.new("API key is not set") if JetEmail.api_key.nil?

      api_key = JetEmail.api_key
      api_key = api_key.call if api_key.is_a?(Proc)

      @path = path
      @body = body
      @verb = verb
      @headers = {
        "Content-Type" => "application/json",
        "Accept" => "application/json",
        "User-Agent" => "jetemail-ruby:#{JetEmail::VERSION}",
        "Authorization" => "Bearer #{api_key}"
      }
    end

    def perform
      options = build_options
      resp = HTTParty.send(@verb.to_sym, "#{BASE_URL}/#{@path}", options)

      data = parse_response(resp)
      handle_error!(data, resp) if error_response?(resp)
      data
    end

    private

    def build_options
      options = { headers: @headers }

      if @verb.downcase == "get" && !@body.empty?
        options[:query] = @body
      elsif !@body.empty?
        options[:body] = @body.to_json
      end

      options
    end

    def parse_response(resp)
      return {} if resp.body.nil? || resp.body.empty?

      JSON.parse(resp.body, symbolize_names: true)
    rescue JSON::ParserError
      raise JetEmail::Error::InternalServerError.new("Unexpected response from JetEmail API", resp.code)
    end

    def error_response?(resp)
      resp.code >= 400
    end

    def handle_error!(data, resp)
      raw_headers = resp.respond_to?(:headers) ? resp.headers.to_h : {}
      headers = raw_headers.transform_values { |v| v.is_a?(Array) ? v.last : v }
      message = data[:message] || data[:error] || "Request failed with status #{resp.code}"
      error_class = JetEmail::Error::ERRORS[resp.code] || JetEmail::Error
      raise error_class.new(message, resp.code, headers)
    end
  end
end
