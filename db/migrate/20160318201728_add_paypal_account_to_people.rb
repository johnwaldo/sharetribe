class AddPaypalAccountToPeople < ActiveRecord::Migration
  def change
    add_column :people, :paypal_account, :string
  end
end
