module Stratocaster
  class ProcessingJob < ActiveJob::Base
    queue_as :stratocaster_jobs

    self.priority = 2

    def perform(obj)
      obj.strattachments.each_key do |base_name|
        filename = obj.send("#{base_name}_filename")
        next if filename.blank?

        original_image = download_image(filename)
        obj.strattachments[base_name].each do |variant|
          variant_name = variant.first
          operations = variant.last

          processed_image = ImageProcessing::Vips.source(original_image).apply(operations).call
          set_dimension_metadata(obj, base_name, variant_name, processed_image)
          upload_image(processed_image, strat_md5(filename, variant_name))
        end

        obj.save!
        destroy_downloaded_image(filename)
      end
    end

    private

    def set_dimension_metadata(obj, base_name, variant_name, processed_image)
      image = Vips::Image.new_from_file(processed_image.path, access: :sequential)
      variant_metadata = { width: image.width, height: image.height }
      m = obj.send("#{base_name}_metadata")
      obj.send("#{base_name}_metadata=", m.merge(variant_name.to_s => variant_metadata))
    end

    def destroy_downloaded_image(filename)
      return unless Stratocaster.config.uploader == :cloud

      file_path = "tmp/#{filename}"
      File.delete(file_path) if File.exist?(file_path)
    end

    def download_image(filename)
      if Stratocaster.config.uploader == :cloud
        Stratocaster::CloudClient.download(filename)
      else
        File.open("public/images/#{filename}")
      end
    end

    def upload_image(processed_image, filename)
      if Stratocaster.config.uploader == :cloud
        Stratocaster::CloudClient.upload(processed_image, filename)
      else
        FileUtils.cp(processed_image, "public/images/#{filename}")
      end
    end

    def strat_md5(filename, format_name)
      Digest::MD5.hexdigest(filename + format_name.to_s)
    end
  end
end
