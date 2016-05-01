class AddMakeOfferEnabledToListingShapes < ActiveRecord::Migration
  def change
    add_column :listing_shapes, :make_offer_enabled, :boolean, default: false
  end
end
