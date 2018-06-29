class ResourceAuditController < ApplicationController

	set_access_control "view_repository" => [:index, :submit, :audit]

	def index
	end

	def submit
		redirect_to :action => :audit, :ref => params['resource']['ref']
	end

	def audit
		begin
			@results = JSONModel::HTTP.get_json(params[:ref] + '/audit')
			if @results.nil?
				flash[:error] = "#{params[:ref]} is not a Resource URI"
				redirect_to :action => :index
			end
		rescue Exception => e
			flash[:error] = e.message
			redirect_to :action => :index
		end
	end

end
