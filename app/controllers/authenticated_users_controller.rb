class AuthenticatedUsersController < ApplicationController

  before do
    authenticate
  end

  before do
    if ['POST', 'PUT', 'DELETE'].include? request.request_method
      halt 403 if limited_user?
    end
  end

  def admin_user?
    current_user.admin?
  end

  def normal_user?
    current_user.normal?
  end

  def limited_user?
    current_user.limited?
  end

  protected
    
  def authenticate
    username = request.user_agent
    access_token = if request.env['HTTP_AUTHORIZATION']
                     request.env['HTTP_AUTHORIZATION'].split('Bearer ')[-1]
                   else
                     nil
                   end
    @current_user = Tendrl::User.authenticate_access_token(
      username,
      access_token
    )
    halt 401 if @current_user.nil?
  end

  def current_user
    @current_user || authenticate
  end

  def monitoring
    config = recurse(etcd.get('/_tendrl/config/performance_monitoring/data'))
    @monitoring = Tendrl::MonitoringApi.new(config['data'])
  rescue Etcd::KeyNotFound
    logger.info 'Monitoring API not enabled.'
    nil
  end

end
