module Api
  class JobPostsController < ApplicationController
    def index
      @job_posts = JobPost.includes(:company).all
      render json: @job_posts.as_json(
        include: { company: { only: [ :id, :name ] } },
        except: [ :created_at, :updated_at ]
      )
    end
  end
end
