# frozen_string_literal: true

module RubyUI
  class Button < Base
    BASE_CLASSES = [
      "inline-flex shrink-0 items-center justify-center whitespace-nowrap font-extrabold transition duration-150",
      "focus:outline-none focus:ring-2 focus:ring-offset-2 active:translate-y-px",
      "disabled:pointer-events-none disabled:opacity-50",
      "aria-disabled:pointer-events-none aria-disabled:cursor-not-allowed aria-disabled:opacity-50",
      "dark:focus:ring-offset-[#0F172A]"
    ].freeze

    def initialize(type: :button, variant: :primary, size: :sm, icon: false, full_width: false, **attrs)
      @type = type
      @variant = variant.to_sym
      @size = size.to_sym
      @icon = icon
      @full_width = full_width
      super(**attrs)
    end

    def view_template(&)
      button(**attrs, &)
    end

    private

    def size_classes
      if @icon
        case @size
        when :xs then "h-8 w-8 rounded-md"
        when :sm then "h-9 w-9 rounded-lg"
        else "h-10 w-10 rounded-lg"
        end
      else
        case @size
        when :xs then "min-h-8 gap-1.5 rounded-md px-2.5 py-1.5 text-xs"
        when :sm then "min-h-9 gap-1.5 rounded-lg px-3 py-2 text-xs sm:text-[13px]"
        else "min-h-10 gap-2 rounded-lg px-3.5 py-2.5 text-sm"
        end
      end
    end

    def variant_classes
      {
        primary: "bg-red-600 text-white shadow-sm shadow-red-950/10 hover:bg-red-700 focus:ring-red-600 dark:bg-red-600 dark:hover:bg-red-500",
        secondary: "border border-[#CBD5E1] bg-white text-[#0F172A] shadow-sm hover:border-slate-400 hover:bg-slate-50 focus:ring-red-600 dark:border-[#475569] dark:bg-[#1E293B] dark:text-[#F8FAFC] dark:hover:bg-[#334155]",
        outline: "border border-[#CBD5E1] bg-white text-[#0F172A] shadow-sm hover:border-slate-400 hover:bg-slate-50 focus:ring-red-600 dark:border-[#475569] dark:bg-[#1E293B] dark:text-[#F8FAFC] dark:hover:bg-[#334155]",
        dark: "bg-[#172033] text-white shadow-sm hover:bg-[#263247] focus:ring-slate-600 dark:bg-[#334155] dark:hover:bg-[#475569]",
        success: "bg-emerald-600 text-white shadow-sm hover:bg-emerald-700 focus:ring-emerald-600",
        danger: "bg-red-700 text-white shadow-sm hover:bg-red-800 focus:ring-red-600 dark:bg-red-600 dark:hover:bg-red-500",
        destructive: "bg-red-700 text-white shadow-sm hover:bg-red-800 focus:ring-red-600 dark:bg-red-600 dark:hover:bg-red-500",
        ghost: "text-red-700 hover:bg-red-50 focus:ring-red-600 dark:text-red-400 dark:hover:bg-red-500/10",
        link: "text-red-700 hover:bg-red-50 focus:ring-red-600 dark:text-red-400 dark:hover:bg-red-500/10",
        outline_danger: "border border-red-200 bg-white text-red-700 hover:bg-red-50 focus:ring-red-600 dark:border-red-500/40 dark:bg-[#1E293B] dark:text-red-400 dark:hover:bg-red-500/10"
      }.fetch(@variant, "bg-red-600 text-white shadow-sm hover:bg-red-700 focus:ring-red-600")
    end

    def default_attrs
      {
        type: @type,
        class: [ BASE_CLASSES, size_classes, variant_classes, ("w-full" if @full_width) ]
      }
    end
  end
end
