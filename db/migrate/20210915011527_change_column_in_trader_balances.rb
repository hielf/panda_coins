class ChangeColumnInTraderBalances < ActiveRecord::Migration[5.2]
  def change
    change_column :trader_balances, :balance, :string
  end
end
