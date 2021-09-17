class Trade < ApplicationRecord

  def self.today
    where("created_time >= ?", Time.now.beginning_of_day)
  end

  # def self.today_pnl
  #   where("created_time >= ?", Date.today).sum(:realized_pnl)
  # end
  def self.to_csv
    attributes = %w{symbol fee_currency price created_time filled_amount filled_fees trade_type}

    require 'csv'
    CSV.generate(headers: true) do |csv|
      csv << attributes

      all.each do |contact|
        csv << attributes.map{ |attr| contact.send(attr) }
      end
    end
  end

end
