require "stratocaster/version"
require "stratocaster/railtie"
require "stratocaster/attacher"
require "stratocaster/cloud_client"
require "stratocaster/base_uploader"
require "stratocaster/cloud_uploader"
require "stratocaster/local_uploader"
require "stratocaster/processing_job"
require "stratocaster/purge_job"
require "stratocaster/view_helper"
require "image_processing/vips"

module Stratocaster
  cattr_accessor :config
  mattr_accessor :attachments, default: Set.new

  # Filenames are content hashes, so two records holding the same image share every stored file. A file is only
  # safe to delete once no attachment column anywhere still points at it.
  def self.referenced?(filename)
    Rails.application.eager_load! unless Rails.application.config.eager_load

    attachments.any? do |class_name, column|
      class_name.safe_constantize&.unscoped&.exists?(column => filename)
    end
  end
end
