/**
 * Order model for Analytics API
 * Intentionally has type inconsistencies with the Java model for demo purposes
 */

export interface Order {
  // Intentional type inconsistency: orderId is UUID in Java but string here
  orderId: string;
  
  // Intentional type inconsistency: userId is string in Java but number here
  userId: number;
  
  // Intentional type inconsistency: amount is BigDecimal in Java but string here
  amount: string;
  
  status: string;
  
  // Intentional type inconsistency: items is List<OrderItem> in Java but any[] here
  items: any[];
  
  // Intentional type inconsistency: createdAt is Instant in Java but string here
  createdAt: string;
  
  // Source of the message (json, java, avro)
  source?: string;
}

export interface OrderItem {
  // Intentional type inconsistency: productId is string in Java but number here
  productId: number;
  
  quantity: number;
  
  // Intentional type inconsistency: price is BigDecimal in Java but number here
  price: number;
}

export interface OrderAnalytics {
  totalOrders: number;
  totalAmount: number;
  ordersByStatus: Record<string, number>;
  recentOrders: Order[];
}
