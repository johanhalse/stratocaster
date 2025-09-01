require "stratocaster/version"
require "stratocaster/railtie"
require "stratocaster/attacher"
require "stratocaster/cloud_client"
require "stratocaster/cloud_uploader"
require "stratocaster/local_uploader"
require "stratocaster/processing_job"
require "stratocaster/view_helper"
require "image_processing/vips"

module Stratocaster
  cattr_accessor :config
end
