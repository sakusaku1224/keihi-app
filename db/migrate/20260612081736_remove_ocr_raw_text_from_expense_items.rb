class RemoveOcrRawTextFromExpenseItems < ActiveRecord::Migration[7.2]
  def change
    remove_column :expense_items, :ocr_raw_text, :text
  end
end
