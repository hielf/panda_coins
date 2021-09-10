class EventLog < ApplicationRecord
  # belongs_to :eventable

  def self.today
    where("open_time >= ?", Time.now.beginning_of_day)
  end
end
