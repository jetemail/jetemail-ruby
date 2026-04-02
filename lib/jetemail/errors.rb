# frozen_string_literal: true

module JetEmail
  class Error < StandardError
    ClientError = Class.new(self)
    ServerError = Class.new(self)
    InternalServerError = Class.new(ServerError)
    InvalidRequestError = Class.new(ClientError)

    class RateLimitError < ClientError
      attr_reader :retry_after

      def initialize(msg, code = nil, headers = {})
        super(msg, code, headers)
        @retry_after = headers["retry-after"]&.to_i
      end
    end

    NotFoundError = Class.new(ClientError)

    ERRORS = {
      400 => InvalidRequestError,
      401 => InvalidRequestError,
      403 => InvalidRequestError,
      404 => NotFoundError,
      422 => InvalidRequestError,
      429 => RateLimitError,
      500 => InternalServerError
    }.freeze

    attr_reader :status_code, :headers

    def initialize(msg, code = nil, headers = {})
      super(msg)
      @status_code = code
      @headers = headers || {}
    end
  end
end
