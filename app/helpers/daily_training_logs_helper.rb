module DailyTrainingLogsHelper
  def consecutive_training_types(training_types_by_date, date, body_part)
    previous_types = training_types_by_date.fetch(date - 1.day, {}).fetch(body_part, [])
    current_types = training_types_by_date.fetch(date, {}).fetch(body_part, [])

    TrainingExercise::TRAINING_TYPE_LABELS.keys & previous_types & current_types
  end

  def training_period_label(range, tab)
    case tab
    when "month" then range.begin.strftime("%Y年%-m月")
    when "week" then "#{range.begin.strftime('%Y/%-m/%-d')}〜#{range.end.strftime('%Y/%-m/%-d')}"
    else range.begin.strftime("%Y/%-m/%-d")
    end
  end

  def training_period_date(date, tab, direction)
    case tab
    when "month" then date >> direction
    when "week" then date + direction.weeks
    else date + direction.days
    end
  end

  def training_exercise_options(exercises_by_type)
    TrainingExercise::TRAINING_TYPE_LABELS.filter_map do |type, label|
      exercises = exercises_by_type.fetch(type, [])
      next if exercises.empty?

      [ label, exercises.map { |exercise| [ exercise.name, exercise.id ] } ]
    end
  end

  def training_log_details(log)
    effort = []
    effort << "#{log.reps}回" if log.reps.present?
    effort << "#{log.duration_seconds}秒" if log.duration_seconds.present?
    details = [ effort.presence&.join(" / "), ("#{log.sets}セット" if log.sets.present?) ].compact.join(" × ")
    weight = "#{number_with_precision(log.weight_kg, precision: 2, strip_insignificant_zeros: true)}kg" if log.weight_kg.present?

    [ details.presence, weight ].compact.presence&.join(" / ") || "実施を記録"
  end
end
