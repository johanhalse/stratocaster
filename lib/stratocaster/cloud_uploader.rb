module Stratocaster
  module CloudUploader
    include BaseUploader

    def upload_strattachment_originals
      strattachments.each_key do |f|
        file = send(f)
        next unless file

        @perform_processing_job = true
        resized_file = resize_original_image(file)
        filename = strat_base_md5(file: resized_file)
        upload_success = strat_upload(resized_file, filename)

        # Clean up temp file if it was created
        resized_file.close! if resized_file.respond_to?(:close!) && resized_file != file

        next unless upload_success

        assign_attributes(
          "#{f}_filename" => filename,
          "#{f}_metadata" => image_size(file)
        )
      end
    end

    def strat_upload(file, filename)
      Stratocaster::CloudClient.upload(file, filename)
    end

    def strat_delete(filename)
      Stratocaster::CloudClient.delete(filename)
    end
  end
end
