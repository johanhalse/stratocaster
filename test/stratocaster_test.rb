require "test_helper"

class StratocasterTest < ActiveSupport::TestCase
  test "it has a version number" do
    assert Stratocaster::VERSION
  end

  test "it can enumerate strattachments" do
    assert_equal(
      {
        hero_image: [[:first, { resize_to_fill: [1024, 768] }], [:second, { resize_to_fill: [800, 600] }]],
        second_image: [[:another, { convert: "webp" }]]
      },
      Finger.new.strattachments
    )
  end

  test "it can get base urls" do
    assert_equal(
      "abcdef123",
      Finger.new(hero_image_filename: "abcdef123").hero_image_filename
    )
  end

  test "it can get format urls" do
    assert_equal(
      "c1228ec8707845d90cbb5db76953ebd5",
      Finger.new(hero_image_filename: "abcdef123").hero_image_first_filename
    )
  end
end
