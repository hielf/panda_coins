class AddOpenAwaitToCloseTimeInTraderSettings < ActiveRecord::Migration[5.2]
  def change
    add_column :trader_settings, :open_await_to_close_time, :string
  end
end
