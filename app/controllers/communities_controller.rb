class CommunitiesController < ApplicationController
  skip_filter :fetch_community,
              :cannot_access_without_joining

  before_filter :ensure_no_communities

  layout 'blank_layout'

  NewMarketplaceForm = Form::NewMarketplace

  def new
    render_form
  end

  def create
    form = NewMarketplaceForm.new(params)

    if form.valid?
      form_hash = form.to_hash
      marketplace = MarketplaceService::API::Marketplaces.create(
        form_hash.slice(:marketplace_name,
                        :marketplace_type,
                        :marketplace_country,
                        :marketplace_language)
        .merge(payment_process: :none)
      )

      user = UserService::API::Users.create_user_with_membership({
        given_name: form_hash[:admin_first_name],
        family_name: form_hash[:admin_last_name],
        email: form_hash[:admin_email],
        password: form_hash[:admin_password],
        locale: form_hash[:marketplace_language]},
        marketplace[:id])

      auth_token = UserService::API::AuthTokens.create_login_token(user[:id])
      url = URLUtils.append_query_param(marketplace[:url], "auth", auth_token[:token])
      redirect_to url
    else
      render_form(errors: form.errors.full_messages)
    end
  end

  def paypal_fee
    community = Communitites.find(params[:id])
    community.update_attributes(paypal_fee: params[:paypal_fee])
    redirect_to :back
  end

  private

  def render_form(errors: nil)
    render action: :new, locals: {
             title: 'Create a new marketplace',
             form_action: communities_path,
             errors: errors
           }
  end

  def ensure_no_communities
    redirect_to root if communities_exist?
  end

  def communities_exist?
    Community.count > 0
  end
end
