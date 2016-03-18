require 'paypal-sdk-rest'

include PayPal::SDK::REST
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
  end

  def pay(amount, return_url)
    p "**************** INSIDE METHOD PAY *****************"
    p "PAYPAL GATEWAY AMOUNT =============> #{amount} ======================="

    #SANDBOX
    PayPal::SDK.configure({
      :mode => "sandbox", 
      :username => "eltonokada+blackmarket-facilitator_api1.gmail.com",
      :password => "P63TMHWVTC5CJPHS", 
      :signature => "AFcWxV21C7fd0v3bYYYRCpSSRl31Ay0i15qYgrnzxLogdH9zOuYTMQOA"
    })

    api = PayPal::SDK::Merchant::API.new
    set_express_checkout = api.build_set_express_checkout({

    :Version => "104.0",
    :SetExpressCheckoutRequestDetails => {
            :ReturnURL => return_url,
            :CancelURL => return_url,
            :PaymentDetails =>[{
              :OrderTotal =>{ :currencyID => "AUD", :value => amount }, :PaymentAction => "Sale"}
              ]
            }
          })

    set_express_checkout_response = api.set_express_checkout(set_express_checkout)

    p "======= CHECKOUT RESPONSE ======= #{set_express_checkout_response}"
    set_express_checkout_response.token

  end

  #send payment to the seller get the key with the parameter
  def send_to_seller(payKey)
    p "******************** EXECUTE PAYMENT ****************"
    # THIS METHOD WILL TRANSFER THE MONEY FROM THE MARKETPLACE ACCOUNT TO THE SELLER ACCOUNT
    # SEND IT TO ENV VARIABLES IN CONFIG

    set_rest_config

    transaction = Transaction.where("paypal_paykey = ?", payKey).last
    
    unless transaction.deposit_cents.nil?
      amount = transaction.amount - transaction.deposit_cents
    else
      amount = transaction.amount
    end
    @payout = PayPal::SDK::REST::Payout.new(
      {
        :sender_batch_header => {
          :sender_batch_id => SecureRandom.hex(8),
          :email_subject => 'You have a Payout!',
        },
        :items => [
          {
            :recipient_type => 'EMAIL',
            :amount => {
              :value => (amount).to_i - ((amount) * 0.1).to_i,
              :currency => 'AUD'
            },
            :note => 'Thanks!',
            :receiver => transaction.seller.paypal_account
          }
        ]
      }
    )

    p "*************** PAYOUT ************* #{@payout} *****************"
    begin
      @payout_batch = @payout.create
      Rails.logger.info "Created Payout with [#{@payout_batch.batch_header.payout_batch_id}]"
      payout_item_id = @payout_batch.items[0].payout_item_id
      
      PaypalPayout.create(transaction_id: transaction.id, paypal_payout_id: payout_item_id)

    rescue ResourceNotFound => err
      Rails.logger.error @payout.error.inspect
    end
  end

  def cancel_payout
    #@payout_item_detail= PayoutItem.cancel(@payout_batch.items[0].payout_item_id)
  end

  #refund the express checkout sale - when the seller rejects the buyer
  def refund_deposit(transaction_id)
    p "******************** REFUND DEPOSIT ****************"
    Paypal.sandbox!

    request = Paypal::Express::Request.new(
      :username => "eltonokada+blackmarket-facilitator_api1.gmail.com",
      :password => "P63TMHWVTC5CJPHS", 
      :signature => "AFcWxV21C7fd0v3bYYYRCpSSRl31Ay0i15qYgrnzxLogdH9zOuYTMQOA"
    )

    transaction = Transaction.find(transaction_id)

    request.refund! transaction.paypal_transaction_id
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
    

  private

  def set_rest_config
    #sandbox
    PayPal::SDK::REST.set_config(
      :mode => "sandbox",
      :client_id => "AVsZT1jWTICSega1GtOaSgGr7LuJ3IrZ3PW6j8zmxbf9hF4Lt3ZXqA7UWPps5OLb2oelz8uXrxOaSqqH",
      :client_secret => "EM9kN_k5sEOBbwYuMaqcnAXWmzyjI-Y-ExvjI_l-SOBiPl3Vj5dl1McMVgKUFaJWktgckkOWTgNUJ6UB")
  end

end