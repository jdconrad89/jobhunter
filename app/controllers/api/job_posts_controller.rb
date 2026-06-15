module Api
  class JobPostsController < BaseController
    skip_before_action :authenticate_api_token!, only: [ :index ]

    def index
      @job_posts = JobPost.includes(:company).all
      render json: @job_posts.as_json(
        include: { company: { only: [ :id, :name ] } },
        except: [ :created_at, :updated_at ]
      )
    end

    def create
      result = JobPosts::CreateManual.call(user: current_user, attributes: job_post_params)

      if result.success?
        render json: job_post_json(result.job_post), status: :created
      else
        render json: { errors: result.errors.full_messages }, status: :unprocessable_entity
      end
    end

    private

    def job_post_params
      params.require(:job_post).permit(
        :title,
        :website,
        :description,
        :location,
        :remote,
        :company_name
      )
    end

    def job_post_json(job_post)
      job_post.as_json(
        include: { company: { only: [ :id, :name ] } },
        except: [ :created_at, :updated_at ]
      ).merge("url" => job_post_url(job_post))
    end
  end
end
