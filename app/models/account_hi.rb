class AccountHi < ApplicationRecord

  def self.today
    where("transact_time >= ?", Time.now.beginning_of_day)
  end
end
