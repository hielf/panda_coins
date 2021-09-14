class TraderBalance < ApplicationRecord
# trade: 交易余额，frozen: 冻结余额, loan: 待还借贷本金, interest: 待还借贷利息, lock: 锁仓, bank: 储蓄
  def self.init(account_id, currency, balance_type)
    tb = find_or_initialize_by(account_id: account_id, currency: currency, balance_type: balance_type)
    if tb.balance.nil?
      tb.balance = 0
      tb.save!
    end
    return tb
  end
end
