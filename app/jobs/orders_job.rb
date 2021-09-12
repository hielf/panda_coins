class OrdersJob < ApplicationJob
  queue_as :first

  after_perform :orders_log

  rescue_from(ActiveRecord::RecordNotFound) do |exception|
     Rails.logger.warn "#{exception.message.to_s}"
  end

  def perform(*args)
    @symbol = args[0]
    @type = args[1]
    @price = args[2]
    @count = args[3]

    huobi_pro = HuobiPro.new(ENV["huobi_access_key"],ENV["huobi_secret_key"],ENV["huobi_accounts"])
    begin
      order = huobi_pro.new_order(@symbol,@type,@price,@count)
    rescue Exception => e
      Rails.logger.warn "OrdersJob error: #{e.message}"
    end

    # huobi_pro.history_matchresults(symbol)
    # huobi_pro.new_order(symbol,"sell-market",0,5)

    # SmsJob.perform_later ENV["admin_phone"], ENV["superme_user"] + " " + ENV["backtrader_version"], "无法连接"
  end

  private
  def orders_log
    job1 = PositionsJob.set(wait: 2.seconds).perform_later(@contract, @version)
  end

end
