class CreateReceipts < ActiveRecord::Migration[7.2]
  def change
    create_table :receipts do |t|
      t.references :user, null: false, foreign_key: true
      t.string :category, null: true
      t.date :occurred_on, null: true
      t.decimal :amount, null: true
      t.string :payee, null: true
      t.string :invoice_registration_number, null: true
      t.references :expense_item, null: true, foreign_key: true

      t.timestamps
    end
  end
end
