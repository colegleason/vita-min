class DocumentsController < ApplicationController
  include AccessControllable
  before_action :require_intake
  
  def illustration_path; end

  def destroy
    document = current_intake.documents.find_by(id: params[:id])

    if document.present?
      document.destroy

      redirect_to helpers.edit_document_path(document.document_type)
    else
      redirect_to overview_documents_path
    end
  end
end
