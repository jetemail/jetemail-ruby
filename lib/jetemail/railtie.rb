# frozen_string_literal: true

require "jetemail"
require "jetemail/mailer"

module JetEmail
  class Railtie < ::Rails::Railtie
    ActiveSupport.on_load(:action_mailer) do
      add_delivery_method :jetemail, JetEmail::Mailer
      ActiveSupport.run_load_hooks(:jetemail_mailer, JetEmail::Mailer)
    end
  end
end
