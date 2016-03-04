class AddManufacturePriceToListings < ActiveRecord::Migration
  def change
    add_column :listings, :manufacture_price_cents, :integer, after: :price_cents
  end
end
