class ApplicationController < ActionController::Base
	# Prevent CSRF attacks by raising an exception.
	# For APIs, you may want to use :null_session instead.
	protect_from_forgery with: :exception
	before_filter :allow_cross_domain_access, :set_controller_and_action_names
	after_filter :allow_cross_domain_access

	BACKEND_URL = "http://localhost:9113"

	def allow_cross_domain_access
		headers['Access-Control-Allow-Origin'] = '*'
		headers['Access-Control-Allow-Methods'] = 'POST, GET, OPTIONS'
		headers['Access-Control-Request-Method'] = '*'
		headers['Access-Control-Allow-Headers'] = '*'
	end
	
    def set_controller_and_action_names
      @current_controller = controller_name
      @current_action     = action_name
    end

    def general_error
		raise ActionController::RoutingError.new('REST Error')
	end

	def intro
		
	end
end
