class AddHeroImageMetadataToFingers < ActiveRecord::Migration[8.0]
  def change
    add_column :fingers, :hero_image_metadata, :json, default: {}
  end
end
