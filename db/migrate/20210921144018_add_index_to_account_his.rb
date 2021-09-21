class AddIndexToAccountHis < ActiveRecord::Migration[5.2]
  def change
    add_index :account_his, [:account_id, :record_id], unique: true
  end
end
