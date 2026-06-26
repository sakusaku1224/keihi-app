class ExpenseItemsController < ApplicationController
  before_action :set_expense_report
  before_action :set_expense_item, only: %i[edit update destroy]
  before_action :require_draft

  def new
    @expense_item = @expense_report.expense_items.build
    @unlinked_receipts = current_user.receipts.unlinked
  end

  # 明細の作成
  def create
    @expense_item = @expense_report.expense_items.build(expense_item_params)
    if @expense_item.save
      if params[:receipt_id].present?
        receipt = current_user.receipts.find(params[:receipt_id])
        receipt.update(expense_item_id: @expense_item.id)
      end
      redirect_to @expense_report, notice: "明細を追加しました"
    else
      render turbo_stream: turbo_stream.replace(
        "new_item_form",
        partial: "expense_items/form",
        locals: { expense_item: @expense_item }
      ), status: :unprocessable_entity
    end
  end

  def edit
    # before_actionで取得済み
  end

  # 更新
  def update
    if @expense_item.update(expense_item_params)
      redirect_to @expense_report, notice: "明細を更新しました"
    else
      render turbo_stream: turbo_stream.replace(
        "edit_item_form_#{@expense_item.id}",
        partial: "expense_items/edit_form",
        locals: { expense_item: @expense_item }
      ), status: :unprocessable_entity
    end
  end

  # 明細削除
  def destroy
    @expense_item.destroy
    redirect_to @expense_report, notice: "明細を削除しました"
  end

  private
  # 親の申請ID取得
  def set_expense_report
    @expense_report = current_user.expense_reports.find(params[:expense_report_id])
  end

  # 明細を取得
  def set_expense_item
    @expense_item = @expense_report.expense_items.find(params[:id])
  end

  # 下書きのみ編集可能
  def require_draft
    unless @expense_report.draft?
      redirect_to @expense_report, alert: "この申請は編集できません"
    end
  end

  def expense_item_params
    params.require(:expense_item).permit(
      :item_name,
      :category,
      :occurred_on,
      :amount,
      :tax_rate,
      :payee,
      :invoice_registration_number,
      :receipt_image
      )
  end
end
