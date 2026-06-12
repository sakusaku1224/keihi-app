class CreateExpenseReports < ActiveRecord::Migration[7.2]
  def change
    create_table :expense_reports do |t|
      t.references :user, null: false, foreign_key: true
      t.string :title
      t.text :notes
      t.integer :status
      t.decimal :total_amount
      t.datetime :submitted_at

      t.timestamps
    end
  end
end
