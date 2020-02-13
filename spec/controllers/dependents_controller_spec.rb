require "rails_helper"

RSpec.describe DependentsController do
  render_views

  let(:intake) { create :intake }
  let(:user) { create :user, intake: intake }

  before do
    allow(subject).to receive(:current_user).and_return user
  end

  describe "#index" do

    context "with existing dependents" do
      let!(:dependent_one) { create :dependent, first_name: "Kylie", last_name: "Kiwi", birth_date: Date.new(2012, 4, 21), intake: intake}
      let!(:dependent_two) { create :dependent, first_name: "Kelly", last_name: "Kiwi", birth_date: Date.new(2012, 4, 21), intake: intake}

      it "renders information about each dependent" do
        get :index

        expect(response.body).to include "Kylie Kiwi 4/21/2012"
        expect(response.body).to include "Kelly Kiwi 4/21/2012"
      end
    end
  end

  describe "#create" do
    context "with valid params" do
      let(:params) do
        {
          dependent: {
            first_name: "Kylie",
            last_name: "Kiwi",
            birth_date_month: "6",
            birth_date_day: "15",
            birth_date_year: "2015",
            relationship: "Nibling",
            months_in_home: "12",
            was_student: "no",
            on_visa: "no",
            north_american_resident: "yes",
            disabled: "no",
            was_married: "no"
          }
        }
      end

      it "creates a new dependent linked to the current intake and redirects to the index" do
        expect do
          post :create, params: params
        end.to change(Dependent, :count).by 1

        expect(response).to redirect_to(dependents_path)

        dependent = Dependent.last
        expect(dependent.intake).to eq intake
        expect(dependent.first_name).to eq "Kylie"
        expect(dependent.last_name).to eq "Kiwi"
        expect(dependent.birth_date).to eq Date.new(2015, 6, 15)
        expect(dependent.relationship).to eq "Nibling"
        expect(dependent.months_in_home).to eq 12
        expect(dependent.was_student).to eq "no"
        expect(dependent.on_visa).to eq "no"
        expect(dependent.north_american_resident).to eq "yes"
        expect(dependent.disabled).to eq "no"
        expect(dependent.was_married).to eq "no"
      end
    end

    context "with invalid params" do
      let(:params) do
        {
          dependent: {
            first_name: "Kylie",
            birth_date_month: "16",
            birth_date_day: "2",
            birth_date_year: "2015",
            relationship: "Nibling",
            months_in_home: "12",
            was_student: "no",
            on_visa: "no",
            north_american_resident: "yes",
            disabled: "no",
            was_married: "no"
          }
        }
      end

      it "renders new with validation errors" do
        expect do
          post :create, params: params
        end.not_to change(Dependent, :count)

        expect(response).to render_template(:new)

        expect(response.body).to include "Please enter a valid date."
        expect(response.body).to include "Please enter a last name."
      end
    end
  end

  describe "#edit" do
    let!(:dependent) do
      create :dependent,
             first_name: "Mary",
             last_name: "Mango",
             birth_date: Date.new(2017, 4, 21),
             relationship: "Kid"
    end

    it "renders information about the existing dependent and renders a delete button" do
      get :edit, params: { id: dependent.id }

      expect(response.body).to include("Mary")
      expect(response.body).to include("Mango")
      expect(response.body).to include("Kid")
      expect(response.body).to include("Remove dependent")
    end
  end

  describe "#update" do
    let!(:dependent) do
      create :dependent,
             first_name: "Mary",
             last_name: "Mango",
             birth_date: Date.new(2017, 4, 21),
             relationship: "Kid",
             intake: intake
    end

    context "with valid params" do
      let(:params) do
        {
          id: dependent.id,
          dependent: {
            first_name: "Kylie",
            last_name: "Kiwi",
            birth_date_month: "6",
            birth_date_day: "15",
            birth_date_year: "2015",
            relationship: "Nibling",
            months_in_home: "12",
            was_student: "no",
            on_visa: "no",
            north_american_resident: "yes",
            disabled: "no",
            was_married: "no"
          }
        }
      end

      it "updates the dependent and redirects to the index" do
        post :update, params: params

        expect(response).to redirect_to(dependents_path)

        dependent.reload
        expect(dependent.first_name).to eq "Kylie"
        expect(dependent.last_name).to eq "Kiwi"
        expect(dependent.birth_date).to eq Date.new(2015, 6, 15)
        expect(dependent.relationship).to eq "Nibling"
        expect(dependent.months_in_home).to eq 12
        expect(dependent.was_student).to eq "no"
        expect(dependent.on_visa).to eq "no"
        expect(dependent.north_american_resident).to eq "yes"
        expect(dependent.disabled).to eq "no"
        expect(dependent.was_married).to eq "no"
      end
    end

    context "with invalid params" do
      let(:params) do
        {
          id: dependent.id,
          dependent: {
            first_name: "Kylie",
            last_name: "",
            birth_date_month: "16",
            birth_date_day: "2",
            birth_date_year: "2015",
            relationship: "Nibling",
            months_in_home: "12",
            was_student: "no",
            on_visa: "no",
            north_american_resident: "yes",
            disabled: "no",
            was_married: "no"
          }
        }
      end

      it "renders edit with validation errors" do
        expect do
          post :update, params: params
        end.not_to change(Dependent, :count)

        expect(response).to render_template(:edit)

        expect(response.body).to include "Please enter a valid date."
        expect(response.body).to include "Please enter a last name."
      end
    end
  end

  describe "#destroy" do
    let!(:dependent) do
      create :dependent,
             first_name: "Mary",
             last_name: "Mango",
             birth_date: Date.new(2017, 4, 21),
             relationship: "Kid"
    end

    it "deletes the dependent and adds a flash message" do
      expect do
        delete :destroy, params: { id: dependent.id }
      end.to change(Dependent, :count).by(-1)

      expect(flash[:notice]).to eq "Removed Mary Mango."
    end
  end
end
