# {{PROJECT_NAME}} iOS - AI Coding Assistant Rules

## Project Type: iOS Application
This is an iOS project written in Swift. ALWAYS respect the iOS development patterns and Swift conventions found in this specific codebase.

## Architecture Rules

### MUST Follow iOS Patterns
- USE the same architectural pattern found in the project (MVC/MVVM/VIPER/etc.)
- FOLLOW existing dependency injection patterns
- RESPECT the existing navigation patterns (UINavigationController/SwiftUI Navigation/etc.)
- MAINTAIN the existing data flow patterns

### Swift Code Style
- FOLLOW the existing naming conventions for classes, functions, and variables
- USE the same access control patterns found in existing code
- RESPECT existing protocol and extension usage patterns
- MAINTAIN consistent indentation and formatting

## UI Development Rules
- USE the same UI framework found in the project (UIKit/SwiftUI)
- FOLLOW existing layout patterns and constraints
- RESPECT existing color schemes and design patterns
- MAINTAIN consistent spacing and styling

## Data Management
- USE the same data persistence approach found in the codebase
- FOLLOW existing networking patterns and error handling
- RESPECT existing model object patterns and relationships
- MAINTAIN consistent data validation patterns

## Testing Requirements
- WRITE unit tests using the same framework found in existing test files
- FOLLOW existing test organization and naming patterns
- USE the same mocking/stubbing approaches found in tests
- RUN tests before committing: [INSERT ACTUAL TEST COMMAND]

## Dependencies and Package Management
- USE the same dependency management approach (CocoaPods/SPM/Carthage)
- FOLLOW existing third-party library usage patterns
- NEVER add new dependencies without checking existing alternatives
- RESPECT existing version constraints

## Build and Development
- BUILD: [INSERT ACTUAL BUILD COMMAND]
- TEST: [INSERT ACTUAL TEST COMMAND]
- ARCHIVE: [INSERT ACTUAL ARCHIVE COMMAND]
- LINT: [INSERT ACTUAL LINT COMMAND IF SWIFTLINT USED]

## iOS-Specific Rules
- RESPECT existing Info.plist configuration patterns
- FOLLOW existing entitlements and capability patterns
- MAINTAIN existing deployment target and iOS version support
- RESPECT existing localization patterns if present

## Security and Privacy
- FOLLOW existing keychain usage patterns
- RESPECT existing privacy permission request patterns
- MAINTAIN existing data protection and encryption approaches
- FOLLOW existing certificate and provisioning patterns

This template should be populated with ACTUAL patterns found in the analyzed iOS codebase.