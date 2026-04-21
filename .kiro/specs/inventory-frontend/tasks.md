# Implementation Plan

- [x] 1. Create HTML structure and basic layout
  - Create `services/inventory-service/src/public/dashboard.html` file
  - Implement semantic HTML structure with header, main sections, and footer
  - Add meta tags for responsive viewport and character encoding
  - Create container divs for health status, filters, inventory table, and errors sections
  - _Requirements: 1.1, 5.1, 5.5, 6.1_

- [x] 2. Implement inline CSS styling
  - [x] 2.1 Define CSS variables for color palette and spacing
    - Create CSS custom properties for primary colors, backgrounds, borders, and spacing
    - Define typography scale (font sizes, weights, line heights)
    - _Requirements: 5.2, 5.3, 5.4_
  
  - [x] 2.2 Style the header and health status section
    - Style the dashboard header with title and subtitle
    - Create card-based layout for consumer status indicators
    - Implement color-coded status badges (green for connected, red for disconnected)
    - Add error count styling
    - _Requirements: 3.2, 5.1, 5.5_
  
  - [x] 2.3 Style filter controls and inventory table
    - Create button group styling for filter controls with active state
    - Implement responsive table layout with proper column widths
    - Add row hover effects and alternating row colors
    - Style empty state message
    - _Requirements: 2.3, 5.1, 5.2, 5.3_
  
  - [x] 2.4 Style errors section and implement responsive design
    - Create collapsible panel styling for errors section
    - Implement mobile-responsive layout with media queries
    - Add loading spinner and connection error banner styles
    - _Requirements: 4.5, 5.1, 7.1_

- [x] 3. Implement JavaScript API client and state management
  - [x] 3.1 Create API client module
    - Implement `fetchInventory()` function with optional source filter parameter
    - Implement `fetchHealth()` function to get consumer status
    - Implement `fetchErrors()` function to get error statistics
    - Add error handling with try-catch blocks for all API calls
    - _Requirements: 1.1, 3.1, 4.1, 7.1, 7.4_
  
  - [x] 3.2 Implement state management
    - Create global state object to store inventory, health, errors, and UI state
    - Implement state update functions that trigger re-renders
    - Add filter state management (all, json, avro)
    - Track last update timestamp and connection status
    - _Requirements: 2.1, 2.5, 7.3_

- [x] 4. Implement DOM rendering functions
  - [x] 4.1 Create inventory table renderer
    - Implement function to generate table rows from inventory data
    - Add conditional rendering for empty state message
    - Display all required fields (order ID, product ID, quantity, user ID, status, source)
    - Implement row highlighting based on source type
    - Update item count display
    - _Requirements: 1.1, 1.2, 1.4, 1.5_
  
  - [x] 4.2 Create health status renderer
    - Implement function to render consumer status cards
    - Display connection status with color-coded indicators
    - Show error counts for both consumers
    - Update last refresh timestamp
    - _Requirements: 3.1, 3.2, 3.3, 3.5_
  
  - [x] 4.3 Create errors section renderer
    - Implement function to render error messages for both consumers
    - Display up to 10 most recent errors
    - Show "No errors" message when error list is empty
    - Implement expand/collapse functionality
    - _Requirements: 4.1, 4.2, 4.3, 4.4, 4.5_

- [x] 5. Implement filtering and interaction logic
  - [x] 5.1 Add filter button event handlers
    - Attach click event listeners to filter buttons
    - Update active filter state on button click
    - Apply active styling to selected filter button
    - Trigger data refresh with selected filter
    - _Requirements: 2.1, 2.2, 2.3_
  
  - [x] 5.2 Implement filtered data display
    - Filter inventory items based on selected source
    - Update item count to reflect filtered results
    - Maintain filter selection across auto-refreshes
    - _Requirements: 2.1, 2.4, 2.5_

- [x] 6. Implement auto-refresh mechanism
  - Create `refreshData()` function that fetches all data concurrently using Promise.all
  - Set up interval timer to call refresh function every 2 seconds
  - Update state and trigger re-render on successful data fetch
  - Handle connection errors gracefully without stopping refresh cycle
  - Update last update timestamp on each successful refresh
  - _Requirements: 1.3, 3.4, 7.1, 7.2, 7.3_

- [x] 7. Add error handling and user feedback
  - Implement connection error banner that displays when API is unreachable
  - Add console logging for all API errors
  - Implement loading state during initial data fetch
  - Ensure UI remains responsive during failed API calls
  - Display last successful data when new requests fail
  - _Requirements: 7.1, 7.2, 7.3, 7.4, 7.5_

- [x] 8. Integrate frontend with FastAPI backend
  - Add static file route to serve dashboard.html at `/dashboard` endpoint
  - Import FileResponse from fastapi.responses in main.py
  - Test that dashboard is accessible at http://localhost:9000/dashboard
  - Verify CORS settings allow frontend to call API endpoints
  - _Requirements: 6.5_

- [ ] 9. Perform integration testing and validation
  - [ ] 9.1 Test initial load and data display
    - Start Inventory Service and navigate to dashboard
    - Verify all sections render with correct data
    - Confirm auto-refresh updates data every 2 seconds
    - _Requirements: 1.1, 1.3, 3.1_
  
  - [ ] 9.2 Test filtering functionality
    - Click each filter button (All, JSON, Avro)
    - Verify filtered results display correctly
    - Confirm item count updates appropriately
    - Test that filter persists across refreshes
    - _Requirements: 2.1, 2.2, 2.3, 2.4, 2.5_
  
  - [ ] 9.3 Test error handling scenarios
    - Stop Kafka to trigger consumer disconnection
    - Verify health status shows disconnected state
    - Send malformed messages to trigger deserialization errors
    - Confirm errors appear in errors section
    - Stop backend and verify connection error handling
    - _Requirements: 3.2, 4.1, 4.2, 7.1, 7.2_
  
  - [ ]* 9.4 Test responsive design and browser compatibility
    - Test dashboard on mobile viewport (< 768px width)
    - Test on desktop viewport (> 768px width)
    - Verify layout adapts appropriately
    - Test in Chrome, Firefox, and Safari browsers
    - _Requirements: 5.1, 5.2, 5.3_
