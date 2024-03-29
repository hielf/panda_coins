class OrdersJob < ApplicationJob
  queue_as :critical

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
    current_time = Time.now.strftime("%H:%M:%S")
    # last_balance = Rails.cache.redis.hget("balance_his", (Date.today - 1).strftime("%Y-%m-%d")).nil? ? nil : (eval Rails.cache.redis.hget("balance_his", (Date.today - 1).strftime("%Y-%m-%d")))[:balance]
    # today_balance = Rails.cache.redis.hget("balance_his", (Date.today).strftime("%Y-%m-%d")).nil? ? nil : (eval Rails.cache.redis.hget("balance_his", (Date.today).strftime("%Y-%m-%d")))[:balance]
    white_list_symbols = ApplicationController.helpers.white_list
    settings = TraderSetting.current_settings
    run_flag = true

    begin
      if (@type.include? "buy") && (current_time <= settings.buy_accept_start_time && current_time >= settings.buy_accept_end_time)
        Rails.logger.warn "OrdersJob skip openning: #{current_time}, #{@symbol}"
        run_flag = false
      elsif @count == 0
        Rails.logger.warn "OrdersJob amount 0 skipping: #{@symbol}"
        run_flag = false
      elsif (Time.now <= settings.daily_start_time.to_time)
        Rails.logger.warn "OrdersJob skip openning: #{current_time}, #{@symbol}"
        run_flag = false
      # elsif (last_balance && today_balance) && ((today_balance - last_balance) / last_balance) > settings.daily_balance_up_limit.to_f
      #   Rails.logger.warn "OrdersJob skip openning: balance up #{settings.daily_balance_up_limit}"
      #   run_flag = false
      elsif !white_list_symbols.include? @symbol
        Rails.logger.warn "OrdersJob skip openning: #{@symbol} due to new into market"
        run_flag = false
      end

      # sell 0 double check
      if (@type.include? "sell") && @count == 0 && !(current_time <= settings.buy_accept_start_time && current_time >= settings.buy_accept_end_time)
        sleep 5
        amount, shares_amount = ApplicationController.helpers.huobi_close_amount(@symbol, 1)
        frozen_amount = ApplicationController.helpers.huobi_frozen_amount(@symbol)
        Rails.logger.warn "OrdersJob accept_time sell 0 error: #{@symbol}, amount: #{amount}, frozen_amount: #{frozen_amount}"
        OrdersJob.perform_later @symbol, 'sell-market', 0, amount, false if (amount > 0 || frozen_amount > 0)
      end


      if @manual
        Rails.logger.warn "OrdersJob manual #{@type} #{@symbol} #{@count}"
        run_flag = true
      end

      if run_flag
        huobi_pro = HuobiPro.new(ENV["huobi_access_key"],ENV["huobi_secret_key"],ENV["huobi_accounts"])
        @order = huobi_pro.new_order(@symbol,@type,@price,@count)

        if @order["status"] == "error"
          Rails.logger.warn "OrdersJob #{@symbol} #{@type} #{@count} error: #{@order["err-msg"]}"
          message = @symbol + " " + @order["err-msg"]
          SmsJob.perform_later ENV["admin_phone"], ENV["superme_user"] + " " + ENV["version"], message
        else
          # Rails.cache.redis.hgetall("trades")
          if @type.include? "buy"
            Rails.cache.redis.hset("trades", @symbol, {:order_id =>@order["data"]})
          end

          if @type.include? "sell"
            Rails.cache.redis.hdel("trades", @symbol)
          end
        end
      end
    rescue Exception => e
      Rails.logger.warn "OrdersJob error: #{e.message}"
      SmsJob.perform_later ENV["admin_phone"], ENV["superme_user"] + " " + ENV["version"], message
    ensure
      AccountLoggerJob.perform_now(@symbol)
      # OrderLoggersJob.perform_later @symbol
      # AccountLoggerJob.set(wait: 1.second).perform_later(@symbol)
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
