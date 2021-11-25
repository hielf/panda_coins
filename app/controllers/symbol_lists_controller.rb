class SymbolListsController < ApplicationController

  def index
    verify_code = params[:verify_code]
    @symbol_lists = SymbolList.all
  end

  def edit
    id = params[:id]
    @symbol = SymbolList.find_by(id: id)
  end

  def disable_symbol
    symbol = SymbolList.find_by(id: params[:id])
    begin
      symbol.disable
    rescue Exception => e
      Rails.logger.warn "disable_symbol error: #{e.message}"
    end
    respond_to do |format|
      format.html { redirect_to request.referer, alert: "#{symbol.symbol}已禁用" }
    end
  end

  def enable_symbol
    symbol = SymbolList.find_by(id: params[:id])
    begin
      symbol.enable
    rescue Exception => e
      Rails.logger.warn "disable_symbol error: #{e.message}"
    end
    respond_to do |format|
      format.html { redirect_to request.referer, alert: "#{symbol.symbol}已启用" }
    end
  end

  private
  # def trade_order_params
  #   params["trader_setting"].permit(:days_after_symbol_listing, :max_opened_orders,
  #     :divide_shares, :up_floor_limit, :up_up_limit, :down_limit, :up_limit, :pnl_interval,
  #     :close_timer_up, :tickers_check_interval, :daily_balance_up_limit, :daily_start_time,
  #     :daily_clear_all_time, :buy_accept_start_time, :buy_accept_end_time,
  #     :open_await_to_close_time, :amount_bottom_limit, :open_down_limit, :balance_proportion)
  # end
end
