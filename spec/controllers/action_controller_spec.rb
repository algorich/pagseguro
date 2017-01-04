# -*- encoding : utf-8 -*-

require "spec_helper"

describe PagSeguro::DeveloperController do
  context 'pagseguro_notification' do
    before do
      PagSeguro.stub(:developer?) {true}
      @email = 'john@doe.com'
      @token = '9CA8D46AF0C6177CB4C23D76CAF5E4B'
      config = {
        'email' => @email,
        'authenticity_token' => @token,
        'base' => 'http://localhost:3000'
      }
      PagSeguro.stub(:config) { config }
      @code = '766B9C-AD4B044B04DA-77742F5FA653-E1AB24'
      @url = "http://localhost:3000/pagseguro_developer_notification/#{@code}"
    end

    it 'with default params' do
      # Define a fake method for test purpose
      class PagSeguro::DeveloperController
        def confirm
          pagseguro_notification { |n| 'do nothing' }
          render :nothing => true
        end
      end

      HTTParty.should_receive(:get).with(@url, {:query => {:email => @email, :token => @token}}).
        and_return(stub(:parsed_response => {}))
      PagSeguro::Notification.should_receive(:new)
      post 'confirm', {'notificationCode' => @code }
    end

    context 'with custom params' do
      it 'email' do
        # Define a fake method for test purpose
        class PagSeguro::DeveloperController
          def confirm
            pagseguro_notification(:email => 'other@example.com') do |n|
              'do nothing'
            end
            render :nothing => true
          end
        end

        query = {:email => 'other@example.com', :token => @token}
        HTTParty.should_receive(:get).with(@url, {:query => query}).
          and_return(stub(:parsed_response => {}))
        PagSeguro::Notification.should_receive(:new)
        post 'confirm', {'notificationCode' => @code }
      end

      it 'token' do
        # Define a fake method for test purpose
        class PagSeguro::DeveloperController
          def confirm
            pagseguro_notification(:token => 'B4E5FAC67D32C4BC7716C0FA') do |n|
              'do nothing'
            end
            render :nothing => true
          end
        end

        query = {:email => @email, :token => 'B4E5FAC67D32C4BC7716C0FA'}
        HTTParty.should_receive(:get).with(@url, {:query => query}).
          and_return(stub(:parsed_response => {}))
        PagSeguro::Notification.should_receive(:new)
        post 'confirm', {'notificationCode' => @code }
      end
    end
  end
end

describe PagSeguro::ActionController do
  include PagSeguro::ActionController

  it "should return the payment url with given code" do
    code = '9CA8D46AF0C6177CB4C23D76CAF5E4B0'
    pagseguro_payment_path(code).should == PagSeguro.gateway_payment_url + "?code=#{code}"
  end

  it "should return the notification url with given code" do
    code = '9CA8D46AF0C6177CB4C23D76CAF5E4B0'
    pagseguro_notification_path(code).should == PagSeguro.gateway_notification_url + "/#{code}"
  end

end

