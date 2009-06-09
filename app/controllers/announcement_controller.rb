class AnnouncementController < ApplicationController
  skip_before_filter :ensure_we_have_fiscal_data
  
  def hide
    session[:hide_announcement] = true
    render :update do |page|
      page.visual_effect :fade, 'announcement'
    end
  end

  # Needed to hide the announcement in a secure page.
  #this_controller_only_responds_to_https
end
