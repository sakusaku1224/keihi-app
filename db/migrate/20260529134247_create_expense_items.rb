class CreateExpenseItems < ActiveRecord::Migration[7.2]
  def change
    create_table :expense_items do |t|
      t.references :expense_report, null: false, foreign_key: true
      t.string :item_name
      t.string :category
      t.date :occurred_on
      t.decimal :amount
      t.integer :tax_rate
      t.string :payee
      t.string :invoice_registration_number
      t.text :ocr_raw_text

      t.timestamps
    end
  end
end
