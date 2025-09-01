require "test_helper"

class ProcessingJobTest < ActiveJob::TestCase
  include ActionDispatch::TestProcess::FixtureFile
  
  test "processes all images" do
    jpeg = fixture_file_upload("image.jpg", "image/jpeg")
    finger = Finger.create!(hero_image: jpeg)
    
    # Ensure the file was uploaded and metadata set
    assert finger.hero_image_filename.present?
    assert finger.hero_image_metadata.present?
    
    # Run the enqueued jobs (which includes the processing job)
    perform_enqueued_jobs
    
    # Reload to get updated metadata
    finger.reload
    
    # Check that metadata was set for variants
    assert finger.hero_image_metadata.present?
    assert finger.hero_image_metadata.is_a?(Hash)
    
    # Check original dimensions are preserved
    assert_equal 1848, finger.hero_image_metadata["width"]
    assert_equal 1220, finger.hero_image_metadata["height"]
    
    # Check variant metadata exists (the processing job adds these)
    assert finger.hero_image_metadata["first"].present?, "First variant metadata should be present"
    assert finger.hero_image_metadata["second"].present?, "Second variant metadata should be present"
    
    # Check variant files were created
    finger.strattachments[:hero_image].each do |variant_name, _operations|
      variant_filename = Digest::MD5.hexdigest(finger.hero_image_filename + variant_name.to_s)
      assert File.exist?("public/images/#{variant_filename}"), "Variant #{variant_name} file should exist"
    end
  end
end
