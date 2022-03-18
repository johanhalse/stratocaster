module Stratocaster
  module ViewHelper
    def strat_image(filename, **kwargs)
      image_tag strat_url(filename), **kwargs
    end

    def strat_url(url)
      if Stratocaster.config.uploader == :cloud
        "https://#{Stratocaster.config.cloud_config[:bucket]}.fra1.cdn.digitaloceanspaces.com/#{url}"
      else
        "/images/#{url}"
      end
    end
  end
end
