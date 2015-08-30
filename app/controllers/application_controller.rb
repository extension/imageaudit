# === COPYRIGHT:
#  Copyright (c) North Carolina State University
#  Developed with funding for the National eXtension Initiative.
# === LICENSE:
#
#  see LICENSE file

class ApplicationController < ActionController::Base
  TRUE_VALUES = [true, 1, '1', 't', 'T', 'true', 'TRUE', 'yes','YES','y','Y','on']
  FALSE_VALUES = [false, 0, '0', 'f', 'F', 'false', 'FALSE','no','NO','n','N','off']


  protect_from_forgery
  include AuthLib
  before_filter :check_for_rebuild, :signin_required

  def check_for_rebuild
    if(rebuild = Rebuild.latest)
      if(rebuild.in_progress?)
        # probably should return 307 instead of 302
        return redirect_to(root_path)
      end
    end
    true
  end

  def append_info_to_payload(payload)
    super
    payload[:ip] = request.remote_ip
    payload[:auth_id] = session[:contributor_id] if session[:contributor_id]
  end

end
