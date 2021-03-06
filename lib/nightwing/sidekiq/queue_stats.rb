require "nightwing/sidekiq/base"

module Nightwing
  module Sidekiq
    ##
    # Sidekiq server middleware for measuring Sidekiq queues
    class QueueStats < Base
      ##
      # Sends Sidekiq queue metrics to client then yields
      #
      # @param [Sidekiq::Worker] _worker
      #   The worker the job belongs to.
      #
      # @param [Hash] _msg
      #   The job message.
      #
      # @param [String] queue
      #   The current queue.
      def call(_worker, _msg, queue)
        sidekiq_queue = ::Sidekiq::Queue.new(queue)
        queue_namespace = metrics.for(queue: queue)

        client.measure "#{queue_namespace}.size", sidekiq_queue.size
        client.measure "#{queue_namespace}.latency", sidekiq_queue.latency
        client.increment "#{queue_namespace}.processed"

        begin
          yield
        rescue
          client.increment "#{queue_namespace}.failed"
          raise
        end
      end
    end
  end
end
