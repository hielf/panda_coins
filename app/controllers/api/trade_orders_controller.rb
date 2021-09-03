class Api::TradeOrdersController < Api::ApplicationController
  skip_before_action :authenticate_user!

  def pre_orders
    begin
      data = Rails.cache.redis.hgetall("orders")
      result = [0, "success", data.as_json]
    rescue Exception => e
      result = [1, e.value.to_s]
    end
    render_json(result)
  end

  def tickers
    begin
      data = Rails.cache.redis.hgetall("tickers")
      result = [0, "success", data.as_json]
    rescue Exception => e
      result = [1, e.value.to_s]
    end
    render_json(result)
  end

  def account_values
    begin
      data = helpers.ib_account_values
      result = [0, "success", data]
    rescue Exception => e
      result = [1, e.value.to_s]
    end
    render_json(result)
  end

  def contract_data
    contract = params[:contract]
    result = [1, 'failed']
    if contract
      data = helpers.market_data(contract)
      result = [0, 'success'] if data
    end
    render_json(result)
  end

  def trades_data
    contract = ENV['contract']
    if request.format.csv?
      duration = params[:duration]
      trades_to_csv(contract, duration)
      file = Rails.root.to_s + "/tmp/csv/trades_#{contract}.csv"
      send_data(File.read(file), type: "application/csv", disposition:  "attachment", filename: "trades_#{contract}.csv")
    else
      result = [1, 'failed']
      data = ib_trades(contract)
      if !data.empty?
        data.sort_by { |h| -h[:time] }.reverse.each do |d|
          trade = Trade.find_or_initialize_by(exec_id: d[:exec_id])
          trade.update(perm_id: d[:perm_id], action: d[:action], symbol: d[:symbol],
            last_trade_date_or_contract_month: d[:last_trade_date_or_contract_month],
            currency: d[:currency], shares: d[:shares], price: d[:price], time: Time.at(d[:time]),
            commission: d[:commission], realized_pnl: d[:realized_pnl])
        end

        result = [0, 'success', data]
      end
      render_json(result)
    end
  end

  private

  def trade_order_params
    params.permit(:order_type, :amount, :price, :rand_code)
  end
end
