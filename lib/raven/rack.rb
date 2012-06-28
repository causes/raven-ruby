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
        event_class = Raven.configuration.event_class
        evt = event_class.capture_rack_exception(e, env)
        Raven.send(evt) if evt
        raise
      end

      if env['rack.exception']
        event_class = Raven.configuration.event_class
        evt = event_class.capture_rack_exception(e, env)
        Raven.send(evt) if evt
      end

      response
    end
  end
end
