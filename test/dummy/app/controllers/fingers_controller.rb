class FingersController < ApplicationController
  def create
    @finger = Finger.new(permitted_params)
    @finger.save!
  end

  private

  def permitted_params
    params.require(:finger).permit %i[hero_image second_image]
  end
end
