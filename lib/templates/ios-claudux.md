# {{PROJECT_NAME}} iOS - Coding Patterns & Conventions

## Architecture Patterns

### SwiftUI & State Management
- **@Observable ViewModels**: Use `@Observable` for all ViewModels instead of ObservableObject
- **State Flow**: View → ViewModel → Manager → Data Layer
- **Previews**: Always include SwiftUI previews with mock/test data
- **Environment Values**: Use for dependency injection in SwiftUI

### Dependency Injection
- **Protocol-Based**: Create `BaseXManager` protocols for testability
- **Concrete Implementations**: Implement `XManager` classes
- **Constructor Injection**: Pass dependencies through initializers
- **Environment Pattern**: Use SwiftUI environment for view dependencies

```swift
// Example Pattern
protocol BaseUserManager {
    func getCurrentUser() async -> User?
}

class UserManager: BaseUserManager {
    private let store: UserDefaultsStore
    private let cloudKit: CloudKitManager
    
    init(store: UserDefaultsStore, cloudKit: CloudKitManager) {
        self.store = store
        self.cloudKit = cloudKit
    }
}
```

## Code Organization

### Directory Structure
- **Models/**: SwiftData entities, core data models
- **Managers/**: Business logic layer with protocol-based DI
- **Extensions/**: Utility extensions organized by type
- **UI/**: Reusable UI components and modifiers
- **UseCases/**: Specific business use cases

### Naming Conventions
- **Managers**: `UserManager`, `ReceiptManager` (concrete implementations)
- **Protocols**: `BaseUserManager`, `BaseReceiptManager` (abstract interfaces)
- **ViewModels**: `ReceiptListViewModel`, `ProfileViewModel`
- **Views**: `ReceiptDetailView`, `ParticipantRowView`

## Data & Persistence

### SwiftData Patterns
- **@Model entities** with proper relationships
- **CloudKit sync** with `@Attribute(.unique)` for stable identifiers
- **Migration strategies** for schema changes
- **Query patterns** with `@Query` and FetchDescriptor

### CloudKit Integration
- **CKRecord mapping** for custom sync logic
- **Conflict resolution** strategies
- **Offline-first** design with local caching
- **User defaults** for app state and preferences

## Error Handling

### Async/Await Patterns
- **Structured concurrency** with async/await
- **Actor isolation** for thread safety
- **TaskGroup** for concurrent operations
- **Cancellation** support with Task.isCancelled

### Error Types
- **Domain-specific errors** (NetworkError, DataError)
- **User-facing messages** with localized descriptions
- **Logging strategies** for debugging
- **Graceful degradation** for network failures

## Testing Strategy

### Unit Testing
- **Protocol mocking** for dependency injection
- **Test data factories** for consistent test setup
- **Async testing** with async/await patterns
- **XCTest expectations** for asynchronous operations

### UI Testing
- **Accessibility identifiers** for element selection
- **Page Object Model** for maintainable UI tests
- **Snapshot testing** for visual regression detection
- **Test data isolation** between test runs

## Performance Considerations

### SwiftUI Performance
- **@Observable optimization** over ObservableObject
- **View identity** with proper `id` modifiers
- **Lazy loading** for large lists and data sets
- **Image caching** and compression strategies

### Memory Management
- **Weak references** for delegate patterns
- **Actor isolation** to prevent data races
- **Resource cleanup** in deinit methods
- **Background processing** for heavy operations

## Security & Privacy

### Data Protection
- **Keychain storage** for sensitive data
- **App Transport Security** for network requests
- **Data encryption** for local storage
- **User consent** for data collection

### Privacy Patterns
- **Permission requests** with clear user messaging
- **Data minimization** principles
- **Opt-out mechanisms** for analytics
- **GDPR compliance** considerations

## Common Patterns & Utilities

### Extensions
- **Foundation extensions** (String, Array, Date)
- **SwiftUI modifiers** for consistent styling
- **Color and Font** theme management
- **Formatters** for currency, dates, numbers

### Reactive Patterns
- **Combine publishers** for data streams
- **NotificationCenter** for decoupled communication
- **Property wrappers** for common behaviors
- **State machines** for complex flows

---

*This document should be updated as the codebase evolves and new patterns emerge.*