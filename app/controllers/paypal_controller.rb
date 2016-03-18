class PaypalController < ApplicationController
  def pay
    gateway = PaypalGateway.new
    #retorna url que vai dar o redirect para o paypal
    #INTEGRAR COM O FLUXO DO SHARETRIBE
    render text: gateway.pay
  end

  def connect
    paypal_gateway = PaypalGateway.new
    redirect_to paypal_gateway.request_permissions
  end  

  def connect_callback
    paypal_gateway = PaypalGateway.new
    paypal_personal_data = paypal_gateway.get_basic_personal_data(params[:request_token], params[:verification_code])
    paypal_account = paypal_personal_data.personalData[0].personalDataValue
    flash[:notice] = "Paypal Account Connected!"
    
    @current_user.update_attributes(paypal_account: paypal_account)

    redirect_to "/"
  end

end