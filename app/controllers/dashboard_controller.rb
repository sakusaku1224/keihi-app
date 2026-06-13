class DashboardController < ApplicationController
  def index
    # 下書き件数
    @draft_count = current_user.expense_reports.draft.count

    # 提出済み件数
    @submitted_count = current_user.expense_reports.submitted.count

    # 承認済み件数
    @approved_count = current_user.expense_reports.approved.count

    # 最近の申請(5件)
    @recent_reports = current_user.expense_reports.order(created_at: :desc).limit(5)

    # 月の開始日・終了日を取得する
    beginning = Date.current.beginning_of_month
    ending = Date.current.end_of_month

    # 月の合計金額
    @monthly_count = current_user.expense_reports
                                 .where(created_at: beginning..ending)
                                 .sum(:total_amount)


    # 過去6ヶ月集計
    start_date = 5.months.ago.beginning_of_month
    monthly_totals = current_user.expense_reports
                    .where(created_at: start_date..ending)
                    .group("TO_CHAR(created_at, 'YYYY-MM')")
                    .sum(:total_amount)

    @monthly_labels = (5.downto(0)).map { |i| i.months.ago.beginning_of_month }

    @monthly_values = @monthly_labels.map do |month|
      key = month.strftime("%Y-%m")
      (monthly_totals[key] || 0).to_i
    end

    @monthly_labels = @monthly_labels.map { |m| m.strftime("%-m月") }

    # カテゴリ別合計金額
    @category_totals = ExpenseItem.joins(:expense_report)
                                  .where(expense_reports: { user_id: current_user.id, created_at: beginning..ending })
                                  .group(:category)
                                  .sum(:amount)
  end
end
