# -*- encoding : utf-8 -*-
class JobsController < ApplicationController

  # before_filter :authenticate_user!, only: [:new, :create, :edit, :update, :destroy]
  before_filter :find_my_job, only: [:edit, :update, :destroy, :open, :close]

  def index
    if params[:user_id]
      @jobs = User.find(params[:user_id]).jobs.recent
    elsif params[:keyword]
      session[:keyword] = params[:keyword]
      @jobs = Job.online.search(params[:keyword])
    elsif session[:keyword]
      @jobs = Job.online.search(session[:keyword])
    else
      @jobs = Job.online.recent
    end
  end

  def show
    @job = Job.find(params[:id])

    set_page_title "#{@job.title} | #{@job.company_name} is hiring!"
    set_page_description @job.description
  end

  def new
    @job = Job.new
    # @job.deadline = Time.zone.now + 90.days
  end

  def create
    @job = Job.new(params[:job])
    payment(params[:stripe_token])

    puts "--------------------------------"
    puts @payment
    if @job.save
      redirect_to job_path(@job)
    else
      render :new
    end
  end

  def edit
  end

  def preview
    @job = current_user.jobs.build(params[:job])
    @job.created_at = Time.now
    @job.valid?

    render layout: false
  end

  def update
    if @job.update_attributes(params[:job])
      redirect_to job_path(@job)
    else
      render :edit
    end
  end

  def destroy
    @job.destroy

    redirect_to jobs_path
  end

  def open
    @job.open
    @job.save!

    redirect_to job_path(@job)
  end

  def close
    @job.close
    @job.save!

    redirect_to job_path(@job)
  end

  protected

  def find_my_job
    @job = Job.find(params[:id])
  end

  def payment(token)
    @transcation = Stripe::Charge.create(
      :amount => 40000, # 40$
      :currency => "usd",
      :card => token,
      :description => "Charge for apptopia job posting"
    )
  end
end