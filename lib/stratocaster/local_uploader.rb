module Stratocaster
  module LocalUploader
    def upload_strattachment_originals
      FileUtils.mkdir_p("public/images")

      strattachments.each_key do |f|
        file = send(f)
        next unless file

        @perform_processing_job = true
        filename = strat_base_md5(f)
        strat_upload(file, filename)
        update({ "#{f}_filename" => filename, "#{f}_metadata" => image_size(file) })
      end
    end

    def strat_upload(file, filename)
      FileUtils.cp(file, "public/images/#{filename}")
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
