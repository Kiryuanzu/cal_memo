class DailyTrainingLogsController < ApplicationController
  before_action :set_selected_tab

  def index
    @selected_date = parse_date(params[:date]) || Time.zone.today
    @daily_training_log = DailyTrainingLog.new(trained_on: @selected_date)
    load_daily_logs
  end

  def create
    @daily_training_log = DailyTrainingLog.new(daily_training_log_params)

    if @daily_training_log.save
      notice = "#{@daily_training_log.training_exercise.name}を登録しました。"
      if request.format.turbo_stream? && (params[:date].blank? || parse_date(params[:date]) == @daily_training_log.trained_on)
        @selected_date = @daily_training_log.trained_on
        load_summary
        flash.now[:notice] = notice
        render turbo_stream: [
          turbo_stream.update("training-flash", partial: "shared/flash"),
          turbo_stream.replace("training-summary", partial: "daily_training_logs/summary", locals: summary_locals),
          turbo_stream.remove("training-empty-state"),
          turbo_stream.remove("training-input-errors"),
          turbo_stream.append("training-log-list", partial: "daily_training_logs/log_item", locals: { log: @daily_training_log, selected_tab: @selected_tab })
        ]
      else
        redirect_to daily_training_logs_path(date: @daily_training_log.trained_on.iso8601, tab: @selected_tab, anchor: "input-section"),
          notice: notice, status: :see_other
      end
    else
      @selected_date = parse_date(params[:date]) || @daily_training_log.trained_on || Time.zone.today
      load_daily_logs
      respond_to do |format|
        format.turbo_stream do
          render turbo_stream: turbo_stream.replace("input-section", partial: "daily_training_logs/input", locals: {
            daily_training_log: @daily_training_log, selected_date: @selected_date,
            selected_tab: @selected_tab, exercises_by_type: @exercises_by_type
          }), status: :unprocessable_entity
        end
        format.html { render :index, status: :unprocessable_entity }
      end
    end
  end

  def update
    log = DailyTrainingLog.find(params.expect(:id))

    if log.update(daily_training_log_detail_params)
      respond_to do |format|
        format.turbo_stream do
          flash.now[:notice] = "#{log.training_exercise.name}の詳細を保存しました。"
          render turbo_stream: [
            turbo_stream.update("training-flash", partial: "shared/flash"),
            turbo_stream.replace(helpers.dom_id(log), partial: "daily_training_logs/log", locals: { log: log, selected_tab: @selected_tab, expanded: true })
          ]
        end
        format.html do
          redirect_to daily_training_logs_path(date: log.trained_on.iso8601, tab: @selected_tab, anchor: helpers.dom_id(log)),
            notice: "#{log.training_exercise.name}の詳細を保存しました。", status: :see_other
        end
      end
    else
      @selected_date = log.trained_on
      @daily_training_log = DailyTrainingLog.new(trained_on: @selected_date)
      load_daily_logs
      @daily_logs = @daily_logs.map { |daily_log| daily_log.id == log.id ? log : daily_log }
      respond_to do |format|
        format.turbo_stream do
          render turbo_stream: turbo_stream.replace(helpers.dom_id(log), partial: "daily_training_logs/log", locals: {
            log: log, selected_tab: @selected_tab, expanded: true
          }), status: :unprocessable_entity
        end
        format.html { render :index, status: :unprocessable_entity }
      end
    end
  end

  def destroy
    log = DailyTrainingLog.find(params.expect(:id))
    @selected_date = log.trained_on
    notice = "#{log.training_exercise.name}の記録を削除しました。"
    log.destroy!

    respond_to do |format|
      format.turbo_stream do
        load_summary
        flash.now[:notice] = notice
        updates = [
          turbo_stream.update("training-flash", partial: "shared/flash"),
          turbo_stream.remove(helpers.dom_id(log, :item)),
          turbo_stream.replace("training-summary", partial: "daily_training_logs/summary", locals: summary_locals)
        ]
        unless DailyTrainingLog.for_date(@selected_date).exists?
          updates << turbo_stream.update("training-empty-message", partial: "daily_training_logs/empty_state")
        end
        render turbo_stream: updates
      end
      format.html do
        redirect_to daily_training_logs_path(date: @selected_date.iso8601, tab: @selected_tab, anchor: "daily-logs-section"),
          notice: notice, status: :see_other
      end
    end
  end

  private
    def set_selected_tab
      @selected_tab = params[:tab].in?(%w[week month]) ? params[:tab] : nil
    end

    def daily_training_log_detail_params
      params.expect(daily_training_log: [ :sets, :reps, :weight_kg, :duration_seconds ])
    end

    def daily_training_log_params
      params.expect(daily_training_log: [ :training_exercise_id, :trained_on, :sets, :reps, :weight_kg, :duration_seconds ])
    end

    def parse_date(value)
      return if value.blank?

      Date.iso8601(value)
    rescue ArgumentError
      nil
    end

    def load_daily_logs
      @daily_logs = DailyTrainingLog.includes(:training_exercise).for_date(@selected_date).order(:created_at, :id)
      @exercises_by_type = TrainingExercise.alphabetical.group_by(&:training_type)
      load_summary
    end

    def load_summary
      @summary_range = case @selected_tab
      when "week" then @selected_date.all_week(:monday)
      when "month" then @selected_date.all_month
      else @selected_date..@selected_date
      end
      @training_types_by_date = DailyTrainingLog.training_types_by_date((@summary_range.begin - 1.day)..@summary_range.end)
      @comparison_parts_by_date = @training_types_by_date.transform_values(&:keys)
      @body_parts_by_date = @comparison_parts_by_date.select { |date, _| @summary_range.cover?(date) }
      @body_part_days = @body_parts_by_date.values.flatten.tally
    end

    def summary_locals
      {
        selected_date: @selected_date, selected_tab: @selected_tab, range: @summary_range,
        body_parts_by_date: @body_parts_by_date, body_part_days: @body_part_days,
        comparison_parts_by_date: @comparison_parts_by_date, training_types_by_date: @training_types_by_date
      }
    end
end
