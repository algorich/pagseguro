module PagSeguro
  module ActionController
    private
    def pagseguro_notification(options={}, &block)
      return unless request.post?
      query = { :email => options[:email] || PagSeguro.config['email'],
                :token => options[:token] || PagSeguro.config['authenticity_token'] }

      response = HTTParty.get(
                   pagseguro_notification_path(params['notificationCode']),
                   { :query => query }).
                 parsed_response.
                 recursive_symbolize_underscorize_keys!

      notification = PagSeguro::Notification.new(response[:transaction])
      yield notification
    end

    def pagseguro_notification_path(code)
      PagSeguro.gateway_notification_url + "/#{code}"
    end

    def pagseguro_payment_path(code)
      PagSeguro.gateway_payment_url + "?code=#{code}"
    end

    def pagseguro_post(order)
      header = { 'Content-Type' => 'application/x-www-form-urlencoded; charset=utf-8' }

      # Add required params
      params = {
	      :email => order.email || PagSeguro.config['email'],
	      :token => order.token || PagSeguro.config['authenticity_token'],
	      :currency => 'BRL',
	      :reference => order.reference
      }

      # Add opitional params
	    params[:shippingType] = order.shipping_type if order.shipping_type
	    params[:redirectURL] = order.redirect_url if order.redirect_url
	    params[:extraAmount] = '%.2f' % order.extra_amount if order.extra_amount
	    params[:maxUses] = order.max_uses if order.max_uses
	    params[:maxAge] = order.max_age if order.max_age

	    # Add products
	    order.products.each_with_index do |product, i|
		    i += 1
		    params["itemId#{i}"] = product[:id]
		    params["itemDescription#{i}"] = product[:description]
		    params["itemAmount#{i}"] = '%.2f' % product[:amount]
		    params["itemQuantity#{i}"] = product[:quantity]
		    params["itemShippingCost#{i}"] = '%.2f' % product[:shipping] if product[:shipping]
		    params["itemWeight#{i}"] = product[:weight] if product[:weight]
	    end

      # Add billing info
	    order.billing.each do |name, value|
		    params[PagSeguro::Order::BILLING_MAPPING[name.to_sym]] = value
	    end

      post_options = { :body => params, :headers => header }
	    response = HTTParty.post(PagSeguro.gateway_url, post_options).parsed_response

	    return :errors => [{:code => 'HTTP 401', :message => 'Unauthorized'}] if response == 'Unauthorized'

	    response.recursive_symbolize_underscorize_keys!
	    if response[:checkout]
  	    response[:checkout][:date] = response[:checkout][:date].to_datetime
        return response[:checkout]
      else
        errors = response[:errors][:error]
        response[:errors] = (errors.class == Hash) ? [errors] : errors
        return response
      end
    end
  end
end

