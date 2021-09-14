class AccountLoggerJob < ApplicationJob
  queue_as :low_priority

  def perform(*args)
    @symbol = args[0]

    @account_id, @status = ApplicationController.helpers.huobi_balances
    @count_match = ApplicationController.helpers.huobi_histroy_matchresults(@symbol)
    @count_his = ApplicationController.helpers.huobi_accounts_history
  end
end
