class ChangeTimeInProfitLosses < ActiveRecord::Migration[5.2]
  def change
    add_column :profit_losses, :current_time, :datetime
  end
end
