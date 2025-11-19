module Stratocaster
  module BaseUploader
    def upload_strattachment_originals
      raise NotImplementedError
    end

    def strat_upload(file, filename)
      raise NotImplementedError
    end

    def strat_delete(filename)
      raise NotImplementedError
    end

    private

    def image_size(file)
      image = Vips::Image.new_from_file(file.path, access: :sequential)
      { width: image.width, height: image.height }
    rescue StandardError => _e
      {}
    end

    def resize_original_image(file)
      pipeline = ImageProcessing::Vips
        .source(file.path)
        .convert("jpg")
        .saver(quality: 85)
        .resize_to_limit(2500, 2500)

      pipeline.call
    rescue StandardError => e
      Rails.logger.error("Failed to resize image: #{e.message}")
      file
    end
  end
end
