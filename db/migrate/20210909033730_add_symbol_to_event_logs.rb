class AddSymbolToEventLogs < ActiveRecord::Migration[5.2]
  def change
    add_column :event_logs, :symbol, :string
  end
end
