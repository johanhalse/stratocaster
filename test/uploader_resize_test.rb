require "test_helper"

class UploaderResizeTest < ActionDispatch::IntegrationTest
  test "LocalUploader resizes images before uploading" do
    # Create a large image that will need resizing
    large_image = Vips::Image.black(3000, 2000)
    temp_file = Tempfile.new(['large', '.jpg'])

    begin
      large_image.write_to_file(temp_file.path)

      # Upload using ActionDispatch file upload
      upload = Rack::Test::UploadedFile.new(temp_file.path, "image/jpeg")
      finger = Finger.create!(hero_image: upload)

      # Check that the uploaded file has been resized
      uploaded_path = "public/images/#{finger.hero_image_filename}"
      assert File.exist?(uploaded_path), "Uploaded file should exist"

      uploaded_image = Vips::Image.new_from_file(uploaded_path)
      assert uploaded_image.width <= 2500, "Image width should be <= 2500"
      assert uploaded_image.height <= 2500, "Image height should be <= 2500"
      assert_equal 2500, uploaded_image.width
      assert_equal 1667, uploaded_image.height
    ensure
      temp_file.close!
    end
  end

  test "LocalUploader converts images to JPEG" do
    # Create a PNG image
    png_image = Vips::Image.black(500, 500)
    temp_file = Tempfile.new(['test', '.png'])

    begin
      png_image.write_to_file(temp_file.path)

      upload = Rack::Test::UploadedFile.new(temp_file.path, "image/png")
      finger = Finger.create!(hero_image: upload)

      # Check that the uploaded file is JPEG
      uploaded_path = "public/images/#{finger.hero_image_filename}"
      uploaded_image = Vips::Image.new_from_file(uploaded_path)
      assert_equal "jpegload", uploaded_image.get("vips-loader")
    ensure
      temp_file.close!
    end
  end

  test "LocalUploader maintains small images without upscaling" do
    jpeg = fixture_file_upload("image.jpg", "image/jpeg")
    finger = Finger.create!(hero_image: jpeg)

    # Original is 1848x1220, should stay the same
    uploaded_path = "public/images/#{finger.hero_image_filename}"
    uploaded_image = Vips::Image.new_from_file(uploaded_path)

    assert_equal 1848, uploaded_image.width
    assert_equal 1220, uploaded_image.height
  end
end
