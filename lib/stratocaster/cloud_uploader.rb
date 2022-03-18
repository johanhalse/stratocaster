module Stratocaster
  module CloudUploader
    def upload_strattachment_originals
      strattachments.each_key do |file|
        next unless send(file)

        filename = strat_base_md5(file)
        update("#{file}_filename" => filename) if strat_upload(file, filename)
      end
    end

    def strat_upload(file, filename)
      Stratocaster::CloudClient.upload(send(file), filename)
    end
  end
end
