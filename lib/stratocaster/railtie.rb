module Stratocaster
  class Railtie < ::Rails::Railtie
    config.stratocaster = ActiveSupport::OrderedOptions.new

    initializer "stratocaster.configure_rails_initialization" do
      Stratocaster.config = config.stratocaster

      ActiveSupport.on_load :action_view do
        include Stratocaster::ViewHelper
      end
    end
  end
end
