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

  test "it deletes local files when record is destroyed" do
    jpeg = fixture_file_upload("image.jpg", "image/jpeg")
    finger = Finger.create!(hero_image: jpeg)
    
    perform_enqueued_jobs
    finger.reload
    
    original_filename = finger.hero_image_filename
    variant1_filename = finger.strat_md5(original_filename, :first)
    variant2_filename = finger.strat_md5(original_filename, :second)
    
    # Verify files exist before destroy
    assert File.exist?("public/images/#{original_filename}")
    assert File.exist?("public/images/#{variant1_filename}")
    assert File.exist?("public/images/#{variant2_filename}")
    
    # Destroy the record
    finger.destroy!
    
    # Verify files are deleted after destroy
    assert_not File.exist?("public/images/#{original_filename}")
    assert_not File.exist?("public/images/#{variant1_filename}")
    assert_not File.exist?("public/images/#{variant2_filename}")
  end

  test "it handles missing local files gracefully during destroy" do
    jpeg = fixture_file_upload("image.jpg", "image/jpeg")
    finger = Finger.create!(hero_image: jpeg)
    
    # Delete files manually to simulate missing files
    FileUtils.rm_rf("public/images")
    
    # Should not raise an error when destroying
    assert_nothing_raised do
      finger.destroy!
    end
  end

  test "it cleans up multiple image attachments on destroy" do
    jpeg1 = fixture_file_upload("image.jpg", "image/jpeg")
    jpeg2 = fixture_file_upload("image.jpg", "image/jpeg")
    
    finger = Finger.create!(hero_image: jpeg1, second_image: jpeg2)
    
    perform_enqueued_jobs
    finger.reload
    
    hero_original = finger.hero_image_filename
    hero_variant1 = finger.strat_md5(hero_original, :first)
    hero_variant2 = finger.strat_md5(hero_original, :second)
    
    second_original = finger.second_image_filename
    second_variant = finger.strat_md5(second_original, :another)
    
    # Verify all files exist
    assert File.exist?("public/images/#{hero_original}")
    assert File.exist?("public/images/#{hero_variant1}")
    assert File.exist?("public/images/#{hero_variant2}")
    assert File.exist?("public/images/#{second_original}")
    assert File.exist?("public/images/#{second_variant}")
    
    # Destroy the record
    finger.destroy!
    
    # Verify all files are deleted
    assert_not File.exist?("public/images/#{hero_original}")
    assert_not File.exist?("public/images/#{hero_variant1}")
    assert_not File.exist?("public/images/#{hero_variant2}")
    assert_not File.exist?("public/images/#{second_original}")
    assert_not File.exist?("public/images/#{second_variant}")
  end
end
