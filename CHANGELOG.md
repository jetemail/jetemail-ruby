# Changelog

## 0.1.0

- Initial release
- Send single emails via `JetEmail::Emails.send`
- Send batch emails via `JetEmail::Batch.send`
- Webhooks CRUD: list, get, create, update, remove, query, replay
- Webhook signature verification via `JetEmail::Webhooks.verify`
- Rails ActionMailer integration
- Error handling with typed exceptions and rate limit support
