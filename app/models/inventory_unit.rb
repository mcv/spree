class InventoryUnit < ActiveRecord::Base
  belongs_to :variant
  belongs_to :order
  validates_presence_of :status
  
  enumerable_constant :status, {:constants => INVENTORY_STATES, :no_validation => true}
  
  # destory the specified number of on hand inventory units 
  def self.destroy_on_hand(variant, quantity)
    inventory = self.find_by_status(variant, quantity, InventoryUnit::Status::ON_HAND)
    inventory.each do |unit|
      unit.destroy
    end                                          
  end
  
  # destory the specified number of on hand inventory units
  def self.create_on_hand(variant, quantity)
    quantity.times do
      self.create(:variant => variant, :status => InventoryUnit::Status::ON_HAND)
    end
  end
  
  # adjust inventory status for the line items in the order 
  def self.adjust(order)
    order.line_items.each do |line_item|
      variant = line_item.variant
      quantity = line_item.quantity
      # retrieve the requested number of on hand units (or as many as possible) - note: optimistic locking used here
      on_hand = self.find_by_status(variant, quantity, InventoryUnit::Status::ON_HAND)
      # mark all of these units as sold and associate them with this order 
      on_hand.each do |unit|
        unit.update_attributes(:status => InventoryUnit::Status::SOLD, :order => order)
      end
      # right now we always allow back ordering
      backorder = quantity - on_hand.size
      backorder.times do 
        self.create(:variant => variant, :status => InventoryUnit::Status::BACK_ORDERED, :order => order)
      end
    end
  end
  
  # find the specified quantity of units with the specified status
  def self.find_by_status(variant, quantity, status)
    variant.inventory_units.find(:all, 
                                 :conditions => ['status = ? ', status], 
                                 :limit => quantity)
  end 
  
end