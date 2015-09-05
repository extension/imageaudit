# === COPYRIGHT:
#  Copyright (c) North Carolina State University
#  Developed with funding for the National eXtension Initiative.
# === LICENSE:
#
#  see LICENSE file
class AuditLogsController < ApplicationController

  def index
    @pagination_params = {}
    @filter_strings = []
    @filtered = false

    if(params[:contributor_id] and @contributor = Contributor.find_by_id(params[:contributor_id]))
      @pagination_params[:contributor_id] = params[:contributor_id]
      @filter_strings << "Contributor: #{@contributor.fullname}"
      @filtered = true
      audit_log_scope = @contributor.audit_logs
    else
      audit_log_scope = AuditLog.scoped({})
    end

    @audit_logs = audit_log_scope.order("created_at desc").page(params[:page]).per(25)

  end

  def show
    @audit_log = AuditLog.find(params[:id])
  end



end
