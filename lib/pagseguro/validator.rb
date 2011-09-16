module PagSeguro
  class Order
    class Validator < ActiveModel::Validator

      # Map all errors codes with the respective attribute in the order model.
      # https://pagseguro.uol.com.br/v2/guia-de-integracao/codigos-de-erro.html
      ERROR_MAPPING = {
        11001 => :email, # receiverEmail is required.
        11002 => :email, # receiverEmail invalid length: {0}
        11003 => :email, # receiverEmail invalid value.
        11004 => :currency, # Currency is required.
        11005 => :currency, # Currency invalid value: {0}
        11006 => :redurect_url, # redirectURL invalid length: {0}
        11007 => :redirect_url, # invalid value: {0}
        11008 => :reference, # reference invalid length: {0}
        11009 => :sender_email, # senderEmail invalid length: {0}
        11010 => :sender_email, # senderEmail invalid value: {0}
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
        11024 => :base, # Itens invalid quantity.
        11025 => :base, # Item Id is required.
        11026 => :base, # Item quantity is required.
        11027 => :base, # Item quantity out of range: {0}
        11028 => :base, # Item amount is required. (e.g. "12.00")
        11029 => :base, # Item amount invalid pattern: {0}. Must fit the patern: \d+.\d\{2\}
        11030 => :base, # Item amount out of range: {0}
        11031 => :base, # Item shippingCost invalid pattern: {0}. Must fit the patern: \d+.\d\{2\}
        11032 => :base, # Item shippingCost out of range: {0}
        11033 => :base, # Item description is required.
        11034 => :base, # Item description invalid length: {0}
        11035 => :base, # Item weight invalid Value: {0}
        11036 => :base, # Extra amount invalid pattern: {0}. Must fit the patern: -?\d+.\d\{2\}
        11037 => :base, # Extra amount out of range: {0}
        11038 => :base, # Invalid receiver for checkout: {0}, verify receiver's account status.
        11039 => :base, # Malformed request XML: {0}.
        11040 => :base, # maxAge invalid pattern: {0}. Must fit the patern: \d+
        11041 => :base, # maxAge out of range: {0}
        11042 => :base, # maxUses invalid pattern: {0}. Must fit the patern: \d+
        11043 => :base, # maxUses out of range.
        11044 => :base, # initialDate is required.
        11045 => :base, # initialDate must be lower than allowed limit.
        11046 => :base, # initialDate must not be older than 6 months.
        11047 => :base, # initialDate must be lower than or equal finalDate.
        11048 => :base, # search interval must be lower than or equal 30 days.
        11049 => :base, # finalDate must be lower than allowed limit.
        11050 => :base, # initialDate invalid format, use 'yyyy-MM-ddTHH:mm' (eg. 2010-01-27T17:25).
        11051 => :base, # finalDate invalid format, use 'yyyy-MM-ddTHH:mm' (eg. 2010-01-27T17:25).
        11052 => :base, # page invalid value.
        11053 => :base, # maxPageResults invalid value (must be between 1 and 1000).
        11054 => :base, # abandonURL invalid length: {0}
        11055 => :base, # abandonURL invalid value: {0}
        11056 => :base, # sender address required invalid value: {0}
        11057 => :base, # sender address not required with address data filled
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
          attribute = ERROR_MAPPING[ error[:code].to_i ] || :base
          record.errors.add attribute, error[:message]
        end
      end

    end
  end
end

