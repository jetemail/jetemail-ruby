# frozen_string_literal: true

RSpec.describe JetEmail::Error do
  it "stores status_code and headers" do
    error = JetEmail::Error.new("test", 400, { "x-request-id" => "abc" })
    expect(error.message).to eq("test")
    expect(error.status_code).to eq(400)
    expect(error.headers).to eq({ "x-request-id" => "abc" })
  end

  it "defaults headers to empty hash" do
    error = JetEmail::Error.new("test", 500)
    expect(error.headers).to eq({})
  end

  it "handles nil headers" do
    error = JetEmail::Error.new("test", 500, nil)
    expect(error.headers).to eq({})
  end

  describe "error hierarchy" do
    it "ClientError is a JetEmail::Error" do
      expect(JetEmail::Error::ClientError.new("test")).to be_a(JetEmail::Error)
    end

    it "ServerError is a JetEmail::Error" do
      expect(JetEmail::Error::ServerError.new("test")).to be_a(JetEmail::Error)
    end

    it "InvalidRequestError is a ClientError" do
      expect(JetEmail::Error::InvalidRequestError.new("test")).to be_a(JetEmail::Error::ClientError)
    end

    it "NotFoundError is a ClientError" do
      expect(JetEmail::Error::NotFoundError.new("test")).to be_a(JetEmail::Error::ClientError)
    end

    it "RateLimitError is a ClientError" do
      expect(JetEmail::Error::RateLimitError.new("test")).to be_a(JetEmail::Error::ClientError)
    end

    it "InternalServerError is a ServerError" do
      expect(JetEmail::Error::InternalServerError.new("test")).to be_a(JetEmail::Error::ServerError)
    end
  end

  describe JetEmail::Error::RateLimitError do
    it "extracts retry_after from headers" do
      error = JetEmail::Error::RateLimitError.new("rate limited", 429, { "retry-after" => "60" })
      expect(error.retry_after).to eq(60)
    end

    it "handles missing retry-after header" do
      error = JetEmail::Error::RateLimitError.new("rate limited", 429, {})
      expect(error.retry_after).to be_nil
    end
  end

  describe "ERRORS mapping" do
    it "maps status codes to error classes" do
      expect(JetEmail::Error::ERRORS[400]).to eq(JetEmail::Error::InvalidRequestError)
      expect(JetEmail::Error::ERRORS[401]).to eq(JetEmail::Error::InvalidRequestError)
      expect(JetEmail::Error::ERRORS[403]).to eq(JetEmail::Error::InvalidRequestError)
      expect(JetEmail::Error::ERRORS[404]).to eq(JetEmail::Error::NotFoundError)
      expect(JetEmail::Error::ERRORS[422]).to eq(JetEmail::Error::InvalidRequestError)
      expect(JetEmail::Error::ERRORS[429]).to eq(JetEmail::Error::RateLimitError)
      expect(JetEmail::Error::ERRORS[500]).to eq(JetEmail::Error::InternalServerError)
    end
  end
end
