module Chargify

  class InvoiceCollection < ActiveResource::Collection
    def initialize(parsed = {})
      @elements = parsed['invoices']
    end
  end

  class Invoice < Base
    include ResponseHelper

    self.collection_parser = Chargify::InvoiceCollection

    class Payment < Base
      include ResponseHelper

      self.prefix = '/invoices/:invoice_id/'
    end

    def self.find_by_invoice_id(id)
      find(:first, {:params => {:id => id}})
    end

    def self.find_by_subscription_id(id)
      find(:all, {:params => {:subscription_id => id}})
    end

    def self.unpaid_from_subscription(subscription_id)
      status_from_subscription(subscription_id, "unpaid")
    end

    def self.status_from_subscription(subscription_id, status)
      find(:all, {:params => {:subscription_id => subscription_id, :status => status}})
    end

    def self.unpaid
      find_by_status("unpaid")
    end

    def self.find_by_status(status)
      find(:all, {:params => {:status => status}})
    end

    # Returns raw PDF data. Usage example:
    # File.open(file_path, 'wb+'){ |f| f.write Chargify::Invoice.find_pdf(invoice.id) }
    def self.find_pdf(scope, options = {})
      prefix_options, query_options = split_options(options[:params])
      path = element_path(scope, prefix_options, query_options).gsub(/\.\w+$/, ".pdf")
      connection.get(path, headers).body
    end

    def payment(attrs = {})
      Payment.create(attrs.merge({:invoice_id => self.id}))
    end

    # Process a refund.  If external is true, no refund will
    # be processed.  Instead, the system will create a record
    # of the external refund.
    #
    # Required Params:
    #  - amount: A string of the dollar amount to be refunded (eg. "10.50" => $10.50)
    #  - memo: A description that will be attached to the refund
    #  - payment_id: The ID of the payment to be refunded
    #
    # Optional Params:
    #  - external: Flag that marks refund as external (no money is returned to the customer). Defaults to false.
    #  - apply_credit: If set to true, creates credit and applies it to an invoice. Defaults to false.
    #  - void_invoice: If apply_credit set to false and refunding full amount, if void_invoice set to true, invoice will be voided after refund. Defaults to false.
    #
    def refund(attrs = {})
      attrs, options = extract_uniqueness_token(attrs)
      process_capturing_errors do
        post :refunds, options, attrs.to_xml(root: :refund)
      end
    end
  end
end
