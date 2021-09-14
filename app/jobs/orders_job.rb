class OrdersJob < ApplicationJob
  queue_as :first

  # after_perform :logger

  rescue_from(ActiveRecord::RecordNotFound) do |exception|
     Rails.logger.warn "#{exception.message.to_s}"
  end

  def perform(*args)
    @symbol = args[0]
    @type = args[1]
    @price = args[2]
    @count = args[3]

    message = "交易错误"
    huobi_pro = HuobiPro.new(ENV["huobi_access_key"],ENV["huobi_secret_key"],ENV["huobi_accounts"])
    current_time = Time.now.strftime("%H:%M")
    begin
      if @type.include? "buy" && (current_time > "00:15" && current_time <= "23:59")
        Rails.logger.warn "OrdersJob skip openning: #{@symbol}"
        exit!
      end

      @order = huobi_pro.new_order(@symbol,@type,@price,@count)

      if @order["status"] == "error"
        message = @order["err-msg"]
        SmsJob.perform_later ENV["admin_phone"], ENV["superme_user"] + " " + ENV["version"], message
      else
        # Rails.cache.redis.hset("trades", symbol[0], @order["data"])
        Rails.cache.redis.hset("trades", @symbol, {:order_id =>@order["data"]}) if @type.include? "buy"
        Rails.cache.redis.hdel("trades", @symbol) if @type.include? "sell"
      end
    rescue Exception => e
      Rails.logger.warn "OrdersJob error: #{e.message}"
      SmsJob.perform_later ENV["admin_phone"], ENV["superme_user"] + " " + ENV["version"], message
    ensure
      AccountLoggerJob.set(wait: 1.second).perform_later(@symbol)
    end

    # huobi_pro.history_matchresults(symbol)
    # huobi_pro.new_order(symbol,"sell-market",0,5)

    # SmsJob.perform_later ENV["admin_phone"], ENV["superme_user"] + " " + ENV["backtrader_version"], "无法连接"
  end

  # private
  # def logger
  #   # if @order["status"] == "ok"
  #
  #   # end
  # end

end

# h = eval Rails.cache.redis.hget("symbols", 'wozxusdt')
# huobi_pro.history_matchresults('wozxusdt')
# OrdersJob.perform_later 'wozxusdt', 'buy-market', 0, 5
