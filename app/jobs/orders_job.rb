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
    @manual = args[4]

    message = "交易错误"
    huobi_pro = HuobiPro.new(ENV["huobi_access_key"],ENV["huobi_secret_key"],ENV["huobi_accounts"])
    current_time = Time.now.strftime("%H:%M")
    last_balance = Rails.cache.redis.hget("balance_his", (Date.today - 1).strftime("%Y-%m-%d")).nil? ? nil : (eval Rails.cache.redis.hget("balance_his", (Date.today - 1).strftime("%Y-%m-%d")))[:balance]
    today_balance = Rails.cache.redis.hget("balance_his", (Date.today).strftime("%Y-%m-%d")).nil? ? nil : (eval Rails.cache.redis.hget("balance_his", (Date.today).strftime("%Y-%m-%d")))[:balance]
    run_flag = true
    begin
      if (@type.include? "buy") && (current_time <= ENV["buy_accept_start_time"] && current_time >= ENV["buy_accept_end_time"])
        Rails.logger.warn "OrdersJob skip openning: #{@symbol}"
        run_flag = false
      elsif @count == 0
        Rails.logger.warn "OrdersJob amount 0 skipping: #{@symbol}"
        run_flag = false
      elsif (last_balance && today_balance) && ((today_balance - last_balance) / last_balance) > ENV["daily_balance_up_limit"].to_f
        Rails.logger.warn "OrdersJob skip openning: balance up #{ENV["daily_balance_up_limit"]}"
        run_flag = false
      end

      if run_flag
        @order = huobi_pro.new_order(@symbol,@type,@price,@count)

        if @order["status"] == "error"
          message = @order["err-msg"]
          SmsJob.perform_later ENV["admin_phone"], ENV["superme_user"] + " " + ENV["version"], message
        else
          # Rails.cache.redis.hgetall("trades")
          Rails.cache.redis.hset("trades", @symbol, {:order_id =>@order["data"]}) if @type.include? "buy"
          Rails.cache.redis.hdel("trades", @symbol) if @type.include? "sell"
        end
      end
    rescue Exception => e
      Rails.logger.warn "OrdersJob error: #{e.message}"
      SmsJob.perform_later ENV["admin_phone"], ENV["superme_user"] + " " + ENV["version"], message
    ensure
      AccountLoggerJob.set(wait: 1.second).perform_later(@symbol)
    end
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
