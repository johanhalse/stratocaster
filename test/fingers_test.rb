require "test_helper"

class FingersControllerTest < ActionDispatch::IntegrationTest
  test "it can attach images" do
    jpeg = fixture_file_upload("image.jpg", "image/jpeg")
    finger = Finger.new(hero_image: jpeg)

    assert finger.save!
  end

  test "it can access config" do
    assert_equal :local, Stratocaster.config.uploader
  end

  test "it schedules a job if an attachment has changed" do
    jpeg = fixture_file_upload("image.jpg", "image/jpeg")
    Finger.create!(hero_image: jpeg)

    assert_enqueued_jobs 1
  end

  test "it processes everything as it should" do
    jpeg = fixture_file_upload("image.jpg", "image/jpeg")
    finger = Finger.create!(hero_image: jpeg)

    perform_enqueued_jobs
    
    finger.reload
    assert finger.hero_image_filename.present?
    assert File.exist?("public/images/#{finger.hero_image_filename}")
    
    # Check that format files were created
    finger.strattachments[:hero_image].each do |variant_name, _operations|
      variant_filename = Digest::MD5.hexdigest(finger.hero_image_filename + variant_name.to_s)
      assert File.exist?("public/images/#{variant_filename}"), "Format #{variant_name} file should exist"
    end
    
    # Check metadata was updated with variant dimensions
    assert finger.hero_image_metadata["first"].present?
    assert finger.hero_image_metadata["second"].present?
  end

  test "it schedules no jobs unless attachment has changed" do
    Finger.create!
    assert_enqueued_jobs 0
  end

  test "hero_image_metadata gets properly set when a file is uploaded" do
    jpeg = fixture_file_upload("image.jpg", "image/jpeg")
    finger = Finger.create!(hero_image: jpeg)
    
    assert finger.hero_image_metadata.present?
    assert finger.hero_image_metadata.is_a?(Hash)
    assert finger.hero_image_metadata["width"].present?
    assert finger.hero_image_metadata["height"].present?
    assert_equal 1848, finger.hero_image_metadata["width"]
    assert_equal 1220, finger.hero_image_metadata["height"]
  end
end
