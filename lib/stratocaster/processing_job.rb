module Stratocaster
  class ProcessingJob < ActiveJob::Base
    queue_as :stratocaster_jobs

    self.priority = 2

    def perform(obj)
      obj.strattachments.each_key do |base_name|
        filename = obj.send("#{base_name}_filename")
        next if filename.blank?

        obj.strattachments[base_name].each do |variant|
          variant_name = variant.first
          operations = variant.last

          processed_image = ImageProcessing::MiniMagick.source(download_image(filename)).apply(operations).call
          upload_image(processed_image, strat_md5(filename, variant_name))
        end
      end
    end

    private

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
