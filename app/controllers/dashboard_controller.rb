class DashboardController < ApplicationController
  def index
    # 下書き件数
    @draft_count = current_user.expense_reports.draft.count

    # 提出済み件数
    @submitted_count = current_user.expense_reports.submitted.count

    #承認済み件数
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

    # カテゴリ別合計金額
    @category_totals = ExpenseItem.joins(:expense_report)
                                  .where(expense_reports: { user_id: current_user.id, created_at: beginning..ending })
                                  .group(:category)
                                  .sum(:amount)
  end
end
