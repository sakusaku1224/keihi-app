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

    # 月の開始日・終了日を取得する
    beginning = Date.current.beginning_of_month
    ending = Date.current.end_of_month

    # 今月の申請完了ぶん合計（提出・承認された金額の合計）
    @monthly_applied = current_user.expense_reports
                                   .where(status: [ :submitted, :approved ])
                                   .where(created_at: beginning..ending)
                                   .sum(:total_amount).to_i

    # 今月の未申請ぶん合計（下書き・未申請BOXの金額の合計）
    draft_amount = current_user.expense_reports.draft
                              .where(created_at: beginning..ending)
                              .sum(:total_amount).to_i

    unlinked_amount = current_user.receipts.unlinked
                                  .where(occurred_on: beginning..ending)
                                  .sum(:amount).to_i

    @monthly_unapplied = draft_amount + unlinked_amount

    # 今月の立替申請見込み金額
    @monthly_total = @monthly_applied + @monthly_unapplied


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
  end
end
