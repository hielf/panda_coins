class AccountLoggerJob < ApplicationJob
  queue_as :default

  def perform(*args)
    @symbol = args[0]

    5.times do
      frozen_count, status = ApplicationController.helpers.huobi_balances
      break if (status && frozen_count == 0)
      sleep 0.5
    end

    count_match = ApplicationController.helpers.huobi_histroy_matchresults(@symbol)
    count_his = ApplicationController.helpers.huobi_accounts_history
  end
end
