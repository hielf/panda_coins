class TestJob < ApplicationJob
  queue_as :low

  after_perform :around_check

  def perform(*args)
    @symbol = args[0]
    p "testing:        #{@symbol}"
    sleep 1
    # TestJob.perform_later "laggggggggggggggggggggg"
    p "testing   done:        #{@symbol}"
    # Rails.logger.warn "testing: #{@symbol}"
  end

  private
  def around_check
    # Rails.cache.redis.hdel("orders", @symbol)
  end

end
