class AddMaxDownLimitToTraderSettings < ActiveRecord::Migration[5.2]
  def change
    add_column :trader_settings, :max_down_limit, :string
  end
end
