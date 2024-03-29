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

    if job == 'huobi.tickers_cache'
      current_time = Time.now
      keys = Rails.cache.redis.keys.sort
      times = []
      keys.each do |key|
        times << key if (!(key.count("a-zA-Z") > 0) && (DateTime.parse key rescue nil))
      end

      if times.empty? || current_time - times[-1].to_time > 30
        Rails.logger.warn "last tickers expired collecting tickers_cache"
        begin
          ApplicationController.helpers.huobi_tickers_cache_ws
        rescue Exception => e
          Rails.logger.warn "huobi.tickers_cache error: #{e.message}"
        end
      end
    end

  end

  # # trades
  every(1.minute, 'huobi.tickers_cache')

  # every(1.minute, 'timing', :skip_first_run => true, :thread => true)
  # every(1.hour, 'hourly.job')
  #
end

# cd /var/www/panda_coins/current/lib/job && clockworkd -c clock.rb start --log -d /var/www/panda_coins/current/lib/job
# clockworkd -c clock.rb start --log -d /Users/hielf/workspace/projects/panda_coins/lib/job
# clockworkd -c clock.rb start --log -d /var/www/panda_coins/current/lib/job
# clockworkd -c clock.rb stop
