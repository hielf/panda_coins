class PnlLoggersJob < ApplicationJob
  queue_as :low_priority

  after_perform :around_check

  def perform(*args)
    @symbol = args[0]
    # @pnls = args[1]

    @pnls = ApplicationController.helpers.huobi_pnls(@symbol)
    ApplicationController.helpers.huobi_pnls_log(@symbol, @pnls)
    ApplicationController.helpers.huobi_orders_log(@symbol)
  end

  private
  def around_check
    # Rails.cache.redis.del("pnl:#{@symbol}")
    Rails.cache.redis.expire("pnl:#{@symbol}", 600)
  end

end
