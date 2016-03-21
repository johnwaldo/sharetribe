include PayPal::SDK::Core::Logging

class PaypalGateway

  def initialize
    #dev
    PayPal::SDK.configure(
      :mode      => "sandbox",  # Set "live" for production
      :app_id    => "APP-80W284485P519543T",
      :username  => "jb-us-seller_api1.paypal.com",
      :password  => "WX4WTU3S8MY44S7F",
      :signature => "AFcWxV21C7fd0v3bYYYRCpSSRl31A7yDhhsPUU2XhtMoZXsWHFxu-RWy" )  

      @api = PayPal::SDK::AdaptivePayments.new      
  end

  def pay(amount, seller_paypal_account, return_url)
    # Build request object
    @pay = @api.build_pay({
      :actionType => "PAY_PRIMARY",
      :cancelUrl => "https://thesurfshare.com",
      :currencyCode => "USD",
      :feesPayer => "PRIMARYRECEIVER",
      :ipnNotificationUrl => "http://localhost:3000",
      :receiverList => {
        :receiver => [
          {
            :amount => (amount).to_i,
            :email => "eltonokada+blackmarket-facilitator@gmail.com", #MARKETPLACE ACCOUNT
            :primary => true
          },
          {
            :amount => (amount).to_i - ((amount) * 0.1).to_i,
            :email => seller_paypal_account, #SELLER ACCOUNT
          }
        ]
      },
      :returnUrl => return_url })

    # Make API call & get response
    @response = @api.pay(@pay)

    Rails.logger.info("api.pay response")
    Rails.logger.info(@response.inspect)

    # Access response
    if @response.success? && @response.payment_exec_status != "ERROR"
      @response.payKey
    else
      @response.error[0].message
    end
  end

  #send payment to the seller get the key with the parameter
  def execute_payment(payKey)
    @execute_payment = @api.build_execute_payment({
      :payKey => payKey
    })

    # Make API call & get response
    @execute_payment_response = @api.execute_payment(@execute_payment)

    Rails.logger.info("api.execute_payment response")
    Rails.logger.info(@execute_payment_response)

    # Access Response
    if @execute_payment_response.success?
      @execute_payment_response.paymentExecStatus
      @execute_payment_response.payErrorList
      @execute_payment_response.postPaymentDisclosureList
    else
      @execute_payment_response.error
    end
  end

  def request_permissions
    @api = PayPal::SDK::Permissions::API.new

    # Build request object
    @request_permissions = @api.build_request_permissions({
      :scope => ["ACCESS_BASIC_PERSONAL_DATA","ACCESS_ADVANCED_PERSONAL_DATA", "REFUND", "DIRECT_PAYMENT"],
      :callback => "http://blackmarketgear.lvh.me:3000/paypal/connect_callback" })

    # Make API call & get response
    @response = @api.request_permissions(@request_permissions)

    # Access Response
    if @response.success?
      @response.token
      @api.grant_permission_url(@response) # Redirect url to grant permissions
    else
      @response.error
    end
  end


  def get_basic_personal_data(token, verifier)
    api = PayPal::SDK::Permissions::API.new

    # Build request object
    get_access_token = api.build_get_access_token({ :token => token, :verifier => verifier })

    # Make API call & get response
    get_access_token_response = api.get_access_token(get_access_token)

    # Access Response
    if get_access_token_response.success?
      api = PayPal::SDK::Permissions::API.new({
         :token => get_access_token_response.token, :token_secret => get_access_token_response.tokenSecret })
      paypal_response = api.get_basic_personal_data({
      :attributeList => {
        :attribute => [ "http://axschema.org/contact/email" ] } })
      return paypal_response.response
    else
      p ("ERROR WHEN GETTING BASIC PERSONAL DATA ======== #{get_access_token_response.error}")
      return false
    end
  end

end