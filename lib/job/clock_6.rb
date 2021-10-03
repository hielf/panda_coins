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
    if job == 'huobi.open_orders'

      loop do
        Rails.logger.warn "openning #{open_count} of new symbols at #{end_time.to_s}"
        open_symbols.each do |data|
          symbol = data[0]
          hash = eval data[1]
          current_balance = 0
          begin
            rbalance =  Rails.cache.redis.hget("balances", "usdt:trade")
            current_balance = (eval rbalance)[:balance].to_f if rbalance
            current_trades = Rails.cache.redis.hgetall("trades")
            # divide_shares = current_trades.count == 0 ? settings.first_share_divide.to_i : settings.divide_shares.to_i
            divide_shares = settings.divide_shares.to_i
            amount = (current_balance / (divide_shares - current_trades.count)).truncate(0)

            OrdersJob.perform_now symbol, 'buy-market', 0, amount, false
            Rails.logger.warn "symbol #{symbol} open @ #{hash[:close]} amount: #{amount}"
          rescue FloatDomainError => e
            Rails.logger.warn "symbol #{symbol} open skipped: shares all used"
          ensure
            Rails.cache.redis.hset("balance_his", end_time.strftime("%Y-%m-%d"), {:balance => current_balance})
          end
        end
      end

    end
  end

  every(1.minute, 'huobi.open_orders')

  # every(1.minute, 'timing', :skip_first_run => true, :thread => true)
  # every(1.hour, 'hourly.job')
  #
  # every(1.day, 'midnight.job', :at => '00:00')
end

# cd /var/www/panda_coins/current/lib/job && clockworkd -c clock.rb start --log -d /var/www/panda_coins/current/lib/job
# clockworkd -c clock.rb start --log -d /Users/hielf/workspace/projects/panda_coins/lib/job
# clockworkd -c clock.rb start --log -d /var/www/panda_coins/current/lib/job
# clockworkd -c clock.rb stop
