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
  end

  def balances
    huobi_pro = HuobiPro.new(ENV["huobi_access_key"],ENV["huobi_secret_key"],ENV["huobi_accounts"])
    @balances = huobi_pro.balances["data"]["list"].find_all {|x| x["balance"].to_f != 0 }
  end

end
