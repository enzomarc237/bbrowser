# Database Schema & Persistence Specification

## 1. Overview

This track establishes a comprehensive database schema and persistence system for the browser project. The system uses SQLite for structured data (bookmarks, history, preferences) and Hive for fast key-value storage (session data, cache), following conductor workflow requirements with proper migration support and performance optimization.

## 2. Functional Requirements

### FR1: Database Infrastructure
- The database system shall support SQLite for structured data and Hive for key-value storage
- Schema versioning shall be implemented with automatic migration on app startup
- Database connection management shall include pooling and error recovery
- Data validation and integrity checks shall be enforced at the database level
- Backup and restore functionality shall be provided for user data

### FR2: Bookmark Management
- Bookmarks table shall store title, URL, favicon, creation date, and folder association
- Bookmark folders shall support hierarchical organization with parent-child relationships
- Bookmark import/export shall support JSON format with validation
- Bookmark search shall provide full-text search capabilities
- Bookmark deduplication shall prevent duplicate entries

### FR3: History Management
- History table shall track URL, title, visit count, and last visited timestamp
- History cleanup shall be configurable with automatic removal of old entries
- Most-visited sites shall be easily accessible for quick navigation
- History search shall support partial URL and title matching
- History privacy shall include option to clear specific entries or all history

### FR4: User Preferences & Settings
- User preferences table shall store key-value pairs with type validation
- Settings import/export shall support JSON format with versioning
- Default settings shall be applied on first launch and user preference reset
- Settings changes shall trigger immediate UI updates through BLoC integration
- Sensitive settings shall be encrypted at rest

### FR5: Tab & Session Management
- Tab state shall persist across app restarts with session restoration
- Session management shall handle multiple windows and tab groups
- Tab session data shall include URL, title, favicon, and scroll position
- Session backup shall occur automatically with configurable frequency
- Session recovery shall handle corrupted or missing session data gracefully

## 3. Non-Functional Requirements

- **NFR1: Performance:** Database queries shall complete within 100ms for typical operations
- **NFR2: Scalability:** System shall handle 10,000+ bookmarks and 50,000+ history entries
- **NFR3: Reliability:** Database operations shall have 99.9% success rate with proper error handling
- **NFR4: Security:** Sensitive data shall be encrypted using platform-appropriate encryption
- **NFR5: Compatibility:** Database schema shall support backward compatibility for app updates

## 4. Database Schema Design

### 4.1 Core Tables

**bookmarks table:**
- id (TEXT, PRIMARY KEY)
- title (TEXT, NOT NULL)
- url (TEXT, NOT NULL)
- favicon (TEXT, nullable)
- folder_id (TEXT, nullable, FOREIGN KEY)
- created_at (TIMESTAMP, DEFAULT CURRENT_TIMESTAMP)
- updated_at (TIMESTAMP, DEFAULT CURRENT_TIMESTAMP)
- sort_order (INTEGER, DEFAULT 0)

**folders table:**
- id (TEXT, PRIMARY KEY)
- name (TEXT, NOT NULL)
- parent_id (TEXT, nullable, FOREIGN KEY)
- created_at (TIMESTAMP, DEFAULT CURRENT_TIMESTAMP)
- sort_order (INTEGER, DEFAULT 0)

**history table:**
- id (TEXT, PRIMARY KEY)
- url (TEXT, NOT NULL)
- title (TEXT, nullable)
- favicon (TEXT, nullable)
- visit_count (INTEGER, DEFAULT 1)
- last_visited (TIMESTAMP, DEFAULT CURRENT_TIMESTAMP)
- created_at (TIMESTAMP, DEFAULT CURRENT_TIMESTAMP)

**user_preferences table:**
- key (TEXT, PRIMARY KEY)
- value (TEXT, NOT NULL)
- updated_at (TIMESTAMP, DEFAULT CURRENT_TIMESTAMP)

### 4.2 Indexes & Constraints
- Indexes on frequently queried columns (url, folder_id, visit_count, last_visited)
- Unique constraints where appropriate (bookmark-url-folder combinations)
- Foreign key constraints with CASCADE DELETE for folders/bookmarks
- Data validation constraints for URL format and date ranges

## 5. Repository Pattern Implementation

### 5.1 Repository Structure
```
lib/repositories/
├── base_repository.dart
├── bookmark_repository.dart
├── history_repository.dart
├── preference_repository.dart
├── folder_repository.dart
└── tab_repository.dart
```

### 5.2 Repository Operations
- CRUD operations with proper error handling
- Batch operations for bulk data changes
- Search and filtering capabilities
- Import/export functionality
- Data validation and sanitization

### 5.3 Database Helper
- Singleton DatabaseHelper class
- Connection pooling and transaction management
- Migration scripts for schema versioning
- Error handling and recovery strategies

## 6. Quality Gates

### 6.1 Database Implementation Requirements
- All database operations must have >80% test coverage
- Database queries must meet performance benchmarks
- Data integrity must be maintained across all operations
- Migration scripts must be tested and validated
- Security measures must be implemented for sensitive data

### 6.2 Testing Requirements
- Unit tests for all repository operations
- Integration tests with real database
- Migration testing across versions
- Performance testing with large datasets
- Data integrity verification tests

### 6.3 Performance Requirements
- Database initialization under 2 seconds
- Query response time under 100ms for typical operations
- Bulk operations under 5 seconds for 1000 records
- Memory usage optimization for large datasets
- Efficient indexing strategy for performance

## 7. Integration Points

### 7.1 BLoC Integration
- Repository injection into BLoCs via dependency injection
- State management integration for data loading/errors
- Real-time updates through stream subscriptions
- Proper error handling and user feedback

### 7.2 Migration System
- Version-controlled migration scripts
- Automatic migration on app startup
- Rollback capabilities for failed migrations
- Migration testing in CI/CD pipeline

### 7.3 Backup & Sync
- Export/import functionality for user data
- Optional cloud sync for user preferences
- Conflict resolution for sync conflicts
- Local-first design with sync when online

## 8. Acceptance Criteria

- A developer can create new database entities following established patterns
- All database operations have comprehensive test coverage (>80%)
- Database performance meets benchmarks for typical user scenarios
- Data migration works correctly across app versions
- Backup and restore functionality preserves all user data
- Security measures protect sensitive user information
- Performance scales appropriately with large datasets

## 9. Out of Scope

- Real-time database synchronization (covered in sync service track)
- Advanced caching strategies beyond Hive (future optimization track)
- Cross-platform database compatibility (macOS-specific implementation)
- Advanced analytics and usage tracking (separate analytics track)
- Database clustering or distributed storage (future scalability track)