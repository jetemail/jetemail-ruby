# frozen_string_literal: true

RSpec.describe JetEmail::Webhooks do
  let(:base_url) { "https://api.jetemail.com" }

  describe ".list" do
    it "lists all webhooks" do
      stub_request(:get, "#{base_url}/webhooks")
        .to_return(
          status: 200,
          body: '{"data":[{"uuid":"wh_1","name":"My Webhook"}]}',
          headers: { "Content-Type" => "application/json" }
        )

      result = JetEmail::Webhooks.list
      expect(result[:data].length).to eq(1)
      expect(result[:data][0][:name]).to eq("My Webhook")
    end
  end

  describe ".get" do
    it "gets a single webhook" do
      stub_request(:get, "#{base_url}/webhooks/wh_123")
        .to_return(
          status: 200,
          body: '{"uuid":"wh_123","name":"Test","url":"https://example.com/hook"}',
          headers: { "Content-Type" => "application/json" }
        )

      result = JetEmail::Webhooks.get("wh_123")
      expect(result[:uuid]).to eq("wh_123")
      expect(result[:url]).to eq("https://example.com/hook")
    end
  end

  describe ".create" do
    it "creates a webhook" do
      params = {
        name: "New Hook",
        url: "https://example.com/webhook",
        events: ["outbound.delivered", "outbound.bounced"]
      }

      stub_request(:post, "#{base_url}/webhooks")
        .with(body: params.to_json)
        .to_return(
          status: 201,
          body: '{"uuid":"wh_new","name":"New Hook","secret":"whsec_abc"}',
          headers: { "Content-Type" => "application/json" }
        )

      result = JetEmail::Webhooks.create(params)
      expect(result[:uuid]).to eq("wh_new")
      expect(result[:secret]).to eq("whsec_abc")
    end
  end

  describe ".update" do
    it "updates a webhook" do
      params = { uuid: "wh_123", name: "Updated Hook" }

      stub_request(:patch, "#{base_url}/webhooks")
        .with(body: params.to_json)
        .to_return(
          status: 200,
          body: '{"uuid":"wh_123","name":"Updated Hook"}',
          headers: { "Content-Type" => "application/json" }
        )

      result = JetEmail::Webhooks.update(params)
      expect(result[:name]).to eq("Updated Hook")
    end
  end

  describe ".remove" do
    it "deletes a webhook" do
      stub_request(:delete, "#{base_url}/webhooks/wh_123")
        .to_return(
          status: 200,
          body: '{"message":"Webhook deleted"}',
          headers: { "Content-Type" => "application/json" }
        )

      result = JetEmail::Webhooks.remove("wh_123")
      expect(result[:message]).to eq("Webhook deleted")
    end
  end

  describe ".query" do
    it "queries webhook events" do
      params = { uuid: "wh_123", event_type: "outbound.delivered" }

      stub_request(:post, "#{base_url}/webhooks/query")
        .with(body: params.to_json)
        .to_return(
          status: 200,
          body: '{"data":[{"event_id":"evt_1","event_type":"outbound.delivered"}]}',
          headers: { "Content-Type" => "application/json" }
        )

      result = JetEmail::Webhooks.query(params)
      expect(result[:data].length).to eq(1)
    end
  end

  describe ".replay" do
    it "replays a webhook event" do
      stub_request(:post, "#{base_url}/webhooks/replay")
        .with(body: { event_id: "evt_1" }.to_json)
        .to_return(
          status: 200,
          body: '{"message":"Event replayed"}',
          headers: { "Content-Type" => "application/json" }
        )

      result = JetEmail::Webhooks.replay({ event_id: "evt_1" })
      expect(result[:message]).to eq("Event replayed")
    end
  end

  describe ".verify" do
    let(:secret) { "my_webhook_secret" }
    let(:payload) { '{"type":"outbound.delivered","data":{}}' }
    let(:timestamp) { Time.now.to_i.to_s }

    def sign(payload, secret)
      "sha256=" + OpenSSL::HMAC.hexdigest("SHA256", secret, payload)
    end

    it "returns true for a valid signature" do
      signature = sign(payload, secret)

      result = JetEmail::Webhooks.verify(
        payload: payload,
        signature: signature,
        timestamp: timestamp,
        secret: secret
      )
      expect(result).to be true
    end

    it "raises on invalid signature" do
      expect {
        JetEmail::Webhooks.verify(
          payload: payload,
          signature: "sha256=invalid",
          timestamp: timestamp,
          secret: secret
        )
      }.to raise_error(JetEmail::Error, "Webhook signature verification failed")
    end

    it "raises on expired timestamp" do
      old_timestamp = (Time.now.to_i - 600).to_s
      signature = sign(payload, secret)

      expect {
        JetEmail::Webhooks.verify(
          payload: payload,
          signature: signature,
          timestamp: old_timestamp,
          secret: secret
        )
      }.to raise_error(JetEmail::Error, /Webhook timestamp is outside tolerance/)
    end

    it "allows custom tolerance" do
      old_timestamp = (Time.now.to_i - 600).to_s
      signature = sign(payload, secret)

      result = JetEmail::Webhooks.verify(
        payload: payload,
        signature: signature,
        timestamp: old_timestamp,
        secret: secret,
        tolerance: 1000
      )
      expect(result).to be true
    end

    it "raises when payload is empty" do
      expect {
        JetEmail::Webhooks.verify(payload: "", signature: "sig", timestamp: timestamp, secret: secret)
      }.to raise_error(JetEmail::Error, "Payload cannot be empty")
    end

    it "raises when signature is empty" do
      expect {
        JetEmail::Webhooks.verify(payload: payload, signature: "", timestamp: timestamp, secret: secret)
      }.to raise_error(JetEmail::Error, "Signature cannot be empty")
    end

    it "raises when timestamp is nil" do
      expect {
        JetEmail::Webhooks.verify(payload: payload, signature: "sig", timestamp: nil, secret: secret)
      }.to raise_error(JetEmail::Error, "Timestamp cannot be empty")
    end

    it "raises when secret is empty" do
      expect {
        JetEmail::Webhooks.verify(payload: payload, signature: "sig", timestamp: timestamp, secret: "")
      }.to raise_error(JetEmail::Error, "Secret cannot be empty")
    end
  end
end
