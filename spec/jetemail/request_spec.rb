# frozen_string_literal: true

RSpec.describe JetEmail::Request do
  let(:base_url) { "https://api.jetemail.com" }

  describe "#initialize" do
    it "raises an error when api_key is nil" do
      JetEmail.api_key = nil
      expect { JetEmail::Request.new("email", {}, "post") }
        .to raise_error(JetEmail::Error, "API key is not set")
    end

    it "supports Proc-based api_key" do
      JetEmail.api_key = -> { "transactional_proc_key" }

      stub_request(:post, "#{base_url}/email")
        .to_return(status: 200, body: '{"id":"msg_1"}', headers: { "Content-Type" => "application/json" })

      JetEmail::Request.new("email", { from: "a@b.com" }, "post").perform
      expect(WebMock).to have_requested(:post, "#{base_url}/email")
        .with(headers: { "Authorization" => "Bearer transactional_proc_key" })
    end
  end

  describe "#perform" do
    it "sends a POST request with JSON body" do
      params = { from: "App <hello@test.com>", to: "user@test.com", subject: "Hi", text: "Hello" }

      stub_request(:post, "#{base_url}/email")
        .with(
          body: params.to_json,
          headers: {
            "Authorization" => "Bearer transactional_test_key_123",
            "Content-Type" => "application/json",
            "Accept" => "application/json"
          }
        )
        .to_return(status: 201, body: '{"id":"msg_123","response":"Queued"}', headers: { "Content-Type" => "application/json" })

      result = JetEmail::Request.new("email", params, "post").perform
      expect(result[:id]).to eq("msg_123")
      expect(result[:response]).to eq("Queued")
    end

    it "sends a GET request with query params" do
      stub_request(:get, "#{base_url}/webhooks")
        .with(query: { limit: "10" })
        .to_return(status: 200, body: '{"data":[]}', headers: { "Content-Type" => "application/json" })

      result = JetEmail::Request.new("webhooks", { limit: "10" }, "get").perform
      expect(result[:data]).to eq([])
    end

    it "sends a GET request without body when empty" do
      stub_request(:get, "#{base_url}/webhooks")
        .to_return(status: 200, body: '{"data":[]}', headers: { "Content-Type" => "application/json" })

      result = JetEmail::Request.new("webhooks", {}, "get").perform
      expect(result[:data]).to eq([])
    end

    it "returns empty hash for empty response body" do
      stub_request(:post, "#{base_url}/email")
        .to_return(status: 200, body: "", headers: {})

      result = JetEmail::Request.new("email", { from: "a@b.com" }, "post").perform
      expect(result).to eq({})
    end

    it "includes User-Agent header" do
      stub_request(:post, "#{base_url}/email")
        .to_return(status: 200, body: '{}', headers: { "Content-Type" => "application/json" })

      JetEmail::Request.new("email", { from: "a@b.com" }, "post").perform
      expect(WebMock).to have_requested(:post, "#{base_url}/email")
        .with(headers: { "User-Agent" => "jetemail-ruby:#{JetEmail::VERSION}" })
    end
  end

  describe "error handling" do
    it "raises InvalidRequestError on 400" do
      stub_request(:post, "#{base_url}/email")
        .to_return(status: 400, body: '{"message":"Bad request"}', headers: { "Content-Type" => "application/json" })

      expect { JetEmail::Request.new("email", {}, "post").perform }
        .to raise_error(JetEmail::Error::InvalidRequestError, "Bad request")
    end

    it "raises InvalidRequestError on 401" do
      stub_request(:post, "#{base_url}/email")
        .to_return(status: 401, body: '{"message":"Unauthorized"}', headers: { "Content-Type" => "application/json" })

      expect { JetEmail::Request.new("email", {}, "post").perform }
        .to raise_error(JetEmail::Error::InvalidRequestError, "Unauthorized")
    end

    it "raises NotFoundError on 404" do
      stub_request(:get, "#{base_url}/webhooks/bad-uuid")
        .to_return(status: 404, body: '{"message":"Not found"}', headers: { "Content-Type" => "application/json" })

      expect { JetEmail::Request.new("webhooks/bad-uuid", {}, "get").perform }
        .to raise_error(JetEmail::Error::NotFoundError, "Not found")
    end

    it "raises RateLimitError on 429 with retry_after" do
      stub_request(:post, "#{base_url}/email")
        .to_return(
          status: 429,
          body: '{"message":"Rate limit exceeded"}',
          headers: { "Content-Type" => "application/json", "Retry-After" => "30" }
        )

      expect { JetEmail::Request.new("email", {}, "post").perform }
        .to raise_error(JetEmail::Error::RateLimitError) { |e|
          expect(e.message).to eq("Rate limit exceeded")
          expect(e.retry_after).to eq(30)
        }
    end

    it "raises InternalServerError on 500" do
      stub_request(:post, "#{base_url}/email")
        .to_return(status: 500, body: '{"message":"Internal error"}', headers: { "Content-Type" => "application/json" })

      expect { JetEmail::Request.new("email", {}, "post").perform }
        .to raise_error(JetEmail::Error::InternalServerError, "Internal error")
    end

    it "raises InternalServerError on unparseable JSON" do
      stub_request(:post, "#{base_url}/email")
        .to_return(status: 200, body: "not json", headers: { "Content-Type" => "text/html" })

      expect { JetEmail::Request.new("email", {}, "post").perform }
        .to raise_error(JetEmail::Error::InternalServerError, "Unexpected response from JetEmail API")
    end

    it "falls back to error key in response" do
      stub_request(:post, "#{base_url}/email")
        .to_return(status: 422, body: '{"error":"Validation failed"}', headers: { "Content-Type" => "application/json" })

      expect { JetEmail::Request.new("email", {}, "post").perform }
        .to raise_error(JetEmail::Error::InvalidRequestError, "Validation failed")
    end

    it "uses generic message when no message or error key" do
      stub_request(:post, "#{base_url}/email")
        .to_return(status: 400, body: '{"status":"error"}', headers: { "Content-Type" => "application/json" })

      expect { JetEmail::Request.new("email", {}, "post").perform }
        .to raise_error(JetEmail::Error::InvalidRequestError, "Request failed with status 400")
    end
  end
end
