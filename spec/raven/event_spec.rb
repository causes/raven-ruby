require File::expand_path('../../spec_helper', __FILE__)
require 'raven'

describe Raven::Event do
  describe '.capture_exception' do
    let(:message) { 'This is a message' }
    let(:exception) { Exception.new(message) }
    let(:hash) { Raven::Event.capture_exception(exception).to_hash }

    context 'for an Exception' do
      it 'returns an event' do
        Raven::Event.capture_exception(exception).should be_a(Raven::Event)
      end

      it "sets the message to the exception's message" do
        hash['message'].should == message
      end

      # sentry uses python's logging values; 40 is the value of logging.ERROR
      it 'has level ERROR' do
        hash['level'].should == 40
      end

      it 'uses the exception class name as the exception type' do
        hash['sentry.interfaces.Exception']['type'].should == 'Exception'
      end

      it 'uses the exception message as the exception value' do
        hash['sentry.interfaces.Exception']['value'].should == message
      end

      it 'does not belong to a module' do
        hash['sentry.interfaces.Exception']['module'].should == ''
      end
    end

    context 'for a nested exception type' do
      module Raven::Test
        class Exception < Exception; end
      end
      let(:exception) { Raven::Test::Exception.new(message) }

      it 'sends the module name as part of the exception info' do
        hash['sentry.interfaces.Exception']['module'].should == 'Raven::Test'
      end
    end

    context 'for a Raven::Error' do
      let(:exception) { Raven::Error.new }
      it 'does not create an event' do
        Raven::Event.capture_exception(exception).should be_nil
      end
    end

  end
end
