require 'rails_helper'

RSpec.describe SettingsController, type: :controller do
  context 'regular user' do
    let(:user) { create(:basic_user) }
    let(:full_user) { create(:full_user) }

    before do
      warden.set_user user
    end

    describe 'POST settings#verify_current_user with verify code' do
      include_context 'prepare verify code' do
        let(:key) { user.email }
      end

      it 'should return error if verify code invalid' do
        post :verify_current_user, type: 'email', verify_code: '111111'
        expect(response).to have_http_status(422)
        expect(JSON.parse(response.body)['errors']).to include('Verify code invalid')
      end

      it 'should set user authenticate if verify code correct' do
        post :verify_current_user, type: 'email', verify_code: @code
        expect(response).to be_success
        token = Rails.cache.fetch("identify_token:#{user.id}")
        expect(token).not_to eq(nil)
        expect(cookies[:identify_token]).to eq(token)
      end
    end

    describe 'PATCH settings#update_primary' do
      include_context 'prepare verify code'

      it 'should return error if user not authenticate' do
        patch :update_primary, type: 'email', verify_code: @code, email: key
        expect(response).to have_http_status(422)
        expect(JSON.parse(response.body)['errors']).to include('User not identified')
      end

      it 'should return error if verify_code invalid' do
        allow_any_instance_of(User).to receive(:identified?).and_return(true)
        patch :update_primary, type: 'email', verify_code: '111111', email: key
        expect(response).to have_http_status(422)
        expect(JSON.parse(response.body)['errors']).to include('Verify code invalid')
      end

      it 'should return user if verify code correct' do
        allow_any_instance_of(User).to receive(:identified?).and_return(true)
        patch :update_primary, type: 'email', verify_code: @code, email: key
        expect(response.body).to eq(UserSerializer.new(user).to_json)
      end
    end

    describe 'PATCH settings#update_password with new password' do
      it 'should return error if password is invalid' do
        patch :update_password, password: '111111', new_password: '222222'
        expect(JSON.parse(response.body)['errors']).to include('Password invalid')
      end

      it 'should return error if new password is invalid' do
        patch :update_password, password: user.password, new_password: '12345'
        expect(JSON.parse(response.body)['errors']).to include('Password is too short (minimum is 6 characters)')
      end

      it 'should update password and return user' do
        patch :update_password, password: user.password, new_password: '123456'
        expect(JSON.parse(response.body)['email']).to eq(user.email)
        expect(user.authenticate('123456')).to eq(user)
      end
    end

    describe 'DELETE settings#unbind_auth' do
      before do
        warden.set_user full_user
      end

      it 'should delete authorization' do
        delete :unbind_auth, provider: 'wechat'
        expect(response).to be_success
        expect(JSON.parse(response.body)['email']).to eq(full_user.email)
      end

      it 'should return error if Authorization not found' do
        delete :unbind_auth, provider: 'wechat'
        delete :unbind_auth, provider: 'wechat'
        expect(JSON.parse(response.body)['errors']).to include('Authorization not found')
      end
    end

    describe 'POST settings#identified' do
      it 'should return false' do
        post :identified
        expect(JSON.parse(response.body)['identified']).to eq(false)
      end

      it 'should return false' do
        token = user.generate_identify_token
        cookies[:identify_token] = token
        post :identified
        expect(JSON.parse(response.body)['identified']).to eq(true)
      end
    end
  end

  context 'old user or sns user' do
    let(:old_user) { create(:old_user) }

    describe 'PATCH settings#update_primary' do
      include_context 'prepare verify code'

      it 'should return user if user is_old and verify_code correct' do
        warden.set_user old_user
        patch :update_primary, type: 'email', verify_code: @code, email: key
        expect(JSON.parse(response.body)['email']).to eq(key)
      end

      it 'should return user if sns user' do
        warden.set_user create(:sns_user)
        patch :update_primary, type: 'email', email: key, verify_code: @code, password: 'new_password'
        expect(JSON.parse(response.body)['email']).to eq(key)
      end
    end

    describe 'POST settings#identified' do
      it 'should return false' do
        warden.set_user old_user
        post :identified
        expect(JSON.parse(response.body)['identified']).to eq(true)
      end
    end
  end
end