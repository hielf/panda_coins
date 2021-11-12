class AddBalanceProportionToTraderSettings < ActiveRecord::Migration[5.2]
  def change
    add_column :trader_settings, :balance_proportion, :string
  end
end
