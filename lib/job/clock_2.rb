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
      check_time = Time.now - 60
      tickers = []
      tickers = Rails.cache.redis.hgetall("tickers")
      if tickers && !tickers.empty?
        c = tickers.find {|x| (eval x[1])[:time] >= check_time}
        break if c && c.count > 0
      end

      loop do
        start_time = Time.now - 120
        end_time = Time.now

        symbols = ApplicationController.helpers.huobi_tickers_check(start_time, end_time)
        open_count = ApplicationController.helpers.huobi_open_symbols(symbols)
        Rails.logger.warn "openning #{open_count} of new symbols at #{end_time.to_s}" if open_count > 0

        sleep 6
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
