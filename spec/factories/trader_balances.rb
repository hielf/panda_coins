FactoryBot.define do
  factory :trader_balance do
    account_id { 1 }
    currency { "MyString" }
    type { "" }
    balance { 1.5 }
    seq_num { 1 }
  end
end
