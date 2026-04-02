# frozen_string_literal: true

RSpec.describe JetEmail::Emails do
  let(:base_url) { "https://api.jetemail.com" }

  describe ".send" do
    it "sends a single email" do
      params = {
        from: "App <hello@test.com>",
        to: "user@test.com",
        subject: "Welcome",
        html: "<h1>Hello</h1>"
      }

      stub_request(:post, "#{base_url}/email")
        .with(body: params.to_json)
        .to_return(
          status: 201,
          body: '{"id":"msg_abc123","response":"Queued"}',
          headers: { "Content-Type" => "application/json" }
        )

      result = JetEmail::Emails.send(params)
      expect(result[:id]).to eq("msg_abc123")
      expect(result[:response]).to eq("Queued")
    end

    it "sends with all optional fields" do
      params = {
        from: "App <hello@test.com>",
        to: ["user1@test.com", "user2@test.com"],
        subject: "Hello",
        html: "<p>Hi</p>",
        text: "Hi",
        cc: "cc@test.com",
        bcc: ["bcc@test.com"],
        reply_to: "reply@test.com",
        headers: { "X-Custom" => "value" },
        attachments: [{ filename: "test.txt", data: "dGVzdA==" }],
        eu: true
      }

      stub_request(:post, "#{base_url}/email")
        .with(body: params.to_json)
        .to_return(
          status: 201,
          body: '{"id":"msg_full","response":"Queued"}',
          headers: { "Content-Type" => "application/json" }
        )

      result = JetEmail::Emails.send(params)
      expect(result[:id]).to eq("msg_full")
    end
  end
end
