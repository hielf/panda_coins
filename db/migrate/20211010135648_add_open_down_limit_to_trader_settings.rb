class AddOpenDownLimitToTraderSettings < ActiveRecord::Migration[5.2]
  def change
    add_column :trader_settings, :open_down_limit, :string
  end
end
