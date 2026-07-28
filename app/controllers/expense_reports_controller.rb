class ExpenseReportsController < ApplicationController
  before_action :set_expense_report, only: %i[ show edit update destroy self_check submit]
  # 下書きの場合のみ更新・削除可能
  before_action :require_draft, only: %i[ edit update destroy ]

  # 一覧画面
  def index
    @expense_reports = current_user.expense_reports

    # ステータスフィルタ
    @expense_reports = @expense_reports.where(status: params[:status]) if params[:status].present?

    # 月フィルタ
    if params[:start_date].present? && params[:end_date].present?
      @expense_reports = @expense_reports.where(created_at: params[:start_date].to_date.beginning_of_day..params[:end_date].to_date.end_of_day)
    end

    # 並び順・ページネーション
    @expense_reports = @expense_reports.order(created_at: :desc).page(params[:page]).per(8)
  end

  def new
    @expense_report = current_user.expense_reports.build
  end

  # 新規作成
  def create
    @expense_report = current_user.expense_reports.build(expense_report_params)
    @expense_report.status = :draft
    if @expense_report.save
      redirect_to @expense_report, notice: "申請を作成しました"
    else
      render :new, status: :unprocessable_entity
    end
  end

  # 詳細画面(タイトル・明細一覧)
  def show
    # 明細を追加で取得、発生日順
    @expense_items = @expense_report.expense_items.includes(:receipt_image_attachment, :receipt, receipt: { receipt_image_attachment: :blob })
                                                  .order(occurred_on: :desc)
    @unlinked_receipts = current_user.receipts.unlinked
  end

  def edit
    # @expense_reportはbefore_actionで取得済み
  end

  # 更新
  def update
    if @expense_report.update(expense_report_params)
      redirect_to @expense_report, notice: "申請を更新しました"
    else
      render :edit, status: :unprocessable_entity
    end
  end

  # 削除
  def destroy
    @expense_report.destroy
    redirect_to expense_reports_path, notice: "申請を削除しました"
  end

  # 提出処理
  def submit
    if @expense_report.draft?
      # 提出時刻を現在時刻に設定
      @expense_report.update!(status: :submitted, submitted_at: Time.current)
      redirect_to root_path, notice: "申請を提出しました"
    else
      redirect_to @expense_report, alert: "下書き以外は提出できません"
    end
  end

  # セルフチェック
  def self_check
    # 領収書未添付
    @missing_items = @expense_report.expense_items.reject do |item|
      item.receipt_image.attached? ||
      item.receipt&.receipt_image&.attached?
    end
    # 過去の申請と重複
    @cross_report_duplicates = @expense_report.expense_items.select do |item|
      ExpenseItem.joins(:expense_report)
                 .where(expense_reports: { user_id: current_user.id })
                 # 自分自身との比較を防ぐ
                 .where.not(expense_report_id: @expense_report.id)
                 .where(occurred_on: item.occurred_on, amount: item.amount,
                        payee: item.payee, category: item.category)
                 .exists?
    end
    # 今回の申請内の重複
    @within_report_duplicates = @expense_report.expense_items.select do |item|
      ExpenseItem.where(expense_report_id: @expense_report.id)
                 .where.not(id: item.id)
                 .where(occurred_on: item.occurred_on, amount: item.amount,
                        payee: item.payee, category: item.category)
                 .exists?
    end
    render :self_check
  end

  private
  # 申請ID取得
  def set_expense_report
    @expense_report = current_user.expense_reports.find(params[:id])
  end

  # 下書きのみ編集可能
  def require_draft
    unless @expense_report.draft?
      redirect_to @expense_report, alert: "この申請は編集できません"
    end
  end

  def expense_report_params
    params.require(:expense_report).permit(:title, :notes)
  end
end
