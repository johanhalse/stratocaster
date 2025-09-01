module Stratocaster
  module CloudUploader
    def upload_strattachment_originals
      strattachments.each_key do |f|
        file = send(f)
        next unless file

        @perform_processing_job = true
        filename = strat_base_md5(f)

        next unless strat_upload(file, filename)

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

    private

    def image_size(file)
      image = Vips::Image.new_from_file(file.path, access: :sequential)
      { width: image.width, height: image.height }
    rescue StandardError => _e
      {}
    end
  end
end
