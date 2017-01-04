#encoding: utf-8
require "spec_helper"

describe PagSeguro::Order do
  before do
    @order = PagSeguro::Order.new
    @product = {:amount => 9.90, :description => "Ruby 1.9 PDF", :reference => 1}
  end

  it "should set order reference when instantiating object" do
    @order = PagSeguro::Order.new("ABCDEF")
    @order.reference.should == "ABCDEF"
  end

  it "should set order reference throught setter" do
    @order.reference = "ABCDEF"
    @order.reference.should == "ABCDEF"
  end

  it "should set order email throught setter" do
    @order.email = "john@doe.com"
    @order.email.should == "john@doe.com"
  end

  it "should set order token throught setter" do
    @order.token = "ABCDEF342432243AHI2"
    @order.token.should == "ABCDEF342432243AHI2"
  end

  it "should set order shipping type throught setter" do
    @order.shipping_type = 1
    @order.shipping_type.should == 1
  end

  it "should set order redirect url throught setter" do
    @order.redirect_url = 'http://example.com.br/confirmation'
    @order.redirect_url.should == 'http://example.com.br/confirmation'
  end

  it "should set order extra amount throught setter" do
    @order.extra_amount = -35.20
    @order.extra_amount.should == -35.20
  end

  it "should set order max uses throught setter" do
    @order.max_uses = 8
    @order.max_uses.should == 8
  end

  it "should set order max age throught setter" do
    @order.max_age = 60
    @order.max_age.should == 60
  end

  it "should reset products" do
    @order.products += [1,2,3]
    @order.products.should have(3).items
    @order.reset!
    @order.products.should be_empty
  end

  it "should alias add method" do
    @order.should_receive(:<<).with(:reference => 1)
    @order.add :reference => 1
  end

  it "should add product with default settings" do
    @order << @product
    @order.products.should have(1).item

    p = @order.products.first
    p[:amount].should == 9.90
    p[:description].should == "Ruby 1.9 PDF"
    p[:reference].should == 1
    p[:quantity].should == 1
    p[:weight].should be_nil
    p[:shipping].should be_nil
  end

  it "should add product with custom settings" do
    @order << @product.merge(:quantity => 3, :shipping => 3.50, :weight => 100)
    @order.products.should have(1).item

    p = @order.products.first
    p[:amount].should == 9.90
    p[:description].should == "Ruby 1.9 PDF"
    p[:reference].should == 1
    p[:quantity].should == 3
    p[:weight].should == 100
    p[:shipping].should == 3.50
  end

  it "should respond to billing attribute" do
    @order.should respond_to(:billing)
  end

  it "should initialize billing attribute" do
    @order.billing.should be_instance_of(Hash)
  end

  describe 'pagseguro_post' do
    before do
      @order = PagSeguro::Order.new('I1001')
      PagSeguro.stub(:gateway_url) {'http://localhost:3000'}
      @default_params = { :email => 'john@doe.com',
                          :token => '9CA8D46AF0C6177CB4C23D76CAF5E4B0',
                          :currency => 'BRL',
                          :reference => 'I1001'}
      @response = { 'checkout' => {'code' => '9CA8D46AF0C6177CB4C23D76CAF5E4B0',
                                   'date' => '2010-12-02T10:11:28.000-02:00' } }
    end

    def stub_post(params={})
      HTTParty.should_receive(:post).
        with(PagSeguro.gateway_url,
          hash_including(:body => @default_params.merge(params))).
            and_return(stub(:parsed_response => @response))
    end

    context 'with errors should return a hash with errors code and message' do
      it 'pagseguro uniq default error' do
        @response = { 'errors' => { 'error' => { 'code' => '11004', 'message' => 'Currency is required.' } } }

        stub_post
        hash = { :currency => ['Currency is required.'] }
        @order.post!
        @order.errors.should == hash
      end

      it 'pagseguro multiple default errors' do
        @response = { 'errors' => { 'error' =>  [{ 'code' => '11004', 'message' => 'Currency is required.' },
                                                 { 'code' => '11005', 'message' => 'Currency invalid value: 100' }]}}

        stub_post
        hash = { :currency => ['Currency is required.', 'Currency invalid value: 100'] }
        @order.post!
        @order.errors.should == hash
      end

      it 'http 401 Unauthorized error' do
        @response = 'Unauthorized'
        stub_post
        hash = { :base => ['Unauthorized'] }
        @order.post!
        @order.errors.should == hash
      end
    end

    context 'successfully' do
      it 'should assign code and date after post' do
        hash = { :code => '9CA8D46AF0C6177CB4C23D76CAF5E4B0',
                 :date => '2010-12-02T10:11:28.000-02:00'.to_datetime }
        stub_post
        @order.post!
        @order.checkout_code.should == hash[:code]
        @order.checkout_date.should == hash[:date]
      end

      context 'with default options' do
        after(:each) do
          @order.post!
        end

        it 'email' do
          stub_post :email => 'john@doe.com'
        end

        it 'token' do
          stub_post :token => '9CA8D46AF0C6177CB4C23D76CAF5E4B0'
        end
      end

      context 'with custom options' do
        after(:each) do
          @order.post!
        end

        it 'email' do
          @order.email = 'mary@example.com'
          stub_post :email => 'mary@example.com'
        end

        it 'token' do
          @order.token = '5BD8D46AC1C6177AA5C23D76CAF6A5F2'
          stub_post :token => '5BD8D46AC1C6177AA5C23D76CAF6A5F2'
        end

        it "should include shipping type" do
          @order.shipping_type = 1
          stub_post :shippingType => 1
        end

        it "should include redirect url" do
          @order.redirect_url = 'http://example.com.br/confirmation'
          stub_post :redirectURL => 'http://example.com.br/confirmation'
        end

        it "should include extra amount" do
          @order.extra_amount = -35.20
          stub_post :extraAmount => '-35.20'
        end

        it "should include max uses" do
          @order.max_uses = 8
          stub_post :maxUses => 8
        end

        it "should include max age" do
          @order.max_age = 60
          stub_post :maxAge => 60
        end

        context "with minimum product info" do
          before(:each) do
            @order << { :id => 1001, :amount => 10.00, :description => "Rails 3 e-Book" }
          end

          it 'should include the required info' do
            params = { 'itemId1' => 1001,
                       'itemDescription1' => 'Rails 3 e-Book',
                       'itemQuantity1' => 1,
                       'itemAmount1' => '10.00' }
            stub_post params
          end

          it 'should not include the optional info' do
            HTTParty.should_receive(:post).
              with(PagSeguro.gateway_url,
                hash_not_including('itemShippingCost1', 'itemWeight1')).
                  and_return(stub(:parsed_response => @response))
          end
        end

        context "with optional product info" do
          it 'should include the optional info' do
            @order << { :id => 1001, :amount => 17.23, :description => 'T-Shirt',
                        :weight => 300, :shipping => 8.50, :quantity => 33 }

            params = { 'itemId1' => 1001,
                       'itemDescription1' => 'T-Shirt',
                       'itemQuantity1' => 33,
                       'itemAmount1' => '17.23',
                       'itemShippingCost1' => '8.50',
                       'itemWeight1' => 300}
            stub_post params
          end
        end

        context "with multiple products" do
          it 'should include all products' do
            @order << { :id => 1001, :amount => 18.07, :description => 'Rails 3 e-Book' }
            @order << { :id => 1002, :amount => 19.30, :description => 'E-Book + Screencast' }

            params = { 'itemId1' => 1001,
                       'itemDescription1' => 'Rails 3 e-Book',
                       'itemQuantity1' => 1,
                       'itemAmount1' => '18.07',
                       'itemId2' => 1002,
                       'itemDescription2' => 'E-Book + Screencast',
                       'itemQuantity2' => 1,
                       'itemAmount2' => '19.30' }
            stub_post params
          end
        end

        context "with billing info" do
          it 'should include all the billing info' do
            @order.billing = {
	            :name => 'John Doe',
	            :email => 'john@doe.com',
	            :phone_area_code => 22,
	            :phone_number => 12345678,
	            :address_country => 'BRA',
	            :address_state => 'AC',
	            :address_city => 'Pantano Grande',
	            :address_street => 'Rua Orobó',
	            :address_postal_code => 28050035,
	            :address_district => 'Tenório',
	            :address_number => 72,
	            :address_complement => 'Casa do fundo',
            }

            params = { 'senderName' => 'John Doe',
                       'senderEmail' => 'john@doe.com',
                       'senderAreaCode' => 22,
                       'senderPhone' => 12345678,
                       'shippingAddressCountry' => 'BRA',
                       'shippingAddressState' => 'AC',
                       'shippingAddressCity' => 'Pantano Grande',
                       'shippingAddressPostalCode' => 28050035,
                       'shippingAddressDistrict' => 'Tenório',
                       'shippingAddressStreet' => 'Rua Orobó',
                       'shippingAddressNumber' => 72,
                       'shippingAddressComplement' => 'Casa do fundo' }
            stub_post params
          end
        end
      end
    end
  end

end

