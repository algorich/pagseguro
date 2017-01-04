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

  end
end

