module Spree
  module Webhooks
    module Endpoints
      class QueueRequests
        prepend Spree::ServiceModule::Base

        def call(body:, event:)
          urls_subscribed_to(event).each do |url|
            Spree::Webhooks::Endpoints::MakeRequestJob.perform_later(body, event, url)
          end
        end

        private

        def urls_subscribed_to(event)
          Spree::Webhooks::Endpoint.
            where(enabled: true).
            where(subscriptions_where_statement(event)).
            pluck(:url)
        end

        def subscriptions_where_statement(event)
          case ActiveRecord::Base.connection.adapter_name
          when 'Mysql2'
            ["('*' MEMBER OF(subscriptions) OR ? MEMBER OF(subscriptions))", event]
          when 'PostgreSQL'
            ["subscriptions @> '[\"*\"]' OR subscriptions @> ?", [event].to_json]
          end
        end
      end
    end
  end
end
