class TraderSettingsController < ApplicationController

  def update
    id = params[:id]
    verify_code = params[:trader_setting][:verify_code]
    @trader_setting = TraderSetting.find_by(id: id)
    if verify_code == ENV["verify_code"]
      begin
        @trader_setting.update!(trade_order_params)
        msg = "修改成功"
      rescue Exception => e
        msg = "修改失败,#{e.to_s}"
      end
      # flash.now[:notice] = 'Message sent!'
      # redirect_to edit_trader_setting_path(@trader_setting)
      respond_to do |format|
        format.html { redirect_to request.referer, alert: '修改成功' }
      end
    else
      respond_to do |format|
        format.html { redirect_to request.referer, alert: '验证码错误' }
      end
    end
  end

  def edit
    id = params[:id]
    @trader_setting = TraderSetting.find_by(id: id)
  end

  private
  def trade_order_params
    params["trader_setting"].permit(:days_after_symbol_listing, :max_opened_orders,
      :divide_shares, :up_floor_limit, :up_up_limit, :down_limit, :up_limit, :pnl_interval,
      :close_timer_up, :tickers_check_interval, :daily_balance_up_limit, :daily_start_time,
      :daily_clear_all_time, :buy_accept_start_time, :buy_accept_end_time,
      :open_await_to_close_time, :amount_bottom_limit, :open_down_limit, :balance_proportion,
      :max_down_limit)
  end
end
