class ChangeColumnTypeInAccountHis < ActiveRecord::Migration[5.2]
  def change
    change_column :account_his, :avail_balance, :string
    change_column :account_his, :acct_balance, :string
  end
end
