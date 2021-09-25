class TraderSettingsController < ApplicationController

  def account_settings
    account_id = params[:account_id]

    @trader_setting = TraderSetting.find_by(account_id: account_id)
  end

end
