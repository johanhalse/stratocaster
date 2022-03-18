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
    Finger.create!(hero_image: jpeg)

    perform_enqueued_jobs
  end

  test "it schedules no jobs unless attachment has changed" do
    Finger.create!
    assert_enqueued_jobs 0
  end
end
