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
          begin
            job = OrdersCloseJob.perform_now
            sleep 0.2
            # if Time.now.strftime('%M:%S') == "59:59"
            #   Rails.logger.warn "huobi.orders_check ended.."
            #   break
            # end
          rescue Exception => e
            Rails.logger.warn "orders_check error: #{e.message}"
          ensure
            Rails.cache.write('running:clock_4', Time.now, expires_in: 1.minute)
          end
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
  every(5.minutes, 'huobi.alive_check2', :thread => true)
  #
  # every(1.day, 'midnight.job', :at => '00:00')
end

# cd /var/www/panda_coins/current/lib/job && clockworkd -c clock.rb start --log -d /var/www/panda_coins/current/lib/job
# clockworkd -c clock.rb start --log -d /Users/hielf/workspace/projects/panda_coins/lib/job
# clockworkd -c clock.rb start --log -d /var/www/panda_coins/current/lib/job
# clockworkd -c clock.rb stop
