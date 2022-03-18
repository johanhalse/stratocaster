module Stratocaster
  module LocalUploader
    def upload_strattachment_originals
      FileUtils.mkdir_p("public/images")

      strattachments.each_key do |f|
        next unless send(f)

        filename = strat_base_md5(f)
        strat_upload(f, filename)
        update("#{f}_filename" => filename)
      end
    end

    def strat_upload(file, filename)
      FileUtils.cp(send(file), "public/images/#{filename}")
    end
  end
end
