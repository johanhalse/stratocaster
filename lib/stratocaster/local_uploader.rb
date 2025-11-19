module Stratocaster
  module LocalUploader
    include BaseUploader

    def upload_strattachment_originals
      FileUtils.mkdir_p("public/images")

      strattachments.each_key do |f|
        file = send(f)
        next unless file

        @perform_processing_job = true
        resized_file = resize_original_image(file)
        filename = strat_base_md5(file: resized_file)
        strat_upload(resized_file, filename)

        # Clean up temp file if it was created
        resized_file.close! if resized_file.respond_to?(:close!) && resized_file != file

        assign_attributes(
          "#{f}_filename" => filename,
          "#{f}_metadata" => image_size(file)
        )
      end
    end

    def strat_upload(file, filename)
      FileUtils.cp(file.path, "public/images/#{filename}")
    end

    def strat_delete(filename)
      file_path = "public/images/#{filename}"
      FileUtils.rm_f(file_path) if File.exist?(file_path)
    end
  end
end
