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

  def pnls
    pnls = ProfitLoss.all.group("symbol").select("symbol").count
  end


  private

  def trade_order_params
    params.permit(:order_type, :amount, :price, :rand_code)
  end
end
