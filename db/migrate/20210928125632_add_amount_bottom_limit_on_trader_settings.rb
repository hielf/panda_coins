class AddAmountBottomLimitOnTraderSettings < ActiveRecord::Migration[5.2]
  def change
    add_column :trader_settings, :amount_bottom_limit, :string
  end
end
