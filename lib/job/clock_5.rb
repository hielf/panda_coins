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

    if job == 'huobi.orders_logger'
      11.times do
        closed_symbols = Rails.cache.redis.hgetall("orders:closing")
        closed_symbols.each do |cs|
          symbol = cs[0]
          # data = eval cs[1]
          # ApplicationController.helpers.huobi_orders_log(symbol, data)
          OrderLoggersJob.perform_later symbol
        end
        p Time.now
        sleep 5
      end
    end

    if job == 'huobi.usdts_symbols'
      begin
        ApplicationController.helpers.usdts_symbols
      rescue Exception => e
        Rails.logger.warn "huobi.usdts_symbols error: #{e.message}"
      end
    end

  end

  every(1.minute, 'huobi.orders_logger')
  every(1.day, 'huobi.usdts_symbols', :at => '12:00', :thread => true)
  every(1.day, 'huobi.usdts_symbols', :at => '23:55', :thread => true)
  # every(5.minutes, 'huobi.alive_check2', :skip_first_run => true, :thread => true)
  #
  # every(1.day, 'midnight.job', :at => '00:00')
end

# cd /var/www/panda_coins/current/lib/job && clockworkd -c clock.rb start --log -d /var/www/panda_coins/current/lib/job
# clockworkd -c clock.rb start --log -d /Users/hielf/workspace/projects/panda_coins/lib/job
# clockworkd -c clock.rb start --log -d /var/www/panda_coins/current/lib/job
# clockworkd -c clock.rb stop
