require "rails_helper"

RSpec.feature "View and edit documents for a client" do
  context "As an authenticated user" do
    let(:user) { create :organization_lead_user }
    let(:client) { create :client, vita_partner: user.role.organization, intake: create(:intake, preferred_name: "Bart Simpson", primary_consented_to_service_at: DateTime.new(2021, 1, 26)) }
    let(:tax_return_1) { create :tax_return, client: client, year: 2019 }
    let!(:document_1) { create :document, display_name: "ID.jpg", client: client, intake: client.intake, tax_return: tax_return_1, document_type: "Care Provider Statement" }
    let!(:document_2) { create :document, display_name: "W-2.pdf", client: client, intake: client.intake, tax_return: tax_return_1, document_type: "Care Provider Statement" }
    before do
      login_as user
      create :tax_return, client: client, year: 2017
    end

    scenario "navigation" do
      visit hub_client_documents_path(client_id: client.id)
      click_on "Return to all clients"
      expect(page).to have_current_path(hub_clients_path)
    end

    scenario "view document list and edit document attributes" do
      visit hub_client_documents_path(client_id: client.id)

      expect(page).to have_selector("h1", text: "Bart Simpson")
      expect(page).to have_selector("#document-#{document_1.id}", text: "ID.jpg")
      expect(page).to have_selector("#document-#{document_1.id}", text: "Care Provider Statement")
      expect(page).to have_selector("#document-#{document_1.id}", text: "2019")

      within "#document-#{document_1.id}" do
        click_on "Edit"
      end

      expect(page).to have_text("Edit Document")

      fill_in("Display name", with: "Updated Document Title")
      select("2017", from: "Tax return")
      select("Form 8879 (Unsigned)", from: "Document type")

      click_on "Save"

      expect(page).to have_selector("h1", text: "Bart Simpson")
      expect(page).to have_selector("#document-#{document_1.id}", text: "Updated Document Title")
      expect(page).to have_selector("#document-#{document_1.id}", text: "2017")
      expect(page).to have_selector("#document-#{document_1.id}", text: "Form 8879 (Unsigned)")
    end

    scenario "view consent form when the client has signed the consent form" do
      visit hub_client_documents_path(client_id: client.id)

      expect(page).to have_content("Consent Form 14446")
      expect(page).to have_content("14446 Consent Form")

      visit hub_client_path(id: client.id)
      visit hub_client_documents_path(client_id: client.id)

      expect(Document.where(document_type: "Consent Form 14446", intake: client.intake).count).to eq 1

      click_on "14446 Consent Form"
    end

    scenario "uploading a document to a client's documents page" do
      visit hub_client_documents_path(client_id: client.id)

      click_on "Add client envelope document"

      attach_file "document_upload", [
        Rails.root.join("spec", "fixtures", "attachments", "test-pattern.png"),
        Rails.root.join("spec", "fixtures", "attachments", "document_bundle.pdf"),
      ]

      fill_in "Display name", with: "A new final document"

      select "Final Tax Document", from: "Document type"
      select "2017", from: "Tax return"

      click_on "Save"

      within "#document-#{Document.last.id}" do
        expect(page).to have_content("2017")
        expect(page).to have_content("Final Tax Document")
      end
    end
  end
end
