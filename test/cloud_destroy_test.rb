require "test_helper"

# Define AWS S3 error classes for testing if not already defined
module Aws
  module S3
    module Errors
      class NoSuchKey < StandardError; end unless defined?(NoSuchKey)
    end
  end
end unless defined?(Aws::S3::Errors)

class CloudDestroyTest < ActionDispatch::IntegrationTest
  setup do
    @original_uploader = Stratocaster.config.uploader
    @original_cloud_config = Stratocaster.config.cloud_config
    @delete_calls = []
    @upload_calls = []
    
    # Switch to cloud mode for these tests
    Stratocaster.config.uploader = :cloud
    Stratocaster.config.cloud_config = {
      region: "us-east-1",
      access_key_id: "test",
      secret_access_key: "test",
      bucket: "test-bucket"
    }
    
    # Stub CloudClient methods
    Stratocaster::CloudClient.singleton_class.class_eval do
      alias_method :original_upload, :upload if method_defined?(:upload)
      alias_method :original_delete, :delete if method_defined?(:delete)
      alias_method :original_download, :download if method_defined?(:download)
    end
    
    test_instance = self
    Stratocaster::CloudClient.define_singleton_method(:upload) do |file, filename|
      test_instance.instance_variable_get(:@upload_calls) << filename
      true
    end
    
    Stratocaster::CloudClient.define_singleton_method(:delete) do |filename|
      test_instance.instance_variable_get(:@delete_calls) << filename
      true
    end
    
    Stratocaster::CloudClient.define_singleton_method(:download) do |filename|
      # Return a mock file for download operations during processing
      File.open(Rails.root.join("test/fixtures/files/image.jpg"))
    end
    
    # Reload Finger class to pick up cloud uploader
    Object.send(:remove_const, :Finger) if defined?(Finger)
    load Rails.root.join("app/models/finger.rb")
  end
  
  teardown do
    # Restore CloudClient methods
    Stratocaster::CloudClient.singleton_class.class_eval do
      remove_method :upload if method_defined?(:upload)
      remove_method :delete if method_defined?(:delete)
      remove_method :download if method_defined?(:download)
      alias_method :upload, :original_upload if method_defined?(:original_upload)
      alias_method :delete, :original_delete if method_defined?(:original_delete)
      alias_method :download, :original_download if method_defined?(:original_download)
    end
    
    # Restore original config
    Stratocaster.config.uploader = @original_uploader
    Stratocaster.config.cloud_config = @original_cloud_config
    
    # Reload Finger class to restore original uploader
    Object.send(:remove_const, :Finger) if defined?(Finger)
    load Rails.root.join("app/models/finger.rb")
  end
  
  test "it deletes cloud files when record is destroyed" do
    jpeg = fixture_file_upload("image.jpg", "image/jpeg")
    finger = Finger.create!(hero_image: jpeg)
    
    perform_enqueued_jobs
    
    original_filename = finger.hero_image_filename
    variant1_filename = finger.strat_md5(original_filename, :first)
    variant2_filename = finger.strat_md5(original_filename, :second)
    
    # Clear upload calls from setup
    @delete_calls.clear
    
    # Destroy the record - should trigger cleanup
    finger.destroy!
    
    # Verify delete was called for original and variants
    assert_includes @delete_calls, original_filename
    assert_includes @delete_calls, variant1_filename
    assert_includes @delete_calls, variant2_filename
    assert_equal 3, @delete_calls.length
  end
  
  test "it handles missing cloud files gracefully" do
    jpeg = fixture_file_upload("image.jpg", "image/jpeg")
    finger = Finger.create!(hero_image: jpeg)
    
    # Stub delete to return false (simulating missing files)
    Stratocaster::CloudClient.define_singleton_method(:delete) do |filename|
      false
    end
    
    # Should not raise an error when destroying
    assert_nothing_raised do
      finger.destroy!
    end
  end
  
  test "it cleans up multiple image attachments" do
    jpeg1 = fixture_file_upload("image.jpg", "image/jpeg")
    jpeg2 = fixture_file_upload("image.jpg", "image/jpeg")
    
    finger = Finger.create!(hero_image: jpeg1, second_image: jpeg2)
    
    perform_enqueued_jobs
    
    hero_original = finger.hero_image_filename
    hero_variant1 = finger.strat_md5(hero_original, :first)
    hero_variant2 = finger.strat_md5(hero_original, :second)
    
    second_original = finger.second_image_filename
    second_variant = finger.strat_md5(second_original, :another)
    
    # Clear upload calls
    @delete_calls.clear
    
    # Destroy the record
    finger.destroy!
    
    # Verify all files were deleted
    assert_includes @delete_calls, hero_original
    assert_includes @delete_calls, hero_variant1
    assert_includes @delete_calls, hero_variant2
    assert_includes @delete_calls, second_original
    assert_includes @delete_calls, second_variant
    assert_equal 5, @delete_calls.length
  end
end