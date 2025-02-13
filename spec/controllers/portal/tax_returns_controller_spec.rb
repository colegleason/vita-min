require 'rails_helper'

describe Portal::TaxReturnsController do
  describe "#authorize_signature" do
    let(:params) { { tax_return_id: tax_return.id } }

    context "when not logged in" do
      let(:tax_return) { create :tax_return, :ready_to_sign }
      it "redirects me to root path" do
        get :authorize_signature, params: params

        expect(response).to redirect_to :root
      end
    end

    context "when trying to access another clients tax return" do
      let(:tax_return) { create :tax_return, :ready_to_sign }
      before { sign_in create :client }

      it "it redirects to root" do
        get :authorize_signature, params: params
        expect(response).to redirect_to :portal_root
      end
    end

    context "when logged in as a client who owns the tax return" do
      before { sign_in tax_return.client }

      context "without a tax form that is ready to sign" do
        let(:tax_return) { create :tax_return }
        it "redirects to client portal root" do
          get :authorize_signature, params: params

          expect(response).to redirect_to :portal_root
        end
      end

      context "with a tax form ready to sign" do
        let(:tax_return) { create :tax_return, :ready_to_sign }

        it "renders a template" do
          get :authorize_signature, params: params

          expect(response).to render_template("authorize_signature")
        end
      end

      context "with an already signed tax form" do
        let(:tax_return) { create :tax_return, :ready_to_file_solo }

        it "redirects to the client portal root path" do
          get :authorize_signature, params: params

          expect(response).to redirect_to :portal_root
        end
      end
    end
  end

  describe "#spouse_authorize_signature" do
    let(:params) { { tax_return_id: tax_return.id } }

    before do
      allow_any_instance_of(TaxReturn).to receive(:filing_joint?).and_return true
    end

    context "when not logged in as a client" do
      let(:tax_return) { create :tax_return, :ready_to_sign }
      it "redirects to unauthenticated root" do
        get :spouse_authorize_signature, params: params

        expect(response).to redirect_to :root
      end
    end

    context "when the client does not own the tax return" do
      let(:tax_return) { create :tax_return, :ready_to_sign }
      before { sign_in create :client }

      it "redirects to client portal root" do
        get :spouse_authorize_signature, params: params

        expect(response).to redirect_to :portal_root
      end
    end

    context "when logged in as a client" do
      before { sign_in tax_return.client }

      context "without a tax form that is ready to sign" do
        let(:tax_return) { create :tax_return }
        it "redirects to client portal root" do
          get :spouse_authorize_signature, params: params

          expect(response).to redirect_to :portal_root
        end
      end

      context "with a tax form ready to sign" do
        let(:tax_return) { create :tax_return, :ready_to_sign }

        it "renders a template" do
          get :spouse_authorize_signature, params: params

          expect(response).to render_template :spouse_authorize_signature
        end
      end
    end
  end

  describe "#sign" do
    context "when not logged in as a client" do
      let(:params) { { tax_return_id: tax_return.id } }
      let(:tax_return) { create :tax_return, :ready_to_sign, client: (create :client, intake: (create :intake, filing_joint: "no")) }

      it "redirects to root" do
        get :sign, params: params

        expect(response).to redirect_to :root
      end
    end

    context "when logged in but not the owner of the tax return" do
      let(:params) { { tax_return_id: tax_return.id } }
      let(:tax_return) { create :tax_return, :ready_to_sign, client: (create :client, intake: (create :intake, filing_joint: "no")) }

      it "redirects to root" do
        get :sign, params: params
        expect(response).to redirect_to :root
      end
    end

    context "when logged in as a client who owns the tax return" do
      let(:tax_return) { create :tax_return, :ready_to_sign, client: (create :client, intake: (create :intake, filing_joint: "no")) }
      before { sign_in tax_return.client }

      context "clients tax return cannot be signed" do
        context "because there are no unsigned 8879s is already signed" do
          let(:tax_return) { create :tax_return, :ready_to_file_solo, client: (create :client, intake: (create :intake, filing_joint: "no")) }

          let(:params) { { tax_return_id: tax_return.id } }

          it "redirects to client portal root" do
            post :sign, params: params
            expect(flash[:notice]).to eq I18n.t("controllers.tax_returns_controller.errors.cannot_sign")
            expect(response).to redirect_to :portal_root
          end
        end

        context "because there is no Form8879 to sign" do
          let(:tax_return) { create :tax_return, client: (create :client, intake: (create :intake, filing_joint: "no")) }

          let(:params) { { tax_return_id: tax_return.id }}

          it "redirects to client portal" do
            post :sign, params: params
            expect(flash[:notice]).to eq I18n.t("controllers.tax_returns_controller.errors.cannot_sign")
            expect(response).to redirect_to :portal_root
          end
        end

        context "because the primary signature is already recorded on the tax return" do
          let(:tax_return) { create :tax_return, :ready_to_file_solo }
          let(:params) { { tax_return_id: tax_return.id } }

          it "redirects to client portal dashboard" do
            post :sign, params: params
            expect(flash[:notice]).to eq "This tax return form cannot be signed."
            expect(response).to redirect_to :portal_root
          end
        end
      end

      context "client can sign the tax return" do
        let(:tax_return) { create :tax_return, :ready_to_sign, client: (create(:client, intake: create(:intake, filing_joint: "yes"))) }
        let(:params) { { tax_return_id: tax_return.id, portal_primary_sign_form8879: { primary_accepts_terms: "yes", primary_confirms_identity: "yes" } } }

        it "sets @tax_return from the params[:tax_return_id]" do
          post :sign, params: params

          expect(assigns(:tax_return)).to eq tax_return
          expect(assigns(:form)).to be_an_instance_of Portal::PrimarySignForm8879
        end

        context "when efile terms are accepted and identity confirmed" do
          let(:params) { { tax_return_id: tax_return.id, portal_primary_sign_form8879: { primary_accepts_terms: "yes", primary_confirms_identity: "yes" } } }

          context "when form successfully saves" do
            it "redirects to success page" do
              post :sign, params: params
              expect(flash[:notice]).to eq "Successfully signed 2019 tax form!"
              expect(response).to redirect_to(portal_root_path)
            end
          end

          context "when form fails to save" do
            let(:form_double) { double }
            before do
              allow(Portal::PrimarySignForm8879).to receive(:new).and_return(form_double)
              allow(form_double).to receive(:sign).and_return false
              allow(form_double).to receive_message_chain(:errors, :keys).and_return [:transaction_failed]
            end

            it "re-renders the page with a flash message" do
              post :sign, params: params

              expect(flash[:alert]).to eq("Error signing tax return. Try again or contact support.")
              expect(response).to render_template(:authorize_signature)
            end
          end
        end

        context "when efile terms are not accepted" do
          let(:params) { { tax_return_id: tax_return.id, portal_primary_sign_form8879: { primary_accepts_terms: "no" } } }

          it "re-renders the page with a flash message" do
            post :sign, params: params

            expect(response).to render_template :authorize_signature
            expect(flash[:alert]).to eq "Please click the authorize checkbox to continue."
          end
        end

        context "when certification of identity is not checked" do
          let(:params) { { tax_return_id: tax_return.id, portal_primary_sign_form8879: { primary_accepts_terms: "yes", primary_confirms_identity: "no" } } }

          it "re-renders the page with a flash message" do
            post :sign, params: params
            expect(response).to render_template :authorize_signature
            expect(flash[:alert]).to eq "Please confirm that you are the listed taxpayer to continue."
          end
        end
      end
    end

  end

  describe "#spouse_sign" do
    let(:tax_return) { create :tax_return, client: (create :client, intake: (create :intake, filing_joint: "no")) }
    before do
      allow_any_instance_of(TaxReturn).to receive(:filing_joint?).and_return true
    end

    context "when not logged in" do
      let(:tax_return) { create :tax_return, :ready_to_sign, client: (create :client, intake: (create :intake, filing_joint: "yes"))}
      let(:params) { { tax_return_id: tax_return.id } }

      it "redirects to root" do
        get :spouse_sign, params: params
        expect(response).to redirect_to :root
      end
    end

    context "when logged in but not the owner of the tax return" do
      let(:params) { { tax_return_id: tax_return.id } }
      let(:tax_return) { create :tax_return, :ready_to_sign, client: (create :client, intake: (create :intake, filing_joint: "yes"))}

      before { sign_in create :client }

      it "redirects to client portal root" do
        get :sign, params: params
        expect(response).to redirect_to :portal_root
      end
    end

    context "when logged in as a client" do
      before { sign_in tax_return.client }

      context "tax return cannot be signed" do
        context "because there are no unsigned 8879s" do
          let(:tax_return) { create :tax_return, :ready_to_file_joint, client: (create :client, intake: (create :intake, filing_joint: "yes"))}

          let(:params) { { tax_return_id: tax_return.id } }

          it "redirects to client portal root" do
            post :spouse_sign, params: params
            expect(flash[:notice]).to eq I18n.t("controllers.tax_returns_controller.errors.cannot_sign")
            expect(response).to redirect_to :portal_root
          end
        end

        context "because there is no Form8879 to sign" do
          let(:tax_return) { create :tax_return }
          let(:params) { { tax_return_id: tax_return.id } }

          it "redirects to client portal root" do
            post :spouse_sign, params: params
            expect(flash[:notice]).to eq I18n.t("controllers.tax_returns_controller.errors.cannot_sign")
            expect(response).to redirect_to :portal_root
          end
        end

        context "because it does not require a spouse signature" do
          let(:tax_return) { create :tax_return, :ready_to_sign }
          let(:params) { { tax_return_id: tax_return.id } }

          before do
            allow_any_instance_of(TaxReturn).to receive(:filing_joint?).and_return false
          end

          it "redirects to client portal root" do
            post :spouse_sign, params: params
            expect(flash[:notice]).to eq "This tax return form cannot be signed."
            expect(response).to redirect_to :portal_root
          end
        end

        context "because the spouse signature is already recorded on the tax return" do
          let(:tax_return) { create :tax_return, :ready_to_file_joint }
          let(:params) { { tax_return_id: tax_return.id } }

          it "redirects to client portal root" do
            post :spouse_sign, params: params
            expect(flash[:notice]).to eq "This tax return form cannot be signed."
            expect(response).to redirect_to :portal_root
          end
        end
      end

      context "spouse can sign the tax return" do
        let(:params) { { tax_return_id: tax_return.id, portal_spouse_sign_form8879: { spouse_accepts_terms: "yes", spouse_confirms_identity: "yes" } } }
        let(:tax_return) { create :tax_return, :ready_to_sign, client: (create :client, intake: (create :intake, filing_joint: "no")) }

        it "sets @tax_return from the params[:tax_return_id]" do
          post :spouse_sign, params: params

          expect(assigns(:tax_return)).to eq tax_return
          expect(assigns(:form)).to be_an_instance_of Portal::SpouseSignForm8879
        end

        context "when efile terms are accepted and identity confirmed" do
          let(:params) { { tax_return_id: tax_return.id, portal_spouse_sign_form8879: { spouse_accepts_terms: "yes", spouse_confirms_identity: "yes" } } }

          context "when form successfully saves" do
            it "redirects to success page" do
              post :spouse_sign, params: params
              expect(flash[:success]).to eq "Successfully signed 2019 tax form!"
              expect(response).to redirect_to :portal_root
            end
          end

          context "when form fails to save" do
            let(:form_double) { double }
            before do
              allow(Portal::SpouseSignForm8879).to receive(:new).and_return(form_double)
              allow(form_double).to receive(:sign).and_return false
              allow(form_double).to receive_message_chain(:errors, :keys).and_return [:transaction_failed]
            end

            it "re-renders the page with a flash message" do
              post :spouse_sign, params: params

              expect(flash[:alert]).to eq("Error signing tax return. Try again or contact support.")
              expect(response).to render_template(:spouse_authorize_signature)
            end
          end
        end

        context "when efile terms are not accepted" do
          let(:tax_return) { create :tax_return, :ready_to_sign }
          let(:params) { { tax_return_id: tax_return.id, portal_spouse_sign_form8879: { spouse_accepts_terms: "no" } } }

          it "re-renders the page with a flash message" do
            post :spouse_sign, params: params

            expect(response).to render_template :spouse_authorize_signature
            expect(flash[:alert]).to eq "Please click the authorize checkbox to continue."
          end
        end

        context "when certification of identity is not checked" do
          let(:tax_return) { create :tax_return, :ready_to_sign }
          let(:params) { { tax_return_id: tax_return.id, portal_spouse_sign_form8879: { spouse_accepts_terms: "yes", spouse_confirms_identity: "no" } } }

          it "re-renders the page with a flash message" do
            post :spouse_sign, params: params
            expect(response).to render_template :spouse_authorize_signature
            expect(flash[:alert]).to eq "Please confirm that you are the listed taxpayer to continue."
          end
        end
      end
    end
  end
end