module Stratocaster
  class CloudClient
    def self.stratoclient
      Aws::S3::Client.new(**Stratocaster.config.cloud_config.except(:bucket))
    end

    def self.upload(file, filename)
      stratoclient.put_object(
        acl: "public-read",
        body: file,
        bucket: Stratocaster.config.cloud_config[:bucket],
        key: filename
      ).etag.present?
    end

    def self.download(filename)
      FileUtils.mkdir_p("tmp")
      local_path = "tmp/#{filename}"

      stratoclient.get_object(
        bucket: Stratocaster.config.cloud_config[:bucket],
        key: filename,
        response_target: local_path
      )

      File.open(local_path)
    end
  end
end
