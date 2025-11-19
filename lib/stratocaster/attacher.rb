module Stratocaster
  module Attacher
    extend ActiveSupport::Concern

    class_methods do
      def with_image(base_name, &block)
        attr_accessor base_name

        define_method("#{base_name}?") { send("#{base_name}_filename").present? }
        strattachments.merge!(base_name => [])
        block.call(base_name)
        before_save :upload_strattachment_originals
        after_commit :perform_processing_job
        after_destroy :cleanup_strattachments
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

      def cleanup_strattachments
        strattachments.each_key do |base_name|
          filename = send("#{base_name}_filename")
          next unless filename.present?

          # Delete original
          strat_delete(filename)
          
          # Delete all variants for this attachment
          strattachments[base_name].each do |variant_name, _options|
            variant_filename = strat_md5(filename, variant_name)
            strat_delete(variant_filename)
          end
        end
      end
    end
  end
end
