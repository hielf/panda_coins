class OrderLoggersJob < ApplicationJob
  queue_as :low

  after_perform :around_check

  def perform(*args)
    @symbol = args[0]
    # @pnls = args[1]

    begin
      rbalance =  Rails.cache.redis.hget("balances", "usdt:trade")
      current_balance = (eval rbalance)[:balance].to_f if rbalance
      end_time = Time.now
      Rails.cache.redis.hset("balance_his", end_time.strftime("%Y-%m-%d"), {:balance => current_balance})
    rescue Exception => e
      Rails.logger.warn "OrderLoggersJob balances error: #{e.message}"
    end

    begin
      # pnls = ApplicationController.helpers.huobi_pnls(@symbol)
      # ApplicationController.helpers.huobi_pnls_log(@symbol, pnls)

      data = eval Rails.cache.redis.hget("orders:closing", @symbol)
      ApplicationController.helpers.huobi_orders_log(@symbol, data)
    rescue Exception => e
      Rails.logger.warn "OrderLoggersJob huobi_orders_log error: #{e.message}"
    end

  end

  private
  def around_check
    # Rails.cache.redis.del("pnl:#{@symbol}")
    Rails.cache.redis.expire("pnl:#{@symbol}", 600)
  end

end
