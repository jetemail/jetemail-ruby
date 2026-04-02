# frozen_string_literal: true

RSpec.describe JetEmail do
  describe ".configure" do
    it "sets the api_key via block" do
      JetEmail.configure do |config|
        config.api_key = "transactional_my_key"
      end

      expect(JetEmail.api_key).to eq("transactional_my_key")
    end

    it "returns true" do
      result = JetEmail.configure { |c| c.api_key = "key" }
      expect(result).to be true
    end
  end

  describe ".config" do
    it "is an alias for .configure" do
      JetEmail.config do |c|
        c.api_key = "transactional_alias_key"
      end

      expect(JetEmail.api_key).to eq("transactional_alias_key")
    end
  end

  describe "VERSION" do
    it "is defined" do
      expect(JetEmail::VERSION).to be_a(String)
      expect(JetEmail::VERSION).not_to be_empty
    end
  end
end
