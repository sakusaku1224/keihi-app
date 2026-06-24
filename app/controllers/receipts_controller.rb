class ReceiptsController < ApplicationController
  before_action :set_receipt, only: %i[destroy]
  before_action :require_unlinked, only: %i[destroy]
  def index
    # 未申請のものに絞る
    @receipts = current_user.receipts.unlinked
  end

  def new
    @receipt = current_user.receipts.build
  end

  def create
    @receipt = current_user.receipts.build(receipt_params)

    # 画像ファイルを取り出す
    image = params[:receipt][:receipt_image]

    # 画像があればOCR実行
    if image.present?
      data = ReceiptScanner.new(image).call
      if data.present?
        @receipt.assign_attributes(
          amount: data["amount"],
          occurred_on: data["occurred_on"],
          payee: data["payee"],
          category: data["category"],
          invoice_registration_number: data["invoice_registration_number"]
        )
      end
    end

    if @receipt.save
      redirect_to receipts_path, notice: "領収書を保存しました"
    else
      flash.now[:alert] = "保存に失敗しました"
      render :new, status: :unprocessable_entity
    end
  end

  def destroy
    @receipt.destroy
    redirect_to receipts_path, notice: "領収書を削除しました"
  end

  private
  # 領収書のID取得
  def set_receipt
    @receipt = current_user.receipts.find(params[:id])
  end

  # 使用していないもののみ削除可能
  def require_unlinked
    if @receipt.expense_item_id.present?
      redirect_to receipts_path, alert: "削除できません"
    end
  end

  def receipt_params
    params.require(:receipt).permit(
      :category,
      :occurred_on,
      :amount,
      :payee,
      :invoice_registration_number,
      :receipt_image,
      )
  end
end

