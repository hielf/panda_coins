class AddOpenDownLimitToEventLogs < ActiveRecord::Migration[5.2]
  def change
    add_column :event_logs, :change_open, :float
    add_column :event_logs, :first_price, :float
  end
end
