module Assistly
  class Client
    # Defines methods related to interactions
    module Interaction
      
      # Returns extended information of up to 100 interactions
      #
      #   @option options [Boolean, String, Integer]
      #   @example Return extended information for 12345
      #     Assistly.interactions(:since_id => 12345)
      #     Assistly.interactions(:since_id => 12345, :count => 5)
      # @format :json
      # @authenticated true
      # @see http://dev.assistly.com/docs/api/interactions
      def interactions(*args)
        options = args.last.is_a?(Hash) ? args.pop : {}
        response = get("interactions",options)
        response['results']
      end
      
      def create_interaction(*args)
        options = args.last.is_a?(Hash) ? args.pop : {}
        direction = 
        if options[:direction].to_s == "outbound"
          options.delete(:direction)
          to      = options.delete(:customer_email)
          subject = options.delete(:interaction_subject)
          body    = options.delete(:interaction_body)
          
          create_outbound_interaction(to, subject, body, options)
        else
          create_inbound_interaction(options)
        end
      end

      # Creates an interaction from a customer
      #
      # @format :json
      # @authenticated true
      # @rate_limited true
      # @return [Array] The requested users.
      # @see http://dev.assistly.com/docs/api/interactions/create
      # @example Create a new interaction
      #   Assistly.create_interaction(:interaction_subject => "this is an api test", :customer_email => "foo@example.com")
      def create_inbound_interaction(*args)
        options = args.last.is_a?(Hash) ? args.pop : {}
        response = post('interactions', options)
        if response['success']
          return response['results']
        else
          return response['errors']
        end
      end
      
      # Create an interaction from an agent
      # 
      # Assistly's API doesn't support creating a new case/interaction initiated by an agent
      # so we'll use send an email to the customer directly that is BCC'd to the support email address
      # which will create the ticket
      # 
      # @see http://support.assistly.com/customer/portal/articles/4180
      # @see http://support.assistly.com/customer/portal/articles/6728
      def create_outbound_interaction(to, subject, body, *args)
        options = args.last.is_a?(Hash) ? args.pop : {}
        options.merge!(:to => to, :subject => subject, :body => body, :from => support_email, :bcc => support_email)
        options.merge!(:headers => { "x-assistly-customer-email" => to, 
                                     "x-assistly-interaction-direction" => "out",
                                     "x-assistly-case-status" => options[:status]||"open"})
        Pony.mail(options)
      end
    end
  end
end
