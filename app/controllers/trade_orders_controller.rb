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
    TraderBalance.where(balance_type: "frozen").map {|t| t.update(balance: 0)}
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

    @history_balances = Set.new
    (1..5).reverse_each do |n|
      date = (Date.today - n).strftime("%Y-%m-%d")
      balance = Rails.cache.redis.hget("balance_his", date).nil? ? nil : (eval Rails.cache.redis.hget("balance_his", date))[:balance]
      @history_balances << {"date": date, "balance": balance}
    end
  end

  def histroy_matchresults
    @histroy_matchresults = Trade.today.order(:created_time)
    @histroy_matchresults_all = Trade.order(:created_time)
    respond_to do |format|
       format.html
       format.csv { send_data @histroy_matchresults_all.to_csv }
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
    n = 200
    count = %x{wc -l #{filename}}.split.first.to_i
    if count < n
      n = count
    end
    n = -1 * n
    @lines = IO.readlines(filename)[n..-1]
  end

  def close_by_symbol
    # symbol = params[:symbol]
    tb = TraderBalance.find_by(id: params[:id])
    symbol = tb.currency + "usdt"
    amount, shares_amount = ApplicationController.helpers.huobi_close_amount(symbol, 1)
    OrdersJob.perform_now symbol, 'sell-market', 0, amount, true

    respond_to do |format|
      format.html { redirect_to request.referer, alert: '卖出成功' }
    end
  end

end
