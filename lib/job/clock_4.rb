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

          begin
            count, closing_symbols = ApplicationController.helpers.huobi_orders_close
            if count > 0
              closing_symbols.each do |symbol|
                amount = ApplicationController.helpers.huobi_close_amount(symbol)
                OrdersJob.perform_now symbol, 'sell-market', 0, amount, false
              end
            end
            # job = OrdersCloseJob.perform_now
            # if Time.now.strftime('%M:%S') == "59:59"
            #   Rails.logger.warn "huobi.orders_check ended.."
            #   break
            # end

            # 1 timer limit
            # data = Rails.cache.redis.hgetall("orders")
            # orders = data.find_all {|x| (eval x[1])[:open_time] <= settings.close_timer_up.to_i.seconds.ago}
            # if settings.daily_clear_all_time && !settings.daily_clear_all_time.empty? && Time.now.strftime('%H:%M') == settings.daily_clear_all_time
            #   orders = data
            # end
            #
            # if orders && orders.any?
            #   orders.each do |order|
            #     symbol = order[0]
            #     next if Rails.cache.redis.hget("orders", symbol).nil?
            #     # pnls = ApplicationController.helpers.huobi_pnls(symbol)
            #     begin
            #       ApplicationController.helpers.huobi_orders_log(symbol)
            #       amount = ApplicationController.helpers.huobi_close_amount(symbol)
            #       OrdersJob.perform_now symbol, 'sell-market', 0, amount, false
            #
            #       # ApplicationController.helpers.huobi_orders_log(symbol)
            #       # Rails.cache.redis.hdel("orders", symbol)
            #     rescue Exception => e
            #       Rails.logger.warn "huobi_orders_close 4: #{e.message}"
            #     end
            #   end
            # end
            #
            # # 2 down limit
            # data = Rails.cache.redis.hgetall("orders")
            # orders = data.find_all {|x| ((eval x[1])[:change] <= settings.down_limit.to_f) && (Time.now - (eval x[1])[:open_time].to_time >= settings.open_await_to_close_time.to_i)}
            #
            # if orders && orders.any?
            #   orders.each do |order|
            #     symbol = order[0]
            #     # pnls = ApplicationController.helpers.huobi_pnls(symbol)
            #     begin
            #       ApplicationController.helpers.huobi_orders_log(symbol)
            #       amount = ApplicationController.helpers.huobi_close_amount(symbol)
            #       OrdersJob.perform_now symbol, 'sell-market', 0, amount, false
            #       # ApplicationController.helpers.huobi_orders_log(symbol)
            #       # Rails.cache.redis.hdel("orders", symbol)
            #     rescue Exception => e
            #       Rails.logger.warn "huobi_orders_close 1: #{e.message}"
            #     end
            #   end
            # end
            #
            # # 3 up_limit
            # data = Rails.cache.redis.hgetall("orders")
            # orders = data.find_all {|x| (eval x[1])[:change] > settings.up_limit.to_f}
            #
            # if orders && orders.any?
            #   orders.each do |order|
            #     symbol = order[0]
            #     # pnls = ApplicationController.helpers.huobi_pnls(symbol)
            #     begin
            #       ApplicationController.helpers.huobi_orders_log(symbol)
            #       amount = ApplicationController.helpers.huobi_close_amount(symbol)
            #       OrdersJob.perform_now symbol, 'sell-market', 0, amount, false
            #
            #       # ApplicationController.helpers.huobi_orders_log(symbol)
            #       # Rails.cache.redis.hdel("orders", symbol)
            #     rescue Exception => e
            #       Rails.logger.warn "huobi_orders_close 2: #{e.message}"
            #     end
            #   end
            # end

          rescue Exception => e
            Rails.logger.warn "orders_close clock_4 error: #{e.message}"
          ensure
            Rails.cache.write('running:clock_4', Time.now, expires_in: 1.minute)
          end
          sleep 0.2
        end
      end
    end

    if job == 'huobi.orders_logger'
      # OrderLoggersJob.perform_later(@symbol, @data)
      closed_symbols = Rails.cache.redis.hgetall("orders:closing")
      closed_symbols.each do |cs|
        symbol = cs[0]
        data = eval cs[1]
        ApplicationController.helpers.huobi_orders_log(symbol, data)
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
  every(1.minute, 'huobi.orders_logger')
  # every(5.minutes, 'huobi.alive_check2', :skip_first_run => true, :thread => true)
  #
  # every(1.day, 'midnight.job', :at => '00:00')
end

# cd /var/www/panda_coins/current/lib/job && clockworkd -c clock.rb start --log -d /var/www/panda_coins/current/lib/job
# clockworkd -c clock.rb start --log -d /Users/hielf/workspace/projects/panda_coins/lib/job
# clockworkd -c clock.rb start --log -d /var/www/panda_coins/current/lib/job
# clockworkd -c clock.rb stop
