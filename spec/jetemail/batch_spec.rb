# frozen_string_literal: true

RSpec.describe JetEmail::Batch do
  let(:base_url) { "https://api.jetemail.com" }

  describe ".send" do
    it "sends a batch of emails" do
      emails = [
        { from: "App <hello@test.com>", to: "user1@test.com", subject: "Hi 1", text: "Hello 1" },
        { from: "App <hello@test.com>", to: "user2@test.com", subject: "Hi 2", text: "Hello 2" }
      ]

      stub_request(:post, "#{base_url}/email-batch")
        .with(body: { emails: emails }.to_json)
        .to_return(
          status: 207,
          body: '{"summary":{"total":2,"successful":2,"failed":0},"results":[{"id":"msg_1"},{"id":"msg_2"}]}',
          headers: { "Content-Type" => "application/json" }
        )

      result = JetEmail::Batch.send(emails)
      expect(result[:summary][:total]).to eq(2)
      expect(result[:summary][:successful]).to eq(2)
      expect(result[:results].length).to eq(2)
    end

    it "sends with empty array by default" do
      stub_request(:post, "#{base_url}/email-batch")
        .with(body: { emails: [] }.to_json)
        .to_return(
          status: 207,
          body: '{"summary":{"total":0,"successful":0,"failed":0},"results":[]}',
          headers: { "Content-Type" => "application/json" }
        )

      result = JetEmail::Batch.send
      expect(result[:summary][:total]).to eq(0)
    end
  end
end
