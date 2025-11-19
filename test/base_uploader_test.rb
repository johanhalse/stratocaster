require "test_helper"

class BaseUploaderTest < ActionDispatch::IntegrationTest
  # Create a test class that includes BaseUploader
  class TestModel
    include Stratocaster::BaseUploader
  end

  setup do
    @test_model = TestModel.new
  end

  test "upload_strattachment_originals raises NotImplementedError" do
    assert_raises(NotImplementedError) do
      @test_model.upload_strattachment_originals
    end
  end

  test "strat_upload raises NotImplementedError" do
    assert_raises(NotImplementedError) do
      @test_model.strat_upload(nil, "test.jpg")
    end
  end

  test "strat_delete raises NotImplementedError" do
    assert_raises(NotImplementedError) do
      @test_model.strat_delete("test.jpg")
    end
  end

  test "image_size returns dimensions for valid image" do
    jpeg = fixture_file_upload("image.jpg", "image/jpeg")
    dimensions = @test_model.send(:image_size, jpeg)

    assert dimensions.is_a?(Hash)
    assert_equal 1848, dimensions[:width]
    assert_equal 1220, dimensions[:height]
  end

  test "image_size returns empty hash for invalid file" do
    invalid_file = Tempfile.new(['invalid', '.txt'])
    invalid_file.write("not an image")
    invalid_file.rewind

    dimensions = @test_model.send(:image_size, invalid_file)

    assert_equal({}, dimensions)
    invalid_file.close!
  end

  test "resize_original_image converts to JPEG" do
    jpeg = fixture_file_upload("image.jpg", "image/jpeg")
    result = @test_model.send(:resize_original_image, jpeg)

    begin
      assert result.respond_to?(:path), "Result should have a path method"

      # Verify it's a valid JPEG
      image = Vips::Image.new_from_file(result.path)
      assert_equal "jpegload", image.get("vips-loader")
    ensure
      result.close! if result.respond_to?(:close!)
    end
  end

  test "resize_original_image does not upscale small images" do
    jpeg = fixture_file_upload("image.jpg", "image/jpeg")
    original_width = 1848
    original_height = 1220

    result = @test_model.send(:resize_original_image, jpeg)

    begin
      image = Vips::Image.new_from_file(result.path)

      # Should maintain original dimensions since image is smaller than 2500x2500
      assert_equal original_width, image.width
      assert_equal original_height, image.height
    ensure
      result.close! if result.respond_to?(:close!)
    end
  end

  test "resize_original_image resizes large images to fit within 2500x2500" do
    # Create a large test image (3000x2000)
    large_image = Vips::Image.black(3000, 2000)
    temp_large = Tempfile.new(['large', '.jpg'])

    begin
      large_image.write_to_file(temp_large.path)
      temp_large.rewind

      result = @test_model.send(:resize_original_image, temp_large)

      begin
        resized = Vips::Image.new_from_file(result.path)

        # Should be resized to fit within 2500x2500, preserving aspect ratio
        # 3000x2000 scaled by 2500/3000 = 0.833... = 2500x1667
        assert resized.width <= 2500
        assert resized.height <= 2500
        assert_equal 2500, resized.width
        assert_equal 1667, resized.height # 2000 * (2500/3000) = 1666.67 rounded up
      ensure
        result.close! if result.respond_to?(:close!)
      end
    ensure
      temp_large.close!
    end
  end

  test "resize_original_image preserves aspect ratio for tall images" do
    # Create a tall test image (2000x3000)
    tall_image = Vips::Image.black(2000, 3000)
    temp_tall = Tempfile.new(['tall', '.jpg'])

    begin
      tall_image.write_to_file(temp_tall.path)
      temp_tall.rewind

      result = @test_model.send(:resize_original_image, temp_tall)

      begin
        resized = Vips::Image.new_from_file(result.path)

        # Should be resized to fit within 2500x2500, preserving aspect ratio
        # 2000x3000 scaled by 2500/3000 = 0.833... = 1667x2500
        assert resized.width <= 2500
        assert resized.height <= 2500
        assert_equal 1667, resized.width # 2000 * (2500/3000) = 1666.67 rounded up
        assert_equal 2500, resized.height
      ensure
        result.close! if result.respond_to?(:close!)
      end
    ensure
      temp_tall.close!
    end
  end

  test "resize_original_image handles errors gracefully" do
    # Create an invalid file
    invalid_file = Tempfile.new(['invalid', '.jpg'])
    invalid_file.write("not a real image")
    invalid_file.rewind

    # Should return the original file on error, not raise
    result = @test_model.send(:resize_original_image, invalid_file)
    assert_equal invalid_file, result

    invalid_file.close!
  end
end
