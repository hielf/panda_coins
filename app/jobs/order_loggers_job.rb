class OrderLoggersJob < ApplicationJob
  queue_as :low_priority

  after_perform :around_check

  def perform(*args)
    @symbol = args[0]

    ApplicationController.helpers.huobi_orders_log(@symbol)
  end

  private
  def around_check
    # Rails.cache.redis.hdel("orders", @symbol)
  end

end
