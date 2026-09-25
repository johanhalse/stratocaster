module Stratocaster
  class PurgeJob < ActiveJob::Base
    queue_as :stratocaster_jobs

    self.priority = 3

    def perform(files)
      files.each do |original, variants|
        next if Stratocaster.referenced?(original)

        [original, *variants].each { |filename| purge(filename) }
      end
    end

    private

    def purge(filename)
      if Stratocaster.config.uploader == :cloud
        Stratocaster::CloudClient.delete(filename)
      else
        FileUtils.rm_f("public/images/#{filename}")
      end
    end
  end
end
