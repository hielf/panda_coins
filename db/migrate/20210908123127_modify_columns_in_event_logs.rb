class ModifyColumnsInEventLogs < ActiveRecord::Migration[5.2]
  def change
    remove_column :event_logs, :content
    remove_column :event_logs, :log_type
    remove_column :event_logs, :order_type

    add_column :event_logs, :open_price, :float
    add_column :event_logs, :current_price, :float
    add_column :event_logs, :change, :float
    add_column :event_logs, :open_time, :datetime
    add_column :event_logs, :current_time, :datetime
  end
end
