class TraderSetting < ApplicationRecord

  def self.current_settings
    find_by(account_id: ENV["huobi_accounts"])
  end
end
