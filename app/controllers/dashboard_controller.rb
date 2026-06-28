class DashboardController < ApplicationController
  def index
    # 未回収金額 未申請BOX合計 + 下書き合計
    @uncollected_amount = current_user.receipts.unlinked.sum(:amount).to_i +
                          current_user.expense_reports.draft.sum(:total_amount).to_i

    # 未申請BOX件数
    @unlinked_count = current_user.receipts.unlinked.count

    # 締切までの日数
    deadline = Date.new(Date.current.year, Date.current.month, 22)
    if deadline < Date.current
      deadline = deadline.next_month
    end
    @deadline_days = (deadline - Date.current).to_i

    # 下書き件数
    @draft_count = current_user.expense_reports.draft.count

    # 提出済み件数
    @submitted_count = current_user.expense_reports.submitted.count

    # 承認済み件数
    @approved_count = current_user.expense_reports.approved.count

    # 最近の申請(5件)
    @recent_reports = current_user.expense_reports.order(created_at: :desc).limit(5)

    # 過去6ヶ月集計
    beginning = Date.current.beginning_of_month
    ending = Date.current.end_of_month
    start_date = 5.months.ago.beginning_of_month
    monthly_totals = current_user.expense_reports
                    .where(status: [ :submitted, :approved ])
                    .where(created_at: start_date..ending)
                    .group("TO_CHAR(created_at, 'YYYY-MM')")
                    .sum(:total_amount)

    @monthly_labels = (5.downto(0)).map { |i| i.months.ago.beginning_of_month }

    @monthly_values = @monthly_labels.map do |month|
      key = month.strftime("%Y-%m")
      (monthly_totals[key] || 0).to_i
    end

    @monthly_labels = @monthly_labels.map { |m| m.strftime("%-m月") }

    # バナー
    if @uncollected_amount == 0
      @reminder_level = nil
    elsif @deadline_days == 0
      @reminder_level = :critical
    elsif @deadline_days <= 3
      @reminder_level = :urgent
    elsif @deadline_days <= 7
      @reminder_level = :warning
    end
  end
end
