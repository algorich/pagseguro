module PagSeguro
  class Order
    class Validator < ActiveModel::Validator

      # Map all errors codes with the respective attribute in the order model.
      # https://pagseguro.uol.com.br/v2/guia-de-integracao/codigos-de-erro.html
      ERROR_MAPPING = {
        11001 => :receiver_email, # receiverEmail is required.
        11002 => :receiver_email, # receiverEmail invalid length: {0}
        11003 => :receiver_email, # receiverEmail invalid value.
        11004 => :currency, # Currency is required.
        11005 => :currency, # Currency invalid value: {0}
        11006 => :redirect_url, # redirectURL invalid length: {0}
        11007 => :redirect_url, # invalid value: {0}
        11008 => :reference, # reference invalid length: {0}
        11009 => :email, # senderEmail invalid length: {0}
        11010 => :email, # senderEmail invalid value: {0}
        11011 => :name, # senderName invalid length: {0}
        11012 => :name, # senderName invalid value: {0}
        11013 => :phone_area_code, # senderAreaCode invalid value: {0}
        11014 => :phone_number, # senderPhone invalid value: {0}
        11015 => :shipping_type, # ShippingType is required.
        11016 => :shipping_type, # ShippingType invalid type: {0}
        11017 => :address_postal_code, # shippingPostalCode invalid Value: {0}
        11018 => :address_street, # shippingAddressStreet invalid length: {0}
        11019 => :address_number, # shippingAddressNumber invalid length: {0}
        11020 => :address_complement, # shippingAddressComplement invalid length: {0}
        11021 => :address_district, # shippingAddressDistrict invalid length: {0}
        11022 => :address_city, # shippingAddressCity invalid length: {0}
        11023 => :address_state, # shippingAddressState invalid value: {0}, must fit the pattern: \w\{2\} (e. g. "SP")
        11024 => :itens, # Itens invalid quantity.
        11025 => :item, # Item Id is required.
        11026 => :item, # Item quantity is required.
        11027 => :item, # Item quantity out of range: {0}
        11028 => :item, # Item amount is required. (e.g. "12.00")
        11029 => :item, # Item amount invalid pattern: {0}. Must fit the patern: \d+.\d\{2\}
        11030 => :item, # Item amount out of range: {0}
        11031 => :item, # Item shippingCost invalid pattern: {0}. Must fit the patern: \d+.\d\{2\}
        11032 => :item, # Item shippingCost out of range: {0}
        11033 => :item, # Item description is required.
        11034 => :item, # Item description invalid length: {0}
        11035 => :item, # Item weight invalid Value: {0}
        11036 => :extra_amount, # Extra amount invalid pattern: {0}. Must fit the patern: -?\d+.\d\{2\}
        11037 => :extra_amount, # Extra amount out of range: {0}
        11038 => :base, # Invalid receiver for checkout: {0}, verify receiver's account status.
        11039 => :base, # Malformed request XML: {0}.
        11040 => :max_age, # maxAge invalid pattern: {0}. Must fit the patern: \d+
        11041 => :max_age, # maxAge out of range: {0}
        11042 => :max_uses, # maxUses invalid pattern: {0}. Must fit the patern: \d+
        11043 => :max_uses, # maxUses out of range.
        11044 => :initial_date, # initialDate is required.
        11045 => :initial_date, # initialDate must be lower than allowed limit.
        11046 => :initial_date, # initialDate must not be older than 6 months.
        11047 => :initial_date, # initialDate must be lower than or equal finalDate.
        11048 => :search_interval, # search interval must be lower than or equal 30 days.
        11049 => :final_date, # finalDate must be lower than allowed limit.
        11050 => :initial_date, # initialDate invalid format, use 'yyyy-MM-ddTHH:mm' (eg. 2010-01-27T17:25).
        11051 => :final_date, # finalDate invalid format, use 'yyyy-MM-ddTHH:mm' (eg. 2010-01-27T17:25).
        11052 => :page, # page invalid value.
        11053 => :max_page_results, # maxPageResults invalid value (must be between 1 and 1000).
        11054 => :abandon_url, # abandonURL invalid length: {0}
        11055 => :abandon_url, # abandonURL invalid value: {0}
        11056 => :address, # sender address required invalid value: {0}
        11057 => :address, # sender address not required with address data filled
      }

      def validate(record)
        response = record.response
        return if response.blank?

        if response == 'Unauthorized'
          record.errors.add(:base, 'Unauthorized')
          return false
        end

        response.recursive_symbolize_underscorize_keys!
        return if response[:errors].blank?

        response_errors = response[:errors][:error]
        response_errors = (response_errors.class == Hash) ? [response_errors] : response_errors

        response_errors.each do |error|
          code = error[:code].to_i
          attribute = ERROR_MAPPING[code] || :base
          message = I18n.t(code, :scope => "pagseguro.errors", :default => [error[:message]])

          record.errors.add attribute, message
        end
      end

    end
  end
end

