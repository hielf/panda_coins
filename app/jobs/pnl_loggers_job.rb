class PnlLoggersJob < ApplicationJob
  queue_as :low_priority

  # after_perform :around_check

  def perform(*args)
    @symbol = args[0]
    @pnls = args[1]

    ApplicationController.helpers.huobi_pnls_log(@symbol, @pnls)
  end

  private
  def around_check

  end

end
