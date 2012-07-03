module Raven
  # Middleware for Rack applications. Any errors raised by the upstream
  # application will be delivered to Sentry and re-raised.
  #
  # Synopsis:
  #
  #   require 'rack'
  #   require 'raven'
  #
  #   Raven.configure do |config|
  #     config.server = 'http://my_dsn'
  #   end
  #
  #   app = Rack::Builder.app do
  #     use Raven::Rack
  #     run lambda { |env| raise "Rack down" }
  #   end
  #
  # Use a standard Raven.configure call to configure your server credentials.
  class Rack
    def initialize(app)
      @app = app
    end

    def call(env)
      begin
        response = @app.call(env)
      rescue Error => e
        raise # Don't capture Raven errors
      rescue Exception => e
        send_exception_to_sentry(e, env)
        raise
      end

      rack_exc = env['rack.exception']
      send_exception_to_sentry(rack_exc, env) if rack_exc

      response
    end

  private

    def send_exception_to_sentry(exception, env)
      event_class = Raven.configuration.event_class
      evt = event_class.capture_rack_exception(e, env)
      Raven.send(evt) if evt
    rescue Exception => e
      Raven.logger.error("Error handling exception `#{exception}`: #{e}")
    end

  end
end
