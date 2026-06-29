module Admin
  class WelfareAttachmentsController < ApplicationController
    def destroy
      @welfare_attachment = policy_scope(WelfareAttachment).find(params[:id])
      authorize @welfare_attachment
      welfare_case = @welfare_attachment.welfare_case
      @welfare_attachment.destroy

      redirect_to admin_welfare_case_path(welfare_case), notice: "Attachment was deleted."
    end
  end
end
