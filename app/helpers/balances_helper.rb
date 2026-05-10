module BalancesHelper
  def balance_range_tab_classes(active)
    if active
      "inline-flex min-h-10 items-center justify-center rounded-full bg-gradient-to-br from-orange-500 to-orange-700 px-4 text-sm font-semibold text-orange-50 shadow-[0_12px_24px_rgba(154,52,18,0.22)]"
    else
      "inline-flex min-h-10 items-center justify-center rounded-full border border-stone-200/80 bg-white/85 px-4 text-sm font-semibold text-stone-700 shadow-sm shadow-stone-950/5 transition duration-200 hover:-translate-y-0.5 hover:border-orange-200 hover:bg-orange-50"
    end
  end

  def balance_bar_track_classes
    "h-2 w-full overflow-hidden rounded-full bg-stone-200/80"
  end

  def balance_bar_fill_classes
    "h-full rounded-full bg-gradient-to-r from-orange-400 via-orange-500 to-orange-700"
  end

  def balance_bar_percent(count, range_days)
    return 0 if range_days.zero?

    [ ((count.to_f / range_days) * 100).round, 100 ].min
  end
end
