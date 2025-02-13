module Hub
  class AssignedClientsController < ApplicationController
    FILTER_COOKIE_NAME = "assigned_clients_filters".freeze
    include AccessControllable
    include ClientSortable

    before_action :require_sign_in, :ensure_always_current_user_assigned, :load_vita_partners, :load_users
    load_and_authorize_resource :client, parent: false
    layout "admin"

    def index
      @page_title = I18n.t("hub.assigned_clients.index.title")
      @clients = filtered_and_sorted_clients.with_eager_loaded_associations.page(params[:page])
      render "hub/clients/index"
    end

    def ensure_always_current_user_assigned
      @always_current_user_assigned = true
    end

    def load_vita_partners
      @vita_partners = VitaPartner.accessible_by(current_ability)
    end

    private

    def filter_cookie_name
      FILTER_COOKIE_NAME
    end
  end
end
