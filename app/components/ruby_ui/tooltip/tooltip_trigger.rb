# frozen_string_literal: true

module RubyUI
  class TooltipTrigger < Base
    def view_template(&)
      div(**attrs, &)
    end

    private

    def default_attrs
      {
        data: {
          ruby_ui__tooltip_target: "trigger",
          action: [
            "mouseenter->ruby-ui--tooltip#show",
            "mouseleave->ruby-ui--tooltip#hide",
            "focusin->ruby-ui--tooltip#show",
            "focusout->ruby-ui--tooltip#hide"
          ]
        }
      }
    end
  end
end
