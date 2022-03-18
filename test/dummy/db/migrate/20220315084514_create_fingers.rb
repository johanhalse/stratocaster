class CreateFingers < ActiveRecord::Migration[7.0]
  def change
    create_table :fingers do |t|
      t.string :hero_image_filename
      t.string :second_image_filename

      t.timestamps
    end
  end
end
