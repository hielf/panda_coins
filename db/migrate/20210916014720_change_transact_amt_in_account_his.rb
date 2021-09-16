class ChangeTransactAmtInAccountHis < ActiveRecord::Migration[5.2]
  def change
    change_column :account_his, :transact_amt, :string
    change_column :trades, :price, :string
    change_column :trades, :filled_amount, :string
    change_column :trades, :filled_fees, :string
  end
end
