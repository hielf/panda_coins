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
      check_time = Time.now - 60
      changes = []
      changes = Rails.cache.redis.hgetall("orders")
      changes.find {|x| (eval x[1])[:current_time].to_time >= check_time}
      break if changes && changes.count > 0

      loop do
        count = ApplicationController.helpers.huobi_orders_check
        break if count == 0
        sleep 0.2
      end
    end
  end

  # every(10.seconds, 'IB.risk', :thread => true)

  every(1.minute, 'huobi.orders_check', :thread => true)
  # every(1.hour, 'hourly.job')
  #
  # every(1.day, 'midnight.job', :at => '00:00')
end

# cd /var/www/panda_coins/current/lib/job && clockworkd -c clock.rb start --log -d /var/www/panda_coins/current/lib/job
# clockworkd -c clock.rb start --log -d /Users/hielf/workspace/projects/panda_coins/lib/job
# clockworkd -c clock.rb start --log -d /var/www/panda_coins/current/lib/job
# clockworkd -c clock.rb stop
