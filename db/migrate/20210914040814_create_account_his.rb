class CreateAccountHis < ActiveRecord::Migration[5.2]
  def change
    create_table :account_his do |t|
      t.integer :account_id
      t.string :currency
      t.string :record_id
      t.float :transact_amt
      t.string :transact_type
      t.float :avail_balance
      t.float :acct_balance
      t.datetime :transact_time

      t.timestamps
    end
    add_index :account_his, :account_id
    add_index :account_his, :transact_time
  end
end
