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
    if job == 'huobi.orders_check'
      Rails.logger.warn "huobi.orders_check started.."
      # Rails.cache.redis.del("orders")
      begin
        loop do
          count_1 = ApplicationController.helpers.huobi_orders_check
          count_2 = ApplicationController.helpers.huobi_orders_close
          # Rails.logger.warn "closing #{count_2} of symbols at #{Time.now.to_s}" if count_2 > 0
          sleep 0.2
          if Time.now.strftime('%M:%S') == "59:59"
            Rails.logger.warn "huobi.orders_check ended.."
            break
          end
        end
      rescue Exception => e
        Rails.logger.warn "orders error: #{e.message}"
      end
    end

    if job == 'huobi.alive_check'
      current_time = Time.now
      check_time = current_time - 60
      orders = []
      orders = Rails.cache.redis.hgetall("orders")
      break if orders.empty?
      c = orders.find {|x| (eval x[1])[:current_time].to_time >= check_time}
      if c.nil? || (c && c.count == 0)
        s = `ps aux | grep 'clockworkd.clock_3' | grep -v grep| awk '{print $2}'`
        pid = s.gsub("\n", "")
        system("kill -9 #{pid}") if pid && pid.to_i > 0
        `god start panda_coins-clock_3`
      end
    end
  end

  every(1.minute, 'huobi.alive_check')
  every(1.hour, 'huobi.orders_check')
  #
  # every(1.day, 'midnight.job', :at => '00:00')
end

# cd /var/www/panda_coins/current/lib/job && clockworkd -c clock.rb start --log -d /var/www/panda_coins/current/lib/job
# clockworkd -c clock.rb start --log -d /Users/hielf/workspace/projects/panda_coins/lib/job
# clockworkd -c clock.rb start --log -d /var/www/panda_coins/current/lib/job
# clockworkd -c clock.rb stop
