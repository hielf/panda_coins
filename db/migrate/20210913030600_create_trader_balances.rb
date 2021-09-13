class CreateTraderBalances < ActiveRecord::Migration[5.2]
  def change
    create_table :trader_balances do |t|
      t.integer :account_id
      t.string :currency
      t.string :balance_type, :default => "trade"
      t.float :balance, :default => 0
      t.integer :seq_num

      t.timestamps
    end

    add_index :trader_balances, :account_id
  end
end
