class TraderBalance < ApplicationRecord

  def self.init(account_id, currency, balance_type)
    tb = find_or_initialize_by(account_id: account_id, currency: currency, balance_type: balance_type)
    if tb.balance.nil?
      tb.balance = 0
      tb.save!
    end
    return tb
  end
end
