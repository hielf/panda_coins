FactoryBot.define do
  factory :trader_setting do
    account_id { 1 }
    days_after_symbol_listing { "MyString" }
    max_opened_orders { "MyString" }
    first_share_divide { "MyString" }
  end
end
