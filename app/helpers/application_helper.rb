module ApplicationHelper
  def body_classes
    "min-h-screen bg-[radial-gradient(circle_at_top_left,rgba(213,103,43,0.18),transparent_32%),radial-gradient(circle_at_top_right,rgba(116,144,98,0.16),transparent_28%),linear-gradient(180deg,#f7f1e8_0%,#f4ede1_100%)] font-sans text-stone-950 antialiased"
  end

  def flash_container_classes
    "sticky top-4 z-50 mx-auto w-full max-w-6xl px-4 sm:px-6 lg:px-8"
  end

  def flash_message_classes(type)
    tone_classes =
      if type == :alert
        "border-rose-200/80 bg-rose-50/90 text-rose-900 shadow-[0_12px_30px_rgba(136,19,55,0.12)]"
      else
        "border-emerald-200/80 bg-emerald-50/90 text-emerald-900 shadow-[0_12px_30px_rgba(6,95,70,0.12)]"
      end

    class_names("mb-3 rounded-2xl border px-4 py-3 text-sm font-medium backdrop-blur", tone_classes)
  end

  def page_shell_classes
    "mx-auto flex w-full max-w-6xl flex-col gap-6 px-4 pb-10 pt-32 sm:px-6 sm:pt-36 lg:px-8"
  end

  def top_bar_classes
    "fixed inset-x-0 top-0 z-40 border-b border-stone-200/80 bg-white/80 shadow-[0_14px_30px_rgba(54,31,18,0.08)] backdrop-blur-xl"
  end

  def top_bar_inner_classes
    "mx-auto flex w-full max-w-6xl flex-wrap items-center justify-between gap-3 px-4 py-3 sm:px-6 lg:px-8"
  end

  def brand_control_classes
    "inline-flex min-h-11 items-center rounded-full bg-white/85 px-4 text-left font-display text-sm tracking-[0.18em] text-stone-950 transition duration-200 hover:-translate-y-0.5 hover:bg-white"
  end

  def nav_group_classes
    "flex flex-wrap gap-2"
  end

  def page_title_classes
    "font-display text-2xl tracking-[0.12em] text-stone-950 sm:text-3xl"
  end

  def section_title_classes
    "font-serif text-3xl leading-tight tracking-tight text-stone-950"
  end

  def hero_title_classes
    "mt-4 font-display text-3xl leading-none tracking-[0.14em] text-stone-950 sm:text-4xl lg:text-5xl"
  end

  def section_description_classes
    "mt-2 text-sm leading-6 text-stone-600"
  end

  def card_classes
    "rounded-[24px] border border-stone-200/80 bg-white/85 p-5 shadow-sm shadow-stone-950/5"
  end

  def compact_card_classes
    "rounded-[22px] border border-stone-200/80 bg-white/90 px-4 py-4 shadow-sm shadow-stone-950/5"
  end

  def empty_state_classes
    "mt-5 rounded-[22px] border border-dashed border-stone-300/80 bg-white/60 px-5 py-8 text-center text-sm text-stone-600"
  end
end
