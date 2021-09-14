class Trade < ApplicationRecord

  def self.today
    where("created_time >= ?", Time.now.beginning_of_day)
  end

  # def self.today_pnl
  #   where("created_time >= ?", Date.today).sum(:realized_pnl)
  # end

end
