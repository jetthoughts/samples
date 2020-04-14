# frozen_string_literal: true

require 'rails_helper'

RSpec.describe 'Api::V1::Posts', type: :request do
  include RequestHelpers
  include AuthHelper

  describe 'api/v1/posts#index' do
    describe 'returned posts' do
      before do
        FactoryBot.create_list(:post, 5)
      end

      it 'returns success' do
        get '/api/v1/posts'

        expect(response).to have_http_status(:success)
      end

      it 'returns all existing posts' do
        get '/api/v1/posts'

        expect(parsed_response_body[:collection][:data].size).to eq(5)
      end

      it 'returns correct json posts schema' do
        get '/api/v1/posts'

        expect(response).to match_response_schema('posts')
      end
    end

    describe 'liked by current user flag' do
      before do
        @liked_by_user = FactoryBot.create_list(:post, 2, :with_likes, liked_by: [user, other_user])
        FactoryBot.create_list(:post, 2, :with_likes, liked_by: [other_user])
        FactoryBot.create_list(:post, 1)
      end

      let(:user) { FactoryBot.create(:user) }
      let(:other_user) { FactoryBot.create(:user) }

      context 'when user unauthenticated' do
        it 'does not show liked by me flag for any post' do
          get '/api/v1/posts'

          liked_posts = parsed_response_body[:collection][:data].select { |item| item['liked_by_me'] }
          expect(liked_posts).to be_empty
        end
      end

      context 'when user is authenticated' do
        it 'shows liked by me flag for a liked post' do
          get '/api/v1/posts', headers: auth_headers(user)

          liked_posts = parsed_response_body[:collection][:data].select { |post| post['liked_by_me'] }
          liked_posts_ids = liked_posts.map { |post| post['id'] }

          expect(liked_posts_ids).not_to be_empty
          expect(liked_posts_ids).to match_array(@liked_by_user.map(&:id))
        end
      end
    end

    describe 'likes count for posts' do
      before do
        users = FactoryBot.create_list(:user, 5)
        @posts_5_likes = FactoryBot.create_list(:post, 2, :with_likes, liked_by: users)
        @posts_0_likes = FactoryBot.create_list(:post, 3)
      end

      it 'returns likes count for posts with likes' do
        get '/api/v1/posts'

        posts_with_likes = parsed_response_body[:collection][:data].select { |entry| entry['likes_count'] > 0 }
        expect(posts_with_likes.map { |post| post['id'] }).to match_array(@posts_5_likes.map(&:id))
        expect(posts_with_likes.map { |post| post['likes_count'] }).to eq([5, 5])
      end

      it 'returns zero likes count for posts without likes' do
        get '/api/v1/posts'

        posts_with_likes = parsed_response_body[:collection][:data].select { |post| post['likes_count'] == 0 }
        expect(posts_with_likes.map { |post| post['id'] }).to match_array(@posts_0_likes.map(&:id))
        expect(posts_with_likes.map { |post| post['likes_count'] }).to eq([0, 0, 0])
      end
    end

    describe 'pagination' do
      before do
        FactoryBot.create_list(:post, 138)
        @request_path = '/api/v1/posts'
        @total_records = 138
        @per_page = 20
      end

      it_behaves_like 'paginated collection response'
    end

    describe 'posts order' do
      before do
        FactoryBot.create(:post, created_at: '2020-03-27T18:28:42.956Z')
        FactoryBot.create(:post, created_at: '2020-03-25T18:28:42.956Z')
        FactoryBot.create(:post, created_at: '2020-03-26T18:28:42.956Z')
      end

      it 'returns posts in order of creation' do
        get '/api/v1/posts'

        posts_dates = parsed_response_body[:collection][:data].map { |comment| comment['published_at'] }
        expected_dates_order = [
          '2020-03-25T18:28:42.956Z',
          '2020-03-26T18:28:42.956Z',
          '2020-03-27T18:28:42.956Z'
        ]
        expect(posts_dates).to eq(expected_dates_order)
      end
    end
  end

  describe 'api/v1/posts#toggle_like' do
    context 'when user is signed in' do
      let(:user) { FactoryBot.create(:user) }
      let(:post_entry) { FactoryBot.create(:post) }

      context 'when post was not liked by user' do
        it 'returns success' do
          post "/api/v1/posts/#{post_entry.id}/toggle_like", headers: auth_headers(user)

          expect(response).to have_http_status(:success)
        end

        it 'creates like for the post' do
          expect do
            post "/api/v1/posts/#{post_entry.id}/toggle_like", headers: auth_headers(user)
          end.to change { post_entry.likes.where(user: user).count }.by(1)
        end

        it 'increases likes count for the post' do
          expect do
            post "/api/v1/posts/#{post_entry.id}/toggle_like", headers: auth_headers(user)
          end.to change { post_entry.reload.likes_count.to_i }.by(1)
        end
      end

      context 'when post was already liked by user' do
        before do
          FactoryBot.create(:like, user: user, post: post_entry)
        end

        it 'returns success' do
          post "/api/v1/posts/#{post_entry.id}/toggle_like", headers: auth_headers(user)

          expect(response).to have_http_status(:success)
        end

        it 'destroys like for the post' do
          expect do
            post "/api/v1/posts/#{post_entry.id}/toggle_like", headers: auth_headers(user)
          end.to change { post_entry.likes.where(user: user).count }.by(-1)
        end

        it 'decreases likes count for the post' do
          expect do
            post "/api/v1/posts/#{post_entry.id}/toggle_like", headers: auth_headers(user)
          end.to change { post_entry.reload.likes_count.to_i }.by(-1)
        end
      end
    end

    context 'when user is not signed in' do
      let(:post_entry) { FactoryBot.create(:post) }

      it 'returns unauthenticated' do
        post "/api/v1/posts/#{post_entry.id}/toggle_like"

        expect(response).to have_http_status(:unauthorized)
      end

      it 'does not create like' do
        expect do
          post "/api/v1/posts/#{post_entry.id}/toggle_like"
        end.not_to(change { post_entry.likes.count })
      end
    end
  end
end