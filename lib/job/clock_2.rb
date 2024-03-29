require 'clockwork'
# require 'clockwork/database_events'
require '../../config/boot'
require '../../config/environment'
require 'active_support/time' # Allow numeric durations (eg: 1.minutes)

module Clockwork
  # configure do |config|
  #   config[:sleep_timeout] = 5
  #   config[:logger] = Logger.new(log_file_path)
  #   config[:tz] = 'EST'
  #   config[:max_threads] = 15
  #   config[:thread] = true
  # end

  # handler receives the time when job is prepared to run in the 2nd argument
  handler do |job, time|
    if job == 'huobi.tickers_check'
      # check_time = Time.now - 60
      # tickers = []
      # tickers = Rails.cache.redis.hgetall("tickers")
      # if tickers && !tickers.empty?
      #   c = tickers.find {|x| (eval x[1])[:time] >= check_time}
      #   return if c && c.count > 0
      # end
      current_time = Time.now
      runtime = Rails.cache.read('running:clock_2')
      if runtime && (current_time - runtime).abs < 30
        nil
      else
        loop do
          settings = TraderSetting.current_settings
          begin
            start_time = Time.now - settings.tickers_check_interval.to_i
            end_time = Time.now

            if settings.daily_start_time && !settings.daily_start_time.empty? && end_time <= settings.daily_start_time.to_time
              # p end_time.strftime("%H:%M:%S")
              next
            end

            if end_time >= Time.now.beginning_of_day && end_time <= Time.now.beginning_of_day + settings.tickers_check_interval.to_i
              start_time = nil
            end

            symbols = ApplicationController.helpers.huobi_tickers_check(settings, start_time, end_time)
            open_count, open_symbols = ApplicationController.helpers.huobi_open_symbols(settings, symbols)

            if open_count > 0
              Rails.logger.warn "openning #{open_count} of new symbols at #{end_time.to_s}"
              open_symbols.each do |data|
                symbol = data[0]
                hash = eval data[1]
                ApplicationController.helpers.huobi_open_order(symbol, hash, settings)
                # current_balance = 0
                # begin
                #   # rbalance =  Rails.cache.redis.hget("balances", "usdt:trade")
                #   # current_balance = (eval rbalance)[:balance].to_f if rbalance
                #   # current_trades = Rails.cache.redis.hgetall("trades")
                #   # # divide_shares = current_trades.count == 0 ? settings.first_share_divide.to_i : settings.divide_shares.to_i
                #   # divide_shares = settings.divide_shares.to_i
                #   # amount = (current_balance / (divide_shares - current_trades.count)).truncate(0)
                #   current_trades = Rails.cache.redis.hgetall("trades")
                #   last_balance = Rails.cache.redis.hget("balance_his", (Date.today - 1).strftime("%Y-%m-%d")).nil? ? nil : (eval Rails.cache.redis.hget("balance_his", (Date.today - 1).strftime("%Y-%m-%d")))[:balance]
                #   divide_shares = settings.divide_shares.to_i
                #   use_balance = last_balance * settings.balance_proportion.to_f
                #   amount = (use_balance / divide_shares).truncate(0)
                #
                #   if current_trades.count < divide_shares
                #     OrdersJob.perform_now symbol, 'buy-market', 0, amount, false
                #     Rails.logger.warn "symbol #{symbol} open @ #{hash[:close]} amount: #{amount}"
                #   else
                #     Rails.logger.warn "symbol #{symbol} open skipped: shares all used"
                #   end
                # # rescue FloatDomainError => e
                # #   Rails.logger.warn "symbol #{symbol} open skipped: shares all used"
                # rescue Exception => e
                #   Rails.logger.warn "orders_open clock_2 error: #{e.message}"
                # end
              end
            end

            sleep 0.2
          rescue Exception => e
            Rails.logger.warn "tickers_check job error: #{e.message}"
          ensure
            Rails.cache.write('running:clock_2', Time.now, expires_in: 1.minute)
          end
        end
      end
    end
  end

  every(1.minute, 'huobi.tickers_check')

  # every(1.minute, 'timing', :skip_first_run => true, :thread => true)
  # every(1.hour, 'hourly.job')
  #
  # every(1.day, 'midnight.job', :at => '00:00')
end

# cd /var/www/panda_coins/current/lib/job && clockworkd -c clock.rb start --log -d /var/www/panda_coins/current/lib/job
# clockworkd -c clock.rb start --log -d /Users/hielf/workspace/projects/panda_coins/lib/job
# clockworkd -c clock.rb start --log -d /var/www/panda_coins/current/lib/job
# clockworkd -c clock.rb stop
