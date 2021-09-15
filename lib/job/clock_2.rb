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
        break
      else
        loop do
          begin
            start_time = Time.now - 120
            end_time = Time.now

            symbols = ApplicationController.helpers.huobi_tickers_check(start_time, end_time)
            open_count, open_symbols = ApplicationController.helpers.huobi_open_symbols(symbols)

            if open_count > 0
              Rails.logger.warn "openning #{open_count} of new symbols at #{end_time.to_s}"
              open_symbols.each do |data|
                symbol = data[0]
                hash = eval data[1]
                current_balance = TraderBalance.find_by(account_id: ENV["huobi_accounts"], currency: "usdt", balance_type: "trade").balance.to_f
                current_trades = Rails.cache.redis.hgetall("trades")
                amount = (current_balance / (ENV['dvide_shares'].to_i - current_trades.count)).truncate(0)

                OrdersJob.perform_now symbol, 'buy-market', 0, amount

                Rails.logger.warn "symbol #{symbol} opened @ #{hash[:close]} amount: #{amount}"
              end
            end

            sleep 6
          rescue Exception => e
            Rails.logger.warn "tickers_check error: #{e.message}"
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
