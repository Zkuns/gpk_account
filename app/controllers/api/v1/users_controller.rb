class Api::V1::UsersController < Api::BaseController
  before_action -> { doorkeeper_authorize! :public, :write, :admin }, only: [:show, :logout]
  before_action -> { doorkeeper_authorize! :admin, :write }, only: [:update, :update_preference]
  before_action -> { doorkeeper_authorize! :admin }, only: :extra_info
  before_action :verify_signature!, only: :third_part_login

  def show
    render json: current_user, serializer: UserBasicSerializer
  end

  def extra_info
    white_list = %w(email mobile)
    querys = white_list & params[:query].collect(&:to_s)
    querys << 'is_old'
    render json: current_user.attributes.slice(*querys)
  end

  def update
    user = current_user
    user.update!(user_params)
    render json: user
  end

  def logout
    current_user.devices.find_by(device_id: params[:device_id])&.destroy
    doorkeeper_token.revoke
    render json: { message: 'success' }
  end

  def third_part_login
    auth = auth_hash
    user = Authorization.find_by(uid: auth['uid'], provider: auth['provider']).try(:user) ||
      User.create_with_omniauth(auth)
    if user
      token = Doorkeeper::AccessToken.find_or_create_for(@client, user.id, @client.scopes, 7200, true)
      render json: token
    else
      render json: { error: 'Login Failed!' }, status: 404
    end
  end

  def update_preference
    current_user.preference&.update(preference_params)
    render json: { message: 'success' }
  end

  def count
    from, to = params.values_at(:from, :to)
    if from.blank? || to.blank?
      render json: { error: 'Missing parameters' }, status: 400
      return
    end

    count = User.where(created_at: from..to).count
    render json: { count: count }

  rescue ActiveRecord::StatementInvalid
    render json: { error: 'Invalid parameter value(s)' }, status: 400
  end

  private

  def preference_params
    params.permit(:receive_message, email: [:enabled, subscriptions: [:event, :report]])
  end

  def auth_hash
    case params[:provider]
    when 'wechat'
      wechat_auth params[:code]
    when 'weibo'
      weibo_auth params
    else
      raise ParameterValueNotAllowed, params[:provider]
    end
  end

  def wechat_auth(code)
    wechat = OmniAuth::Strategies::WeChat.new(
      {},
      client_id: ENV['MOBILE_WECHAT_ID'],
      client_secret: ENV['MOBILE_WECHAT_SECRET']
    )
    token = wechat.client.get_token(wechat.token_params.merge(code: code,
                                                              grant_type: 'authorization_code',
                                                              parse: :json))
    wechat.access_token = token
    wechat.auth_hash
  end

  def weibo_auth(hash)
    weibo = OmniAuth::Strategies::Weibo.new(
      {},
      client_id: ENV['MOBILE_WEIBO_ID'],
      client_secret: ENV['MOBILE_WEIBO_SECRET']
    )
    hash = hash.each_with_object({}) do |(k, v), h|
      h[k.underscore] = v
      h
    end
    token = OAuth2::AccessToken.from_hash(weibo.client, hash)
    weibo.access_token = token
    weibo.auth_hash
  end

  def user_params
    params.permit(:avatar, :realname, :nickname, :city, :company, :title, :bio)
  end
end
