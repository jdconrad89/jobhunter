# frozen_string_literal: true

class ResumesController < ApplicationController
  before_action :require_login
  before_action :require_resume_recommendations!
  before_action :set_resume, only: [ :show, :destroy ]

  def index
    @resumes = current_user.resumes.default_first
  end

  def new
    @resume = current_user.resumes.build
  end

  def create
    result = Resumes::Create.call(user: current_user, attributes: resume_params)

    if result.success?
      redirect_to resumes_path, notice: "Resume uploaded. Text extraction is in progress."
    else
      @resume = result.resume
      render :new, status: :unprocessable_entity
    end
  end

  def show
  end

  def destroy
    @resume.destroy
    redirect_to resumes_path, notice: "Resume deleted."
  end

  private

  def set_resume
    @resume = current_user.resumes.find(params[:id])
  end

  def resume_params
    params.require(:resume).permit(:name, :file, :is_default)
  end
end
