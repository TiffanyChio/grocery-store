require 'csv'
require_relative 'customer'

class Order
  attr_accessor :products, :customer, :fulfillment_status
  attr_reader :id 
  
  def initialize(id, products, customer, fulfillment_status = :pending)
    if ![:pending, :paid, :processing, :shipped, :complete].include? fulfillment_status
      raise ArgumentError, 'Invalid fulfillment status.'
    end
    
    @id = id
    @products = products
    @customer = customer
    @fulfillment_status = fulfillment_status
  end
  
  def total
    total = @products.values.sum
    total *= 1.075
    return total.round(2)
  end
  
  def add_product(prod_name, prod_price)
    if @products.keys.include? prod_name
      raise ArgumentError, 'The item is already part of the order.'
    end
    
    @products[prod_name] = prod_price
  end
  
  def remove_product(prod_name)
    if @products.keys.include? prod_name
      @products.reject! {|key,value| key == prod_name}
    else
      raise ArgumentError, 'Product was not found in cart.'
    end
  end
  
  def self.all
    all_orders = []
    
    # CSV file did not include headers, will be read as array of arrays.
    CSV.read('data/orders.csv').each do |element|
      id = element[0].to_i
      products = self.parse_product(element[1])
      customer = Customer.find(element[2].to_i)
      status = element[3].downcase.to_sym
      
      all_orders << Order.new(id, products, customer, status)
    end
    
    return all_orders
  end
  
  # Takes in a string from CSV containing information about products in the order.
  # "Lobster:17.18;Annatto seed:58.38;Camomile:83.21"
  # ...
  # Returns information in formatted hash form.
  # { "Lobster" => 17.18, "Annatto seed" => 58.38, "Camomile" => 83.21 }
  def self.parse_product(a_string)
    product_hash = {}
    
    a_string.split(";").each do |pair|
      prod_price_array = pair.split(":")
      product_hash[prod_price_array[0]] = prod_price_array[1].to_f
    end
    
    return product_hash
  end
  
  def self.find(order_id)
    matches = self.all.select {|order| order.id == order_id}
    
    # If no customer object found, returns nil like the find method for Ruby arrays.
    # Returns the first match if multiple matches found, like the find method for Ruby arrays.
    return matches[0]
  end
  
  def self.find_by_customer(cust_id)
    matches = self.all.select {|order| order.customer.id == cust_id}
    
    # Returns nil if no matches found from customer ID.
    if matches == []
      return nil
    else
      return matches
    end
  end
  
  def self.save(filename)
    all_orders = self.all
    
    CSV.open(filename, "w") do |file|
      all_orders.each do |order|
        id = order.id
        products = self.product_to_csv_format(order.products)
        customer = order.customer.id
        status = order.fulfillment_status.to_s
        
        row = [id, products, customer, status]
        
        file << row
      end
    end
  end
  
  # Takes in a hash of products and returns formatted string for CSV file.
  def self.product_to_csv_format(hash)
    string = ""
    
    hash.each do |key, value|
      string << key << ":" << value.to_s << ";"
    end
    
    # Remove the last ";" character prior to returning string.
    return string[0..-2]
  end
end
