# Requirements Document

## Introduction

This document defines the requirements for a simple web-based frontend for the Inventory Service. The frontend will provide a user-friendly interface to monitor inventory status, view Kafka message consumption, and track errors in real-time. This frontend is part of the Tower of Babel demo project and should maintain the educational focus while providing clear visibility into the system's behavior.

## Glossary

- **Inventory Service**: The Python FastAPI backend service that consumes Kafka messages and tracks inventory status
- **Frontend**: The web-based user interface that displays inventory data and system status
- **Kafka Consumer**: Background process that reads messages from Kafka topics
- **JSON Consumer**: Consumer that processes messages without Schema Registry (demonstrates serialization issues)
- **Avro Consumer**: Consumer that uses Schema Registry for proper deserialization
- **Order Event**: Kafka message containing order information (orderId, productId, quantity, userId)
- **Dashboard**: The main view showing inventory items and system health

## Requirements

### Requirement 1

**User Story:** As a demo presenter, I want to view all inventory items in a clear table format, so that I can show the audience what data the service has consumed from Kafka

#### Acceptance Criteria

1. WHEN the Frontend loads, THE Frontend SHALL display a table containing all inventory items from the Inventory Service
2. THE Frontend SHALL display the following fields for each inventory item: order ID, product ID, quantity, user ID, status, and source
3. THE Frontend SHALL refresh the inventory data automatically every 2 seconds to show real-time updates
4. THE Frontend SHALL indicate when no inventory items exist with a clear message
5. THE Frontend SHALL display the total count of inventory items at the top of the table

### Requirement 2

**User Story:** As a demo presenter, I want to filter inventory items by their source (JSON vs Avro), so that I can demonstrate the difference between broken and working consumers

#### Acceptance Criteria

1. THE Frontend SHALL provide filter buttons for "All", "JSON", and "Avro" sources
2. WHEN a user clicks a filter button, THE Frontend SHALL display only inventory items matching the selected source
3. THE Frontend SHALL visually highlight the currently active filter
4. THE Frontend SHALL update the item count to reflect the filtered results
5. THE Frontend SHALL maintain the selected filter across automatic data refreshes

### Requirement 3

**User Story:** As a demo presenter, I want to see system health status at a glance, so that I can quickly verify that Kafka consumers are running properly

#### Acceptance Criteria

1. THE Frontend SHALL display a health status section showing connection status for JSON and Avro consumers
2. THE Frontend SHALL use color coding (green for connected, red for disconnected) to indicate consumer status
3. THE Frontend SHALL display error counts for both JSON and Avro consumers
4. THE Frontend SHALL refresh health status automatically every 2 seconds
5. THE Frontend SHALL display the last update timestamp for health information

### Requirement 4

**User Story:** As a demo presenter, I want to view error details when deserialization fails, so that I can explain to the audience what went wrong

#### Acceptance Criteria

1. THE Frontend SHALL display an errors section showing recent deserialization errors
2. WHEN errors exist, THE Frontend SHALL display up to 10 most recent error messages
3. THE Frontend SHALL clearly separate JSON consumer errors from Avro consumer errors
4. THE Frontend SHALL display a "No errors" message when no errors have occurred
5. THE Frontend SHALL allow expanding/collapsing the errors section to save screen space

### Requirement 5

**User Story:** As a demo presenter, I want a clean and professional interface that matches the demo's educational purpose, so that the audience can focus on the concepts being demonstrated

#### Acceptance Criteria

1. THE Frontend SHALL use a responsive layout that works on different screen sizes
2. THE Frontend SHALL use clear typography with adequate font sizes for presentation visibility
3. THE Frontend SHALL use consistent spacing and alignment throughout the interface
4. THE Frontend SHALL use a color scheme that provides good contrast and readability
5. THE Frontend SHALL include the service name and demo context in the page header

### Requirement 6

**User Story:** As a developer, I want the frontend to be a single HTML file with inline CSS and JavaScript, so that it's easy to deploy and maintain without additional build steps

#### Acceptance Criteria

1. THE Frontend SHALL be implemented as a single HTML file
2. THE Frontend SHALL include all CSS styles inline within a style tag
3. THE Frontend SHALL include all JavaScript code inline within a script tag
4. THE Frontend SHALL not require any external dependencies or build tools
5. THE Frontend SHALL be served as a static file from the FastAPI backend

### Requirement 7

**User Story:** As a demo presenter, I want the frontend to handle API errors gracefully, so that temporary connectivity issues don't disrupt the presentation

#### Acceptance Criteria

1. IF the Inventory Service API is unreachable, THEN THE Frontend SHALL display a connection error message
2. THE Frontend SHALL continue attempting to fetch data after connection errors
3. THE Frontend SHALL display the last successfully fetched data while retrying failed requests
4. THE Frontend SHALL log API errors to the browser console for debugging
5. THE Frontend SHALL not freeze or become unresponsive when API calls fail
