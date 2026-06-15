# Requirements Document: Admin Management System

## Introduction

This document specifies requirements for the Admin Management System in Bazaar Suez, a Flutter/Firebase application. The system enables administrators to manage user reports, control accounts (craftsmen, stores, couriers), manage images, and view analytics dashboards. The system is designed for rapid implementation (one week) with a simple architecture (UI Pages → Services → Firestore) without over-engineering.

## Glossary

- **System**: The Admin Management System component within Bazaar Suez
- **Admin**: A user with administrator role verified via Firebase Custom Claims
- **Moderator**: A user with limited permissions to manage reports only
- **Craftsman**: A user providing handcraft or trade services
- **Store**: A business/market user account
- **Courier**: A delivery service provider user
- **Report**: A user complaint about a craftsman, store, or courier
- **Admin_Status**: The moderation state of a user account (pending, approved, rejected, suspended, banned, deleted)
- **Firestore**: Firebase Cloud Firestore database
- **FCM**: Firebase Cloud Messaging for push notifications
- **StreamBuilder**: Flutter widget for real-time Firestore data streams
- **Custom_Claims**: Firebase Authentication custom claims for role-based access

## Requirements

### Requirement 1: User Report Submission

**User Story:** As a regular user, I want to report problematic craftsmen, stores, or couriers, so that administrators can review and take action against inappropriate behavior.

#### Acceptance Criteria

1. WHEN a regular user submits a report, THE System SHALL create a report document in the user_reports collection with fields: type, reportedEntityId, reportedBy, reason, status=pending, and createdAt
2. WHEN a report is created, THE System SHALL validate that the reason field is not empty
3. WHEN a report is created, THE System SHALL validate that the reportedEntityId exists in the corresponding collection (craftsmen, markets, or courier_requests)
4. WHEN a report is successfully created, THE System SHALL trigger a Cloud Function to send an FCM notification to the admin topic
5. THE System SHALL allow reports for three entity types: craftsman, store, and courier

### Requirement 2: Admin Report Viewing

**User Story:** As an admin, I want to view all pending reports in a dedicated page, so that I can review user complaints efficiently.

#### Acceptance Criteria

1. THE System SHALL display a reports list page accessible only to admin and moderator roles
2. WHEN the reports page loads, THE System SHALL stream all user_reports with status=pending using StreamBuilder
3. FOR EACH report, THE System SHALL display the report type, reason, creation date, and reported entity information
4. WHEN a report is displayed, THE System SHALL show the count of total reports for the same reported entity
5. THE System SHALL order reports by createdAt in descending order (newest first)

### Requirement 3: Admin Report Resolution

**User Story:** As an admin, I want to resolve or dismiss reports, so that I can close investigated complaints.

#### Acceptance Criteria

1. WHEN an admin selects a report, THE System SHALL provide Resolve and Dismiss action buttons
2. WHEN an admin clicks Resolve, THE System SHALL require a resolution text input before submission
3. WHEN a resolution is submitted with non-empty text, THE System SHALL update the report with status=resolved, resolution text, and resolvedAt=current timestamp
4. WHEN an admin clicks Dismiss, THE System SHALL update the report with status=dismissed and resolvedAt=current timestamp
5. WHEN a report status changes to resolved or dismissed, THE System SHALL remove it from the pending reports list in real-time

### Requirement 4: Admin Authentication and Authorization

**User Story:** As the system, I want to verify admin roles using Firebase Custom Claims, so that only authorized users can access admin features.

#### Acceptance Criteria

1. WHEN a user attempts to access any admin page, THE System SHALL check Firebase Custom Claims for role=admin or role=moderator
2. IF a user lacks admin or moderator role, THEN THE System SHALL redirect to the home page and display an error message
3. THE System SHALL use Firebase Security Rules to enforce that only users with role=admin can read and write reports collection
4. THE System SHALL allow moderator role to read and write reports collection
5. WHEN admin authentication succeeds, THE System SHALL navigate to the admin dashboard

### Requirement 5: User Account Approval

**User Story:** As an admin, I want to approve pending craftsmen, stores, and couriers, so that verified users can access the platform.

#### Acceptance Criteria

1. WHEN an admin approves a user, THE System SHALL update the user document with adminStatus=approved
2. WHEN adminStatus is updated, THE System SHALL add a lastAdminAction object with fields: action=approve, by=adminUserId, at=current timestamp, and reason (empty for approval)
3. THE System SHALL apply the approval operation to all three user types: craftsmen, markets, and courier_requests collections
4. WHEN approval succeeds, THE System SHALL display a success message to the admin

### Requirement 6: User Account Rejection

**User Story:** As an admin, I want to reject user accounts with a reason, so that inappropriate accounts are denied platform access.

#### Acceptance Criteria

1. WHEN an admin rejects a user, THE System SHALL require a non-empty rejection reason
2. WHEN a rejection reason is provided, THE System SHALL update the user document with adminStatus=rejected
3. WHEN adminStatus is updated to rejected, THE System SHALL store the reason in lastAdminAction.reason
4. THE System SHALL apply rejection to craftsmen, markets, and courier_requests collections

### Requirement 7: User Account Suspension

**User Story:** As an admin, I want to temporarily suspend user accounts, so that problematic users are blocked from platform access without permanent deletion.

#### Acceptance Criteria

1. WHEN an admin suspends a user, THE System SHALL require a non-empty suspension reason
2. WHEN a suspension reason is provided, THE System SHALL update the user document with adminStatus=suspended
3. WHEN a user is suspended, THE System SHALL store the suspension reason in lastAdminAction.reason
4. THE System SHALL allow suspended users to be later activated or banned

### Requirement 8: User Account Ban

**User Story:** As an admin, I want to permanently ban user accounts, so that malicious users cannot access the platform.

#### Acceptance Criteria

1. WHEN an admin bans a user, THE System SHALL require a non-empty ban reason
2. WHEN a ban reason is provided, THE System SHALL update the user document with adminStatus=banned
3. WHEN a user is banned, THE System SHALL store the ban reason in lastAdminAction.reason
4. THE System SHALL prevent banned users from being approved or activated

### Requirement 9: User Account Deletion

**User Story:** As an admin, I want to soft-delete user accounts, so that deleted accounts can be restored if needed.

#### Acceptance Criteria

1. WHEN an admin deletes a user, THE System SHALL update the user document with adminStatus=deleted
2. WHEN a user is deleted, THE System SHALL add deletedAt=current timestamp and deletedBy=adminUserId fields
3. WHEN a user is deleted, THE System SHALL preserve all user data in Firestore (soft delete, not permanent deletion)
4. THE System SHALL exclude deleted users from default queries and lists
5. THE System SHALL allow admin to restore deleted accounts
6. WHEN a user is deleted, THE System SHALL update the users collection document to change role from 'craftsman' or 'store_owner' to 'user' (convert to regular user)

### Requirement 10: User Account Restoration

**User Story:** As an admin, I want to restore deleted or suspended accounts, so that users can regain platform access after issues are resolved.

#### Acceptance Criteria

1. WHEN an admin restores a deleted user, THE System SHALL update adminStatus from deleted to approved
2. WHEN an admin restores a suspended user, THE System SHALL update adminStatus from suspended to approved
3. WHEN a user is restored, THE System SHALL update lastAdminAction with action=restore
4. THE System SHALL only allow restoration from deleted or suspended states, not from banned or rejected states

### Requirement 11: Unified User Management Interface

**User Story:** As an admin, I want a single users management page with tabs for different user types, so that I can efficiently manage all account types.

#### Acceptance Criteria

1. THE System SHALL provide a users management page with three tabs: Craftsmen, Stores, and Couriers
2. WHEN a tab is selected, THE System SHALL stream users from the corresponding collection using StreamBuilder
3. FOR EACH user in the list, THE System SHALL display name, adminStatus, and a detail view button
4. THE System SHALL filter user lists by adminStatus (all, pending, approved, rejected, suspended, banned, deleted)
5. WHEN a user is clicked, THE System SHALL navigate to the user detail page

### Requirement 12: User Detail View

**User Story:** As an admin, I want to view detailed user information and perform actions, so that I can make informed moderation decisions.

#### Acceptance Criteria

1. WHEN the user detail page loads, THE System SHALL stream the user document in real-time using StreamBuilder
2. THE System SHALL display all user profile fields including name, contact information, profession/category, and registration date
3. THE System SHALL display the current adminStatus and lastAdminAction history
4. THE System SHALL provide action buttons: Approve, Reject, Suspend, Ban, Delete, and Restore (based on current status)

### Requirement 13: Craftsman Dashboard Statistics

**User Story:** As an admin, I want to view craftsman statistics on a dashboard, so that I can monitor platform activity and user engagement.

#### Acceptance Criteria

1. THE System SHALL provide a dashboard page with craftsman statistics calculated on-demand from Firestore
2. WHEN the dashboard loads, THE System SHALL display total craftsmen count
3. WHEN the dashboard loads, THE System SHALL display craftsmen count grouped by profession
4. WHEN the dashboard loads, THE System SHALL display pending craftsmen count (adminStatus=pending)
5. THE System SHALL use StreamBuilder to update dashboard statistics in real-time

### Requirement 14: Craftsman Contact Analytics

**User Story:** As an admin, I want to view contact interaction counts per craftsman, so that I can identify high-engagement users.

#### Acceptance Criteria

1. FOR EACH craftsman, THE System SHALL display the total count of phone calls initiated by users
2. FOR EACH craftsman, THE System SHALL display the total count of WhatsApp contacts initiated by users
3. THE System SHALL use denormalized counter fields stored in craftsman documents for performance
4. WHEN contact counts are displayed, THE System SHALL sort craftsmen by total interactions in descending order
5. THE System SHALL update contact counters in real-time when users initiate calls or WhatsApp contacts

### Requirement 15: Store Dashboard Statistics

**User Story:** As an admin, I want a separate dashboard for store statistics, so that I can monitor marketplace activity independently from craftsmen.

#### Acceptance Criteria

1. THE System SHALL provide a separate dashboard page for store/market statistics
2. WHEN the store dashboard loads, THE System SHALL display total stores count
3. WHEN the store dashboard loads, THE System SHALL display stores count grouped by category
4. WHEN the store dashboard loads, THE System SHALL display pending stores count (adminStatus=pending)
5. THE System SHALL calculate all store statistics on-demand from the markets collection

### Requirement 16: Image Management for Craftsmen

**User Story:** As an admin, I want to control images uploaded to craftsman portfolios, so that I can remove inappropriate content.

#### Acceptance Criteria

1. THE System SHALL display all portfolio images uploaded by a craftsman in the user detail page
2. FOR EACH portfolio image, THE System SHALL provide a delete button visible only to admins
3. WHEN an admin deletes an image, THE System SHALL remove the image URL from the craftsman document
4. WHEN an image is deleted, THE System SHALL optionally delete the image file from Firebase Storage
5. WHEN an image is deleted, THE System SHALL update the craftsman's portfolio image array in Firestore

### Requirement 17: Admin Dashboard Overview

**User Story:** As an admin, I want a dashboard overview page, so that I can quickly see key metrics and pending tasks.

#### Acceptance Criteria

1. THE System SHALL provide a dashboard page displaying summary statistics for all user types
2. WHEN the dashboard loads, THE System SHALL display pending craftsmen count and total craftsmen count
3. WHEN the dashboard loads, THE System SHALL display pending stores count and total stores count
4. WHEN the dashboard loads, THE System SHALL display pending couriers count and total couriers count
5. WHEN the dashboard loads, THE System SHALL display open reports count

### Requirement 18: Real-Time Data Updates

**User Story:** As an admin, I want all admin pages to update in real-time, so that I always see current data without manual refresh.

#### Acceptance Criteria

1. THE System SHALL use StreamBuilder for all Firestore queries in admin pages
2. WHEN a document is updated in Firestore, THE System SHALL automatically update the corresponding UI widget within 2 seconds
3. WHEN a new report is created, THE System SHALL add it to the pending reports list in real-time without page reload
4. WHEN a user status changes, THE System SHALL update all admin lists displaying that user in real-time
5. THE System SHALL maintain active Firestore listeners for the duration of admin page sessions

### Requirement 19: Firebase Security Rules Enforcement

**User Story:** As the system, I want Firebase Security Rules to enforce access control, so that unauthorized users cannot access or modify admin data.

#### Acceptance Criteria

1. THE System SHALL enforce that only users with Custom Claims role=admin or role=moderator can read the user_reports collection
2. THE System SHALL enforce that only users with Custom Claims role=admin can update adminStatus, adminNote, and lastAdminAction fields in craftsmen, markets, and courier_requests collections
3. IF an unauthorized user attempts to read or write admin data, THEN Firestore SHALL reject the operation with a permission-denied error
4. THE System SHALL validate Custom Claims on every Firestore operation through Security Rules

### Requirement 20: Cost-Optimized Queries

**User Story:** As the system, I want to minimize Firestore read operations, so that Firebase costs remain low.

#### Acceptance Criteria

1. THE System SHALL use denormalized counter fields for frequently accessed statistics (call counts, WhatsApp counts, report counts)
2. THE System SHALL avoid aggregation queries in Cloud Functions for real-time dashboards
3. WHEN calculating dashboard statistics, THE System SHALL use simple where queries with indexed fields
4. THE System SHALL calculate statistics on-demand without a separate platform_stats collection
5. THE System SHALL limit StreamBuilder listeners to only necessary collections and documents

### Requirement 21: Error Handling for User Not Found

**User Story:** As an admin, I want clear error messages when attempting to modify non-existent users, so that I understand why operations fail.

#### Acceptance Criteria

1. WHEN an admin attempts to update a user that does not exist in Firestore, THE System SHALL display an error message "المستخدم غير موجود" (User not found)
2. WHEN a user-not-found error occurs, THE System SHALL navigate back to the users list page
3. THE System SHALL validate user existence before performing any update operation
4. WHEN a user document is deleted between page load and action execution, THE System SHALL handle the race condition gracefully
5. THE System SHALL log user-not-found errors for debugging purposes

### Requirement 22: Error Handling for Permission Denied

**User Story:** As a non-admin user, I want clear feedback when attempting to access admin features, so that I understand access restrictions.

#### Acceptance Criteria

1. WHEN a user without admin or moderator role attempts to access an admin page, THE System SHALL display the message "ليس لديك صلاحيات" (You don't have permissions)
2. WHEN a permission-denied error occurs, THE System SHALL redirect the user to the home page
3. THE System SHALL check permissions before rendering any admin UI components
4. IF Firebase Security Rules reject an operation, THEN THE System SHALL catch the permission-denied exception and display a user-friendly message
5. THE System SHALL prevent unauthorized users from seeing admin navigation menu items

### Requirement 23: Error Handling for Network Failures

**User Story:** As an admin, I want to retry failed operations due to network issues, so that temporary connectivity problems don't block my work.

#### Acceptance Criteria

1. WHEN a Firestore operation fails due to network error, THE System SHALL display the message "حدث خطأ، حاول مرة أخرى" (An error occurred, try again)
2. WHEN a network error occurs, THE System SHALL provide a retry button
3. WHEN the retry button is clicked, THE System SHALL re-attempt the failed operation
4. THE System SHALL distinguish between network errors and other error types (permission, validation)
5. THE System SHALL timeout Firestore operations after 30 seconds and treat timeouts as network errors

### Requirement 24: Input Validation for Report Resolution

**User Story:** As an admin, I want validation errors when submitting incomplete report resolutions, so that all resolved reports have proper documentation.

#### Acceptance Criteria

1. WHEN an admin attempts to resolve a report without entering resolution text, THE System SHALL prevent form submission
2. WHEN resolution text is empty, THE System SHALL display a validation error message below the resolution input field
3. THE System SHALL require minimum 10 characters for resolution text
4. WHEN resolution text meets validation requirements, THE System SHALL enable the submit button
5. THE System SHALL trim whitespace from resolution text before validation

### Requirement 25: Cloud Function for Report Notifications

**User Story:** As an admin, I want to receive push notifications when new reports are created, so that I can respond quickly to user complaints.

#### Acceptance Criteria

1. WHEN a new report document is created in Firestore, THE System SHALL trigger the onReportCreated Cloud Function
2. WHEN the onReportCreated function executes, THE System SHALL send an FCM message to the admin_notifications topic
3. THE FCM notification SHALL include title "بلاغ جديد" (New Report) and body text indicating the report type
4. THE System SHALL complete the notification within 5 seconds of report creation
5. IF FCM delivery fails, THEN THE Cloud Function SHALL log the error but not retry

### Requirement 26: Admin Navigation and Routing

**User Story:** As an admin, I want intuitive navigation between admin pages, so that I can efficiently access different management features.

#### Acceptance Criteria

1. THE System SHALL use GoRouter for declarative routing in the admin module
2. THE System SHALL provide a navigation drawer or bottom navigation bar with links to Dashboard, Users, Reports, and Images pages
3. WHEN an admin clicks a navigation item, THE System SHALL navigate to the corresponding page within 500ms
4. THE System SHALL highlight the current page in the navigation menu
5. THE System SHALL use deep linking to allow direct navigation to specific users or reports via URL

