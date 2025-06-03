import { Order, OrderAnalytics } from '../models/order';

/**
 * Service for analytics calculations and data storage
 */
export class AnalyticsService {
  private orders: Order[] = [];
  private maxOrdersToStore = 100;
  
  /**
   * Add an order to the analytics store
   */
  addOrder(order: Order): void {
    // Add to the beginning for most recent first
    this.orders.unshift(order);
    
    // Limit the number of orders stored
    if (this.orders.length > this.maxOrdersToStore) {
      this.orders = this.orders.slice(0, this.maxOrdersToStore);
    }
  }
  
  /**
   * Get analytics data
   */
  getAnalytics(): OrderAnalytics {
    const ordersByStatus: Record<string, number> = {};
    let totalAmount = 0;
    
    // Calculate statistics
    for (const order of this.orders) {
      // Increment count for this status
      const status = order.status || 'UNKNOWN';
      ordersByStatus[status] = (ordersByStatus[status] || 0) + 1;
      
      // Add to total amount - intentional type inconsistency issues here
      // The amount is stored as a string but we need to convert to number
      try {
        // This can fail if the amount is not a valid number string
        const amount = parseFloat(order.amount);
        if (!isNaN(amount)) {
          totalAmount += amount;
        }
      } catch (error: any) {
        console.error(`Error parsing amount for order ${order.orderId}: ${error.message || 'Unknown error'}`);
        console.error(error);
      }
    }
    
    return {
      totalOrders: this.orders.length,
      totalAmount,
      ordersByStatus,
      recentOrders: this.orders.slice(0, 10) // Return only the 10 most recent orders
    };
  }
  
  /**
   * Get recent orders
   */
  getRecentOrders(limit: number = 10): Order[] {
    return this.orders.slice(0, limit);
  }
  
  /**
   * Clear all stored orders
   */
  clearOrders(): void {
    this.orders = [];
  }
}
