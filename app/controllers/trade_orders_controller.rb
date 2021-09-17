class TradeOrdersController < ApplicationController

  def pre_orders
    # p "#{request.protocol}#{request.host_with_port}#{request.fullpath}"
    p "#{request.protocol}#{request.host_with_port}/api/trade_orders/pre_orders"
    data = Faraday.get "#{request.protocol}#{request.host_with_port}/api/trade_orders/pre_orders"
    @pre_orders = (JSON.parse data.body)["data"]

    case params[:sort]
    when "symbol"
      @pre_orders = @pre_orders.sort_by { |key| key[0] }.to_h
    when "open_price"
      @pre_orders = @pre_orders.sort_by { |key| (eval key[1])[:open_price] }.to_h
    when "current_price"
      @pre_orders = @pre_orders.sort_by { |key| (eval key[1])[:current_price] }.to_h
    when "change"
      @pre_orders = @pre_orders.sort_by { |key| (eval key[1])[:change] }.to_h
    when "open_time"
      @pre_orders = @pre_orders.sort_by { |key| (eval key[1])[:open_time] }.to_h
    when "current_time"
      @pre_orders = @pre_orders.sort_by { |key| (eval key[1])[:current_time] }.to_h
    end

  end

  def event_logs
    data = Faraday.get "#{request.protocol}#{request.host_with_port}/api/trade_orders/event_logs"
    @event_logs = (JSON.parse data.body)["data"]
    @today_change_sum = EventLog.today.sum(:change)
  end

  def trader_balances
    data = Rails.cache.redis.hgetall("balances")
    account_id = ENV["huobi_accounts"]
    data.each do |d|
      h = eval d[1]
      tb = TraderBalance.init(account_id, h[:currency], h[:type])
      tb.attributes = { balance: h[:balance], seq_num: h[:"seq-num"] }
      if tb.save!
        @status = true
      end
    end

    @trader_balances_all = TraderBalance.all
    @trader_balances = TraderBalance.where("balance > ?", 0.0001)
  end

  def histroy_matchresults
    @histroy_matchresults = Trade.today.order(:created_time)
    @histroy_matchresults_all = Trade.order(:created_time)
    respond_to do |format|
       format.html
       format.csv { send_data @histroy_matchresults.to_csv }
     end
  end

  def accounts_history
    @accounts_history = AccountHi.today.order(:transact_time)
  end

  def production_log
    filename =
    case Rails.env
    when "production"
      "#{Rails.root}/log/production.log"
    when "development"
      "#{Rails.root}/log/development.log"
    end
    # @last_100_lines = `tail -n 100 #{filename}`

    @lines = IO.readlines(filename)[-100..-1]
    # IO.readlines(filename)[-100..-1].each do |l|
    #   @lines << l
    # end
  end

end
