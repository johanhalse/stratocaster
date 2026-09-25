module Stratocaster
  module Attacher
    extend ActiveSupport::Concern

    class_methods do
      def with_image(base_name, &block)
        attr_accessor base_name

        define_method("#{base_name}?") { send("#{base_name}_filename").present? }
        strattachments.merge!(base_name => [])
        Stratocaster.attachments << [name, "#{base_name}_filename"] if name
        block.call(base_name)
        before_save :upload_strattachment_originals
        after_commit :perform_processing_job, on: %i[create update]
        after_destroy_commit :purge_strattachments
      end

      def strattachments
        @strattachments ||= {}
      end

      def add_format(base_name, format_name, **kwargs)
        strattachments[base_name] << [format_name, kwargs]

        define_method "#{base_name}_#{format_name}_filename" do
          base_filename = send("#{base_name}_filename")
          return nil if base_filename.nil?

          strat_md5(base_filename, format_name)
        end

        define_method "#{base_name}_#{format_name}_dimensions" do
          metadata = send("#{base_name}_metadata")[format_name.to_s]
          metadata.presence || begin
            ops = %i[resize_to_fill resize_to_limit resize_and_pad]
            values = kwargs.fetch(ops.find { kwargs.key?(_1) }, {})
            { width: values.first, height: values.last }
          end
        end
      end
    end

    included do
      if Stratocaster.config.uploader == :cloud
        include Stratocaster::CloudUploader
      else
        include Stratocaster::LocalUploader
      end

      def strat_md5(base_filename, format_name = nil)
        Digest::MD5.hexdigest(base_filename + format_name.to_s)
      end

      def strattachments
        self.class.strattachments
      end

      def perform_processing_job
        Stratocaster::ProcessingJob.perform_later(self) if @perform_processing_job
      end

      def strat_base_md5(file:)
        "original_#{Digest::MD5.hexdigest(file.read)}"
      end

      # Deleting inline would hold the destroy transaction, and every row lock it has taken, open across one
      # HTTP round trip per original and variant -- long enough for a concurrent writer to deadlock against
      # it. Collect the keys and let a job do the deleting once the transaction has committed, so a rollback
      # also stops us from orphaning rows that still point at deleted files.
      def purge_strattachments
        files = Hash.new { |hash, filename| hash[filename] = [] }
        strattachments.each do |base_name, variants|
          filename = send("#{base_name}_filename")
          next if filename.blank?

          files[filename].concat(variants.map { |variant_name, _options| strat_md5(filename, variant_name) })
        end

        Stratocaster::PurgeJob.perform_later(files.to_h) if files.any?
      end
    end
  end
end
