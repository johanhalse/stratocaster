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

    private

    def image_size(file)
      dimensions = `$(which convert) -auto-orient "#{file.path}" -format %wx%h info:`.split("x")
      return {} if dimensions.blank?

      { width: dimensions.first.to_i, height: dimensions.last.to_i }
    rescue StandardError => _e
      {}
    end
  end
end
