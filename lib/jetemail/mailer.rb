# frozen_string_literal: true

require "jetemail"

module JetEmail
  class Mailer
    attr_accessor :config, :settings

    IGNORED_HEADERS = %w[
      from to cc bcc subject reply-to
      mime-version content-type content-transfer-encoding
      date message-id
    ].freeze

    def initialize(config)
      @config = config
      raise JetEmail::Error.new("API key is not set") unless JetEmail.api_key

      @settings = { return_response: true }
    end

    def deliver!(mail)
      params = build_params(mail)
      resp = JetEmail::Emails.send(params)
      mail.message_id = resp[:id] if resp[:id]
      resp
    end

    private

    def build_params(mail)
      params = {
        from: get_from(mail),
        to: mail.to,
        subject: mail.subject
      }

      params[:cc] = mail.cc if mail.cc&.any?
      params[:bcc] = mail.bcc if mail.bcc&.any?
      params[:reply_to] = mail.reply_to if mail.reply_to&.any?

      params.merge!(get_contents(mail))

      headers = get_headers(mail)
      params[:headers] = headers unless headers.empty?

      attachments = get_attachments(mail)
      params[:attachments] = attachments if attachments.any?

      params
    end

    def get_from(mail)
      return mail.from.first if mail[:from].nil?

      from = mail[:from].formatted
      return from.first if from.is_a?(Array)

      from.to_s
    end

    def get_contents(mail)
      params = {}
      case mail.mime_type
      when "text/plain"
        params[:text] = mail.body.decoded
      when "text/html"
        params[:html] = mail.body.decoded
      when "multipart/alternative", "multipart/mixed", "multipart/related"
        params[:text] = mail.text_part.decoded if mail.text_part
        params[:html] = mail.html_part.decoded if mail.html_part
      end
      params
    end

    def get_headers(mail)
      headers = {}
      mail.header_fields.each do |field|
        next if IGNORED_HEADERS.include?(field.name.downcase)

        headers[field.name] = field.unparsed_value
      end
      headers
    end

    def get_attachments(mail)
      mail.attachments.map do |part|
        headers = part.respond_to?(:header) ? part.header : nil
        filename = part.filename || "attachment"
        {
          filename: filename,
          data: Base64.strict_encode64(part.body.decoded)
        }
      end
    end
  end
end
