# JetEmail Ruby SDK

Ruby SDK for the [JetEmail](https://jetemail.com) transactional email service.

## Installation

Add to your Gemfile:

```ruby
gem "jetemail"
```

Then run `bundle install`. Or install directly:

```
gem install jetemail
```

## Configuration

```ruby
require "jetemail"

JetEmail.configure do |config|
  config.api_key = "transactional_your_key_here"
end
```

Or set the `JETEMAIL_API_KEY` environment variable and configure in an initializer.

## Sending Emails

### Single Email

```ruby
JetEmail::Emails.send({
  from: "App <hello@yourdomain.com>",
  to: "user@example.com",
  subject: "Welcome!",
  html: "<h1>Hello</h1><p>Welcome to our app.</p>"
})
# => { id: "msg_123", response: "Queued" }
```

### With Attachments

```ruby
JetEmail::Emails.send({
  from: "App <hello@yourdomain.com>",
  to: "user@example.com",
  subject: "Your invoice",
  html: "<p>Please find your invoice attached.</p>",
  attachments: [
    { filename: "invoice.pdf", data: Base64.strict_encode64(File.read("invoice.pdf")) }
  ]
})
```

### All Options

```ruby
JetEmail::Emails.send({
  from: "App <hello@yourdomain.com>",
  to: ["user1@example.com", "user2@example.com"],  # max 50
  subject: "Hello",
  html: "<h1>Hello</h1>",
  text: "Hello",                                     # plain text fallback
  cc: "cc@example.com",                              # string or array, max 50
  bcc: ["bcc1@example.com"],                         # string or array, max 50
  reply_to: "reply@example.com",                     # string or array, max 50
  headers: { "X-Custom-Header" => "value" },
  attachments: [{ filename: "file.txt", data: "base64..." }],
  eu: true                                           # EU-only delivery
})
```

### Batch Email

Send up to 100 emails in a single request:

```ruby
JetEmail::Batch.send([
  {
    from: "App <hello@yourdomain.com>",
    to: "user1@example.com",
    subject: "Hello User 1",
    html: "<p>Hi User 1</p>"
  },
  {
    from: "App <hello@yourdomain.com>",
    to: "user2@example.com",
    subject: "Hello User 2",
    html: "<p>Hi User 2</p>"
  }
])
# => { summary: { total: 2, successful: 2, failed: 0 }, results: [...] }
```

## Webhooks

### CRUD Operations

```ruby
# List all webhooks
JetEmail::Webhooks.list

# Get a webhook
JetEmail::Webhooks.get("webhook_uuid")

# Create a webhook
JetEmail::Webhooks.create({
  name: "My Webhook",
  url: "https://example.com/webhook",
  events: ["outbound.delivered", "outbound.bounced"]
})

# Update a webhook
JetEmail::Webhooks.update({ uuid: "webhook_uuid", name: "Updated Name" })

# Delete a webhook
JetEmail::Webhooks.remove("webhook_uuid")

# Query webhook events
JetEmail::Webhooks.query({ uuid: "webhook_uuid", event_type: "outbound.delivered" })

# Replay a webhook event
JetEmail::Webhooks.replay({ event_id: "event_123" })
```

### Webhook Event Types

**Outbound:** `outbound.queued`, `outbound.delivered`, `outbound.bounced`, `outbound.rejected`, `outbound.deferred`, `outbound.spam`, `outbound.dropped`, `outbound.virus`, `outbound.opened`, `outbound.clicked`, `outbound.complaint`

### Signature Verification

Verify incoming webhook requests using the `X-Webhook-Signature`, `X-Webhook-Timestamp`, and your webhook secret:

```ruby
JetEmail::Webhooks.verify(
  payload: request.raw_post,
  signature: request.headers["X-Webhook-Signature"],
  timestamp: request.headers["X-Webhook-Timestamp"],
  secret: ENV["JETEMAIL_WEBHOOK_SECRET"]
)
# => true (or raises JetEmail::Error)
```

## Rails Integration

The gem integrates with Rails ActionMailer automatically.

### Setup

In `config/environments/production.rb`:

```ruby
config.action_mailer.delivery_method = :jetemail
```

In an initializer (`config/initializers/jetemail.rb`):

```ruby
JetEmail.configure do |config|
  config.api_key = ENV["JETEMAIL_API_KEY"]
end
```

### Usage

Use ActionMailer as normal:

```ruby
class UserMailer < ApplicationMailer
  def welcome(user)
    mail(
      from: "App <hello@yourdomain.com>",
      to: user.email,
      subject: "Welcome!"
    )
  end
end
```

## Error Handling

```ruby
begin
  JetEmail::Emails.send({ from: "a@b.com", to: "c@d.com", subject: "Hi", text: "Hello" })
rescue JetEmail::Error::RateLimitError => e
  puts "Rate limited. Retry after: #{e.retry_after}s"
rescue JetEmail::Error::InvalidRequestError => e
  puts "Invalid request: #{e.message} (#{e.status_code})"
rescue JetEmail::Error::NotFoundError => e
  puts "Not found: #{e.message}"
rescue JetEmail::Error::InternalServerError => e
  puts "Server error: #{e.message}"
rescue JetEmail::Error => e
  puts "Error: #{e.message} (#{e.status_code})"
end
```

## License

MIT
