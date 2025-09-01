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
        assign_attributes(
          "#{f}_filename" => filename,
          "#{f}_metadata" => image_size(file)
        )
      end
    end

    def strat_upload(file, filename)
      FileUtils.cp(file, "public/images/#{filename}")
    end

    def strat_delete(filename)
      file_path = "public/images/#{filename}"
      FileUtils.rm_f(file_path) if File.exist?(file_path)
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
