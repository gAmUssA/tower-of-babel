# Requirements Document

## Introduction

The analytics dashboard is unable to display the userId field for orders, showing "N/A" instead of the actual user identifier. This occurs because of a type mismatch between the Avro schema definition (string), the Kotlin service implementation (String), and the TypeScript analytics service (number). The TypeScript service attempts to parse the string userId as an integer, which fails for non-numeric user identifiers like "user-123", resulting in NaN values that the UI treats as missing data.

## Glossary

- **Analytics Dashboard**: The web-based UI that displays order information and statistics
- **Avro Schema**: The schema definition that specifies userId as a string type
- **TypeScript Order Model**: The data model in the analytics-api service that currently expects userId as a number
- **Avro Consumer**: The service component that deserializes Avro messages and converts them to Order objects
- **Order Service**: The Kotlin-based service that produces order events with string-based userId values

## Requirements

### Requirement 1

**User Story:** As a business analyst viewing the analytics dashboard, I want to see the userId for each order, so that I can identify which customers are placing orders

#### Acceptance Criteria

1. WHEN the Analytics Dashboard receives an order event with a userId field, THE Analytics Dashboard SHALL display the userId value in the Recent Orders table
2. WHEN the userId contains non-numeric characters (such as "user-123"), THE Analytics Dashboard SHALL display the complete userId string without modification
3. THE TypeScript Order Model SHALL define userId as a string type to match the Avro schema definition
4. THE Avro Consumer SHALL preserve the userId value as a string without attempting numeric conversion

### Requirement 2

**User Story:** As a developer, I want the TypeScript data models to match the Avro schema definitions, so that data integrity is maintained across service boundaries

#### Acceptance Criteria

1. THE TypeScript Order Model SHALL use the same data type for userId as specified in the Avro schema
2. THE Avro Consumer SHALL not perform type conversions that are inconsistent with the schema definition
3. WHEN processing an Avro message, THE Avro Consumer SHALL extract the userId field directly as a string
4. THE Analytics Dashboard SHALL correctly count unique users by treating userId as a string identifier
