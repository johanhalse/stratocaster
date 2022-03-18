class Finger < ApplicationRecord
  include Stratocaster::Attacher

  with_image :hero_image do |image|
    add_format image, :first, resize_to_fill: [1024, 768]
    add_format image, :second, resize_to_fill: [800, 600]
  end

  with_image :second_image do |image|
    add_format image, :another, convert: "webp"
  end
end
