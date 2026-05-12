module DashboardHelper
  DAILY_TARGET = 1_500
  WEEKLY_TARGET_LOWER = 10_150
  WEEKLY_TARGET_UPPER = 11_550
  MONTHLY_TARGET = 40_600
  DAILY_PROTEIN_TARGET = 60
  WEEKLY_PROTEIN_TARGET = 420

  BUTTON_BASE_CLASSES = "inline-flex min-h-11 items-center justify-center rounded-full px-4 text-sm font-semibold transition duration-200 hover:-translate-y-0.5"

  def panel_classes
    "rounded-[28px] border border-stone-200/80 bg-white/75 p-6 shadow-[0_18px_50px_rgba(54,31,18,0.12)] backdrop-blur-xl md:p-7"
  end

  def hero_panel_classes
    "relative overflow-hidden rounded-[32px] border border-stone-200/80 bg-gradient-to-br from-white/90 via-orange-50/90 to-rose-50/80 p-8 shadow-[0_18px_50px_rgba(54,31,18,0.12)] backdrop-blur-xl md:p-10"
  end

  def large_metric_card_classes(tone_classes = nil)
    class_names("rounded-[28px] border px-5 py-5 shadow-[0_14px_30px_rgba(54,31,18,0.08)] shadow-stone-950/5", tone_classes || "border-stone-200/80 bg-white/85")
  end

  def summary_metric_card_classes(tone_classes = nil)
    class_names("rounded-[24px] border p-5 shadow-sm shadow-stone-950/5", tone_classes || "border-stone-200/80 bg-white/85")
  end

  def metric_label_classes
    "text-sm text-stone-600"
  end

  def metric_value_classes(size: :large, color: true)
    base_classes = "mt-2 font-extrabold tracking-tight"
    size_classes = size == :large ? "text-2xl sm:text-3xl" : "text-lg"
    color_classes = color ? "text-stone-950" : nil

    class_names(base_classes, size_classes, color_classes)
  end

  def progress_track_classes
    "mt-4 h-3 overflow-hidden rounded-full bg-stone-200/80"
  end

  def progress_bar_classes
    "h-full rounded-full bg-gradient-to-r from-orange-400 via-orange-500 to-orange-700"
  end

  def supporting_text_classes(spacing: "mt-3")
    "#{spacing} text-sm leading-6 text-stone-500"
  end

  def summary_row_classes(calories)
    class_names("flex flex-col gap-3 rounded-[22px] border px-5 py-4 shadow-sm shadow-stone-950/5 sm:flex-row sm:items-center sm:justify-between", calorie_tone_classes(calories))
  end

  def meal_panel_classes(calories)
    class_names("scroll-mt-28 rounded-[28px] border p-6 shadow-[0_18px_50px_rgba(54,31,18,0.12)] backdrop-blur-xl md:p-7", section_tone_classes(calories))
  end

  def meal_badge_wrapper_classes(meal_type)
    class_names("inline-flex rounded-full px-3 py-1 text-sm font-extrabold", meal_badge_classes(meal_type))
  end

  def manual_calorie_form_classes
    "hidden rounded-[22px] border border-orange-200/70 bg-orange-50/80 p-4 shadow-sm shadow-stone-950/5 sm:col-span-2 xl:col-span-3"
  end

  def form_label_classes
    "mb-2 block text-sm font-semibold text-stone-700"
  end

  def textarea_classes
    "mt-3 min-h-36 w-full rounded-[22px] border border-stone-200/80 bg-white/90 px-4 py-4 text-sm leading-7 text-stone-700 shadow-inner shadow-stone-950/5 focus:border-orange-300 focus:outline-none focus:ring-4 focus:ring-orange-100"
  end

  def primary_button_classes
    "#{BUTTON_BASE_CLASSES} bg-gradient-to-br from-orange-500 to-orange-700 text-orange-50 shadow-[0_12px_24px_rgba(154,52,18,0.22)] hover:from-orange-400 hover:to-orange-600"
  end

  def subtle_button_classes
    "#{BUTTON_BASE_CLASSES} border border-stone-200/80 bg-white/80 text-stone-700 shadow-sm shadow-stone-950/5 hover:border-orange-200 hover:bg-orange-50"
  end

  def danger_button_classes
    "#{BUTTON_BASE_CLASSES} bg-rose-600 text-rose-50 shadow-[0_12px_24px_rgba(159,18,57,0.18)] hover:bg-rose-500"
  end

  def section_tab_classes
    "inline-flex min-h-10 items-center justify-center rounded-full border border-orange-200/70 bg-white/85 px-4 py-2 text-sm font-semibold text-orange-900 transition duration-200 hover:-translate-y-0.5 hover:border-orange-300 hover:bg-orange-50"
  end

  def period_tab_classes(active)
    if active
      "inline-flex min-h-12 items-center justify-center rounded-full bg-gradient-to-br from-orange-500 to-orange-700 px-4 text-sm font-semibold text-orange-50 shadow-[0_12px_24px_rgba(154,52,18,0.22)]"
    else
      "inline-flex min-h-12 items-center justify-center rounded-full border border-stone-200/80 bg-white/85 px-4 text-sm font-semibold text-stone-700 shadow-sm shadow-stone-950/5 transition duration-200 hover:-translate-y-0.5 hover:border-orange-200 hover:bg-orange-50"
    end
  end

  def food_button_classes
    "w-full rounded-2xl border border-orange-200/70 bg-orange-50/80 px-4 py-3 text-sm font-semibold text-orange-950 transition duration-200 hover:-translate-y-0.5 hover:border-orange-300 hover:bg-white"
  end

  def input_classes
    "w-full rounded-2xl border border-stone-200/80 bg-white px-4 py-3 text-sm text-stone-900 shadow-inner shadow-stone-950/5 focus:border-orange-300 focus:outline-none focus:ring-4 focus:ring-orange-100"
  end

  def progress_percent(current, target)
    [ (current.to_f / target * 100).round, 100 ].min
  end

  def weekly_target_range_text
    lower = number_with_delimiter(WEEKLY_TARGET_LOWER)
    upper = number_with_delimiter(WEEKLY_TARGET_UPPER)
    "週の総摂取カロリー目安: 約#{lower}〜#{upper} kcal"
  end

  def protein_status_text(deficit)
    if deficit.positive?
      "不足: #{deficit} g"
    else
      "達成済み（+#{-deficit} g）"
    end
  end

  def calorie_tone_classes(calories)
    case calories
    when 2501.. then "border-rose-300/80 bg-rose-50/90 text-rose-950"
    when 2001..2500 then "border-amber-300/80 bg-amber-50/90 text-amber-950"
    else "border-stone-200/80 bg-white/80 text-stone-950"
    end
  end

  def section_tone_classes(calories)
    case calories
    when 2501.. then "border-rose-300/80 bg-rose-50/90"
    when 2001..2500 then "border-amber-300/80 bg-amber-50/90"
    else "border-stone-200/80 bg-white/75"
    end
  end

  def meal_badge_classes(meal_type)
    case meal_type
    when "breakfast" then "bg-amber-100 text-amber-900"
    when "lunch" then "bg-orange-100 text-orange-900"
    when "dinner" then "bg-rose-100 text-rose-900"
    else "bg-violet-100 text-violet-900"
    end
  end
end
