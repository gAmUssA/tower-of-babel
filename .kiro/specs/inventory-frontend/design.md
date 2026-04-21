# Design Document: Inventory Service Frontend

## Overview

The Inventory Service Frontend is a single-page web application that provides real-time visibility into the inventory service's Kafka message consumption. Built as a self-contained HTML file with inline CSS and JavaScript, it fetches data from the FastAPI backend and displays inventory items, system health, and error information in an intuitive dashboard layout.

The design prioritizes simplicity, clarity, and ease of deployment while maintaining professional presentation quality suitable for live demos.

## Architecture

### Component Structure

```
┌─────────────────────────────────────────────────────────┐
│                    Browser (Client)                      │
│  ┌───────────────────────────────────────────────────┐  │
│  │           dashboard.html (Single File)            │  │
│  │  ┌─────────────────────────────────────────────┐  │  │
│  │  │  HTML Structure                             │  │  │
│  │  │  - Header                                   │  │  │
│  │  │  - Health Status Section                    │  │  │
│  │  │  - Filter Controls                          │  │  │
│  │  │  - Inventory Table                          │  │  │
│  │  │  - Errors Section (Collapsible)             │  │  │
│  │  └─────────────────────────────────────────────┘  │  │
│  │  ┌─────────────────────────────────────────────┐  │  │
│  │  │  CSS Styles (Inline)                        │  │  │
│  │  │  - Layout & Grid                            │  │  │
│  │  │  - Typography                               │  │  │
│  │  │  - Color Scheme                             │  │  │
│  │  │  - Responsive Design                        │  │  │
│  │  └─────────────────────────────────────────────┘  │  │
│  │  ┌─────────────────────────────────────────────┐  │  │
│  │  │  JavaScript (Inline)                        │  │  │
│  │  │  - API Client                               │  │  │
│  │  │  - State Management                         │  │  │
│  │  │  - DOM Manipulation                         │  │  │
│  │  │  - Auto-refresh Logic                       │  │  │
│  │  └─────────────────────────────────────────────┘  │  │
│  └───────────────────────────────────────────────────┘  │
└─────────────────────────────────────────────────────────┘
                          │
                          │ HTTP/REST API
                          ▼
┌─────────────────────────────────────────────────────────┐
│              FastAPI Backend (Port 9000)                 │
│  ┌───────────────────────────────────────────────────┐  │
│  │  Static File Serving                              │  │
│  │  GET /dashboard → dashboard.html                  │  │
│  └───────────────────────────────────────────────────┘  │
│  ┌───────────────────────────────────────────────────┐  │
│  │  REST API Endpoints                               │  │
│  │  GET /health                                      │  │
│  │  GET /inventory?source={filter}                   │  │
│  │  GET /errors                                      │  │
│  └───────────────────────────────────────────────────┘  │
└─────────────────────────────────────────────────────────┘
```

## Components and Interfaces

### 1. HTML Structure

**Header Section**
- Service title: "Inventory Service Dashboard"
- Subtitle: "Tower of Babel Demo - Real-time Kafka Message Monitoring"
- Last updated timestamp

**Health Status Section**
- Consumer status cards (JSON and Avro)
- Connection status indicators (colored badges)
- Error count displays
- Refresh indicator

**Filter Controls**
- Three buttons: "All", "JSON", "Avro"
- Active state styling
- Item count display

**Inventory Table**
- Columns: Order ID, Product ID, Quantity, User ID, Status, Source
- Responsive table layout
- Empty state message
- Row highlighting based on source

**Errors Section**
- Collapsible panel
- Separate sections for JSON and Avro errors
- Error message list (max 10 items)
- Timestamp for each error
- Empty state message

### 2. CSS Design System

**Color Palette**
```css
Primary Background: #f5f7fa
Card Background: #ffffff
Border Color: #e1e8ed
Text Primary: #14171a
Text Secondary: #657786
Success Green: #17bf63
Error Red: #e0245e
Warning Orange: #ff9800
Info Blue: #1da1f2
```

**Typography**
- Font Family: -apple-system, BlinkMacSystemFont, "Segoe UI", Roboto, sans-serif
- Header: 24px bold
- Subheader: 18px semi-bold
- Body: 14px regular
- Small: 12px regular

**Layout**
- Container max-width: 1200px
- Card padding: 20px
- Grid gap: 16px
- Border radius: 8px
- Box shadow: 0 2px 4px rgba(0,0,0,0.1)

**Responsive Breakpoints**
- Desktop: > 768px (multi-column layout)
- Mobile: ≤ 768px (single-column stack)

### 3. JavaScript Architecture

**State Management**
```javascript
const state = {
  inventory: [],
  health: null,
  errors: null,
  activeFilter: 'all',
  lastUpdate: null,
  isLoading: false,
  connectionError: false
};
```

**API Client Module**
```javascript
const API = {
  baseURL: window.location.origin,
  
  async fetchInventory(source = null) {
    const url = source ? `/inventory?source=${source}` : '/inventory';
    return await fetch(url).then(r => r.json());
  },
  
  async fetchHealth() {
    return await fetch('/health').then(r => r.json());
  },
  
  async fetchErrors() {
    return await fetch('/errors').then(r => r.json());
  }
};
```

**Rendering Module**
```javascript
const Renderer = {
  renderInventoryTable(items) { /* ... */ },
  renderHealthStatus(health) { /* ... */ },
  renderErrors(errors) { /* ... */ },
  updateTimestamp() { /* ... */ }
};
```

**Auto-refresh Logic**
```javascript
const AUTO_REFRESH_INTERVAL = 2000; // 2 seconds

async function refreshData() {
  try {
    const [inventory, health, errors] = await Promise.all([
      API.fetchInventory(state.activeFilter !== 'all' ? state.activeFilter : null),
      API.fetchHealth(),
      API.fetchErrors()
    ]);
    
    state.inventory = inventory;
    state.health = health;
    state.errors = errors;
    state.lastUpdate = new Date();
    state.connectionError = false;
    
    Renderer.renderAll();
  } catch (error) {
    console.error('Failed to fetch data:', error);
    state.connectionError = true;
    Renderer.renderConnectionError();
  }
}

setInterval(refreshData, AUTO_REFRESH_INTERVAL);
```

## Data Models

### Inventory Item
```typescript
interface InventoryItem {
  order_id: string;
  product_id: string;
  quantity: number;
  user_id: string;
  status: string;
  source: 'json' | 'avro' | 'java';
}
```

### Health Status
```typescript
interface HealthStatus {
  status: string;
  kafka: 'connected' | 'disconnected';
  avro_kafka: 'connected' | 'disconnected';
  error_count: {
    json: number;
    avro: number;
  };
}
```

### Error Stats
```typescript
interface ErrorStats {
  json_consumer: {
    error_count: number;
    last_errors: string[];
  };
  avro_consumer: {
    error_count: number;
    last_errors: string[];
  };
}
```

## Error Handling

### API Error Handling
1. **Network Errors**: Display connection error banner, retry on next interval
2. **HTTP Errors**: Log to console, show last successful data
3. **Parse Errors**: Log to console, skip rendering that section
4. **Timeout**: 5-second timeout per request, then fail gracefully

### User Feedback
- Loading spinner during initial load
- Connection error banner when API is unreachable
- Empty state messages when no data exists
- Console logging for debugging

## Testing Strategy

### Manual Testing Checklist
1. **Initial Load**: Verify all sections render correctly
2. **Auto-refresh**: Confirm data updates every 2 seconds
3. **Filtering**: Test all three filter options (All, JSON, Avro)
4. **Error Display**: Trigger errors and verify they appear
5. **Responsive Design**: Test on mobile and desktop viewports
6. **Connection Loss**: Stop backend and verify error handling
7. **Empty States**: Clear inventory and verify empty messages
8. **Browser Compatibility**: Test in Chrome, Firefox, Safari

### Integration Testing
1. Start Inventory Service backend
2. Navigate to http://localhost:9000/dashboard
3. Verify initial data load
4. Trigger order events via Order Service
5. Verify new items appear in real-time
6. Test filter functionality
7. Verify health status updates

### Error Scenario Testing
1. **No Kafka Connection**: Verify health status shows disconnected
2. **Deserialization Errors**: Send malformed messages, verify errors appear
3. **Backend Restart**: Stop/start backend, verify reconnection
4. **Empty Inventory**: Clear all data, verify empty state message

## Implementation Notes

### File Location
- Path: `services/inventory-service/src/public/dashboard.html`
- Served at: `http://localhost:9000/dashboard`

### FastAPI Integration
Add static file serving to `main.py`:
```python
from fastapi.responses import FileResponse
from fastapi.staticfiles import StaticFiles

@app.get("/dashboard")
async def serve_dashboard():
    return FileResponse("src/public/dashboard.html")
```

### Browser Compatibility
- Target: Modern browsers (Chrome 90+, Firefox 88+, Safari 14+)
- No polyfills needed (using native fetch, async/await)
- CSS Grid and Flexbox for layout

### Performance Considerations
- Single HTML file: ~15-20KB uncompressed
- No external dependencies: Zero network overhead
- Efficient DOM updates: Only re-render changed sections
- Debounced filter changes: Prevent excessive re-renders

## Visual Design Mockup

```
┌────────────────────────────────────────────────────────────┐
│  Inventory Service Dashboard                               │
│  Tower of Babel Demo - Real-time Kafka Message Monitoring │
│  Last updated: 2:34:56 PM                                  │
├────────────────────────────────────────────────────────────┤
│  ┌──────────────────┐  ┌──────────────────┐               │
│  │ JSON Consumer    │  │ Avro Consumer    │               │
│  │ ● Connected      │  │ ● Connected      │               │
│  │ Errors: 5        │  │ Errors: 0        │               │
│  └──────────────────┘  └──────────────────┘               │
├────────────────────────────────────────────────────────────┤
│  [All] [JSON] [Avro]                    Total Items: 12   │
├────────────────────────────────────────────────────────────┤
│  Order ID  │ Product │ Qty │ User ID │ Status │ Source    │
│  ─────────────────────────────────────────────────────────│
│  ORD-001   │ PROD-A  │  5  │ USR-123 │ active │ avro     │
│  ORD-002   │ PROD-B  │  3  │ USR-456 │ active │ json     │
│  ORD-003   │ PROD-C  │  2  │ USR-789 │ active │ avro     │
├────────────────────────────────────────────────────────────┤
│  ▼ Errors (5)                                              │
│  ┌────────────────────────────────────────────────────────┐│
│  │ JSON Consumer Errors:                                  ││
│  │ • Failed to deserialize: missing field 'userId'        ││
│  │ • Failed to deserialize: type mismatch on 'quantity'   ││
│  │                                                         ││
│  │ Avro Consumer Errors:                                  ││
│  │ • No errors                                            ││
│  └────────────────────────────────────────────────────────┘│
└────────────────────────────────────────────────────────────┘
```

## Future Enhancements (Out of Scope)

- Real-time WebSocket updates instead of polling
- Chart visualization of message throughput
- Message detail modal with full payload
- Export inventory data to CSV
- Dark mode theme toggle
- Advanced filtering (by date, status, etc.)
