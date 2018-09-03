module Relax
  class EventsQueueNotSetError < StandardError; end

  class EventListener < Base
    DEFAULT_LOG_LEVEL        = 'info'

    @@callback = nil
    @@logger = nil
    @@polling = true

    def self.listen!
      if relax_events_queue.nil? || relax_events_queue == ""
        raise EventsQueueNotSetError, "Environment Variable RELAX_EVENTS_QUEUE is not set"
      end

      # Gracefully handle SIGTERM, stop polling for more events and complete the
      # current event in the 30s grace period. If event doesn't complete within
      # 30s we'll receive a SIGKILL.
      Signal.trap('TERM') {
        polling = false
      }

      Signal.trap('INT') {
        polling = false
      }

      self.log("Listening for Relax Events...")

      while polling do
        begin
          queue_name, event_json = redis.with { |c| c.lpop(relax_events_queue) }

          if queue_name == relax_events_queue
            event = Event.new(JSON.parse(event_json))
            callback.call(event) if callback
          end
        rescue SignalException => e
          self.log("Got signaled #{e.message}")
        end
      end

      self.log("Shutting down...")
    end

    def self.log(text, level = DEFAULT_LOG_LEVEL)
      return if logger.nil?
      logger.send(level, "#{Time.now.strftime('%FT%T%z')}: #{text}")
    end

    def self.callback=(cb)
      @@callback = cb
    end

    def self.callback
      @@callback
    end

    def self.logger=(logger)
      @@logger = logger
    end

    def self.logger
      @@logger
    end

    def self.polling=(polling)
      @@polling = polling
    end

    def self.polling
      self.log("Polling: #{@@polling}")
      @@polling
    end

    def self.relax_events_queue
      ENV['RELAX_EVENTS_QUEUE']
    end
  end
end
