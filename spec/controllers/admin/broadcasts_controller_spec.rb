require 'rails_helper'

RSpec.describe Admin::BroadcastsController, type: :controller do
  let(:user)  { create(:basic_user) }
  let(:admin) { create(:user, :admin) }

  describe 'without login or not admin' do
    context 'not login' do
      it_behaves_like 'return 404 without admin' do
        let(:subject) { get :index }
      end
    end

    context 'not admin' do
      before { warden.set_user(user) }
      it_behaves_like 'return 404 without admin' do
        let(:subject) { get :index }
      end
    end
  end

  describe 'CRUD' do
    before { warden.set_user(admin) }

    describe 'Get #index' do
      it 'return 200' do
        get :index
        expect(response).to have_http_status(200)
      end
    end

    describe 'Get #new' do
      it 'return 200' do
        get :new
        expect(response).to have_http_status(200)
      end
    end

    describe 'Post #create' do
      context 'valid params' do
        it 'create a broadcast' do
          post :create, broadcast: attributes_for(:broadcast)
          expect(response).to redirect_to(admin_broadcasts_path)
        end
      end

      context 'invalid params' do
        it 'render new' do
          post :create, broadcast: attributes_for(:broadcast, title: nil)
          expect(response).to have_http_status(422)
          expect(JSON.parse(response.body)['errors']).to include('Title不能为空字符')
        end
      end
    end
  end
end
