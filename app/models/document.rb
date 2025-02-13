# == Schema Information
#
# Table name: documents
#
#  id                   :bigint           not null, primary key
#  contact_record_type  :string
#  display_name         :string
#  document_type        :string           not null
#  uploaded_by_type     :string
#  created_at           :datetime         not null
#  updated_at           :datetime         not null
#  client_id            :bigint
#  contact_record_id    :bigint
#  documents_request_id :bigint
#  intake_id            :bigint
#  tax_return_id        :bigint
#  uploaded_by_id       :bigint
#
# Indexes
#
#  index_documents_on_client_id                                  (client_id)
#  index_documents_on_contact_record_type_and_contact_record_id  (contact_record_type,contact_record_id)
#  index_documents_on_documents_request_id                       (documents_request_id)
#  index_documents_on_intake_id                                  (intake_id)
#  index_documents_on_tax_return_id                              (tax_return_id)
#  index_documents_on_uploaded_by_type_and_uploaded_by_id        (uploaded_by_type,uploaded_by_id)
#
# Foreign Keys
#
#  fk_rails_...  (client_id => clients.id)
#  fk_rails_...  (documents_request_id => documents_requests.id)
#  fk_rails_...  (tax_return_id => tax_returns.id)
#
require "mini_magick"

class Document < ApplicationRecord
  include InteractionTracking

  belongs_to :intake, optional: true
  belongs_to :client
  belongs_to :documents_request, optional: true
  belongs_to :contact_record, polymorphic: true, optional: true
  belongs_to :tax_return, optional: true
  belongs_to :uploaded_by, polymorphic: true, optional: true

  validates_presence_of :client
  validates_presence_of :upload
  validate :tax_return_belongs_to_client
  validate :upload_must_have_data
  # Permit all existing document types plus two historical ones
  validates_presence_of :document_type
  validates :document_type, inclusion: { in: DocumentTypes::ALL_TYPES.map(&:key) + ["Requested", "F13614C / F15080 2020"] }, allow_blank: true

  before_save :set_display_name

  default_scope { order(created_at: :asc) }

  scope :of_type, ->(type) { where(document_type: type) }

  after_create_commit do
    uploaded_by.is_a?(Client) ? record_incoming_interaction : record_internal_interaction

    if upload.filename.extension_without_delimiter.downcase == "heic"
      HeicToJpgJob.perform_later(id)
    end
  end

  # has_one_attached needs to be called after defining any callbacks that access attachments, like
  # the HEIC conversion; see https://github.com/rails/rails/issues/37304
  has_one_attached :upload

  def document_type_label
    DocumentTypes::ALL_TYPES.find { |doc_type_class| doc_type_class.key == document_type } || document_type
  end

  def set_display_name
    return if display_name.present?

    self.display_name = upload.attachment.filename
  end

  def convert_heic_upload_to_jpg!
    image = MiniMagick::Image.read(upload.download)

    jpg_image = image.format("jpg")

    upload.attach(io: File.open(jpg_image.path), filename: "#{display_name}.jpg", content_type: "image/jpg")
    update!(display_name: upload.attachment.filename)
  end

  def uploaded_by_name_label
    if uploaded_by.is_a? User
      uploaded_by.name || ""
    elsif uploaded_by.is_a? Client
      I18n.t("hub.documents.index.client_doc")
    else
      I18n.t("hub.documents.index.system_generated_doc")
    end
  end

  private

  def tax_return_belongs_to_client
    errors.add(:tax_return, I18n.t("forms.errors.tax_return_belongs_to_client")) unless tax_return.blank? || tax_return.client == client
  end

  def upload_must_have_data
    if upload.attached? && upload.blob.byte_size.zero?
      errors[:upload] << I18n.t("validators.file_zero_length")
    end
  end
end
