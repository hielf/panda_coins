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
      begin
        # ApplicationController.helpers.huobi_tickers_cache
        HuobiEm.new.start
      rescue Exception => e
        Rails.logger.warn "huobi.tickers_cache error: #{e.message}"
      end
      # current_time = Time.now
      # runtime = Rails.cache.read("running:clock_1_#{ENV["collect_order"]}")
      # settings = TraderSetting.current_settings
      # if runtime && (current_time - runtime).abs < 30
      #   nil
      # else
      #   Rails.logger.warn "last tickers expired collecting tickers_cache on collect_order #{ENV["collect_order"]}"
      #
      # end
    end
  end

  # # trades
  every(1.minute, 'huobi.tickers_cache')
  # every(1.day, 'huobi.usdts_symbols', :at => '12:00', :thread => true)
  # every(1.day, 'huobi.usdts_symbols', :at => '23:55', :thread => true)
  # every(1.minute, 'timing', :skip_first_run => true, :thread => true)
  # every(1.hour, 'hourly.job')
  #
end

# cd /var/www/panda_coins/current/lib/job && clockworkd -c clock.rb start --log -d /var/www/panda_coins/current/lib/job
# clockworkd -c clock.rb start --log -d /Users/hielf/workspace/projects/panda_coins/lib/job
# clockworkd -c clock.rb start --log -d /var/www/panda_coins/current/lib/job
# clockworkd -c clock.rb stop
