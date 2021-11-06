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
    if job == 'huobi.orders_close'
      Rails.logger.warn "huobi.orders_close started.."
      # Rails.cache.redis.del("orders")
      current_time = Time.now
      runtime = Rails.cache.read('running:clock_4')
      if runtime && (current_time - runtime).abs < 30
        nil
      else
        loop do
          settings = TraderSetting.current_settings
          # token = (Time.now.to_f * 1000).to_i
          begin
            count, closing_symbols = ApplicationController.helpers.huobi_orders_close
            if count > 0
              closing_symbols.each do |symbol|
                amount, shares_amount = ApplicationController.helpers.huobi_close_amount(symbol, 2)
                next if Rails.cache.read("enqueued:closing:#{symbol}")
                Rails.cache.write("enqueued:closing:#{symbol}", ['sell-market', amount, false].join('/'), expires_in: 5.second)
                # OrdersJob.perform_now symbol, 'sell-market', 0, amount, false
                OrdersJob.perform_now symbol, 'sell-market', 0, shares_amount, false
                OrdersJob.perform_now symbol, 'sell-market', 0, shares_amount, false if amount > shares_amount
              end
            end
          rescue Exception => e
            Rails.logger.warn "orders_close clock_4 error: #{e.message}"
          ensure
            Rails.cache.write('running:clock_4', Time.now, expires_in: 1.minute)
          end
          sleep 0.2
        end
      end
    end

    if job == 'huobi.alive_check2'
      Rails.logger.warn "huobi alive checking2.."
      runtime = Rails.cache.read('running:clock_4')
      if runtime.nil?
        Rails.logger.warn "clock_4 restarting.."
        `god restart panda_coins-clock_4`
      end
    end

  end

  every(1.minute, 'huobi.orders_close')
  # every(5.minutes, 'huobi.alive_check2', :skip_first_run => true, :thread => true)
  #
  # every(1.day, 'midnight.job', :at => '00:00')
end

# cd /var/www/panda_coins/current/lib/job && clockworkd -c clock.rb start --log -d /var/www/panda_coins/current/lib/job
# clockworkd -c clock.rb start --log -d /Users/hielf/workspace/projects/panda_coins/lib/job
# clockworkd -c clock.rb start --log -d /var/www/panda_coins/current/lib/job
# clockworkd -c clock.rb stop
