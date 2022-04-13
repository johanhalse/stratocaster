module Stratocaster
  module Attacher
    extend ActiveSupport::Concern

    class_methods do
      def with_image(base_name, &block)
        attr_accessor base_name

        define_method("#{base_name}?") { send("#{base_name}_filename").present? }
        strattachments.merge!(base_name => [])
        block.call(base_name)
        before_commit :upload_strattachment_originals
        after_save :schedule_processing_job
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
          base_filename = send("#{base_name}_filename")
          return {} if base_filename.nil?

          variant = strattachments[base_name].find { |v| v.first == format_name }
          operations = variant.last
          { width: operations[:resize_to_fill].first, height: operations[:resize_to_fill].last }
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

      def schedule_processing_job
        return unless strattachments.keys.any? { |a| send("saved_change_to_#{a}_filename?") }

        Stratocaster::ProcessingJob.perform_later(self)
      end

      def strat_base_md5(base_name)
        "original_#{Digest::MD5.hexdigest(File.read(send(base_name).tempfile))}"
      end
    end
  end
end
