# Tasks List: Admin Management System

## Task 1: Create Data Models

**Status:** pending

**Description:**
Create Dart data models for UserReport and AdminAction with Firestore serialization.

**Acceptance Criteria:**
- [ ] Create `lib/admin/models/user_report.dart` with UserReport class
- [ ] Implement fromFirestore factory method
- [ ] Implement toFirestore method
- [ ] Create `lib/admin/models/admin_action.dart` with AdminAction class
- [ ] Implement toMap and fromMap methods
- [ ] Add validation for required fields

**Files to Create:**
- `lib/admin/models/user_report.dart`
- `lib/admin/models/admin_action.dart`

---

## Task 2: Create ReportService

**Status:** pending

**Description:**
Implement ReportService with methods for creating, viewing, and managing reports.

**Acceptance Criteria:**
- [ ] Create `lib/admin/services/report_service.dart`
- [ ] Implement createReport with duplicate validation (24-hour check)
- [ ] Implement watchPendingReports with StreamBuilder
- [ ] Implement getReportsByTarget
- [ ] Implement resolveReport
- [ ] Implement dismissReport
- [ ] Add error handling for all methods

**Files to Create:**
- `lib/admin/services/report_service.dart`

**Dependencies:**
- Task 1 (Data Models)

---

## Task 3: Create AdminAccountService

**Status:** pending

**Description:**
Implement AdminAccountService with account management methods (approve, reject, suspend, ban, delete, restore).

**Acceptance Criteria:**
- [ ] Create `lib/admin/services/admin_account_service.dart`
- [ ] Implement approveUser method
- [ ] Implement rejectUser method with reason validation
- [ ] Implement suspendAccount method with reason validation
- [ ] Implement banAccount method with reason validation
- [ ] Implement deleteAccount with batch write (account + users collection)
- [ ] Implement restoreAccount with batch write
- [ ] Implement watchAccountsByStatus
- [ ] Add helper method _collection for routing to correct collection

**Files to Create:**
- `lib/admin/services/admin_account_service.dart`

**Dependencies:**
- Task 1 (Data Models)

---

## Task 4: Create DashboardService

**Status:** pending

**Description:**
Implement DashboardService with methods for retrieving dashboard statistics.

**Acceptance Criteria:**
- [ ] Create `lib/admin/services/dashboard_service.dart`
- [ ] Implement getQuickStats method
- [ ] Use count() queries for totalCraftsmen, totalStores, pendingReports
- [ ] Implement _getCraftsmenByProfession helper method
- [ ] Get top 10 craftsmen by totalCalls
- [ ] Return structured map with all statistics

**Files to Create:**
- `lib/admin/services/dashboard_service.dart`

---

## Task 5: Create AdminDashboardPage

**Status:** pending

**Description:**
Create admin dashboard page displaying quick stats and charts.

**Acceptance Criteria:**
- [ ] Create `lib/admin/pages/admin_dashboard_page.dart`
- [ ] Use FutureBuilder with DashboardService.getQuickStats()
- [ ] Display stat cards for craftsmen, stores, pending reports
- [ ] Display craftsmen count by profession
- [ ] Display top 10 craftsmen with call/WhatsApp counts
- [ ] Add loading indicator
- [ ] Add error handling UI

**Files to Create:**
- `lib/admin/pages/admin_dashboard_page.dart`
- `lib/admin/widgets/stat_card.dart` (reusable widget)

**Dependencies:**
- Task 4 (DashboardService)

---

## Task 6: Create ReportsListPage

**Status:** pending

**Description:**
Create reports list page displaying pending reports in real-time.

**Acceptance Criteria:**
- [ ] Create `lib/admin/pages/reports_list_page.dart`
- [ ] Use StreamBuilder with ReportService.watchPendingReports()
- [ ] Display reports in Card widgets with report info
- [ ] Show empty state when no reports
- [ ] Add navigation to ReportDetailPage
- [ ] Add loading indicator
- [ ] Display report count per target entity

**Files to Create:**
- `lib/admin/pages/reports_list_page.dart`

**Dependencies:**
- Task 2 (ReportService)

---

## Task 7: Create ReportDetailPage

**Status:** pending

**Description:**
Create report detail page with resolve/dismiss actions.

**Acceptance Criteria:**
- [ ] Create `lib/admin/pages/report_detail_page.dart`
- [ ] Display full report details (reason, target, date)
- [ ] Show total report count for target entity
- [ ] Add Resolve button with resolution text input dialog
- [ ] Add Dismiss button with reason text input dialog
- [ ] Validate resolution text (minimum 10 characters)
- [ ] Navigate back after successful resolution
- [ ] Add delete target entity button (calls AdminAccountService.deleteAccount)

**Files to Create:**
- `lib/admin/pages/report_detail_page.dart`

**Dependencies:**
- Task 2 (ReportService)
- Task 3 (AdminAccountService)

---

## Task 8: Create UsersListPage with Tabs

**Status:** pending

**Description:**
Create unified users management page with tabs for Craftsmen, Stores, Couriers.

**Acceptance Criteria:**
- [ ] Create `lib/admin/pages/users_list_page.dart`
- [ ] Use DefaultTabController with 3 tabs
- [ ] Create _UsersTab widget for each tab
- [ ] Use StreamBuilder with AdminAccountService.watchAccountsByStatus()
- [ ] Add filter dropdown for adminStatus (all, pending, active, suspended, banned, deleted)
- [ ] Display user cards with name, status, and detail button
- [ ] Navigate to UserDetailPage on tap

**Files to Create:**
- `lib/admin/pages/users_list_page.dart`

**Dependencies:**
- Task 3 (AdminAccountService)

---

## Task 9: Create UserDetailPage

**Status:** pending

**Description:**
Create user detail page with full profile and admin action buttons.

**Acceptance Criteria:**
- [ ] Create `lib/admin/pages/user_detail_page.dart`
- [ ] Use StreamBuilder to watch user document in real-time
- [ ] Display user profile fields (name, contact, profession, registration date)
- [ ] Display adminStatus badge
- [ ] Display lastAdminAction history
- [ ] Add action buttons based on current status (Approve, Reject, Suspend, Ban, Delete, Restore)
- [ ] Add input dialogs for actions requiring reason
- [ ] Display portfolio images section (if craftsman)
- [ ] Add delete button for each portfolio image
- [ ] Show report count and reports list

**Files to Create:**
- `lib/admin/pages/user_detail_page.dart`

**Dependencies:**
- Task 3 (AdminAccountService)
- Task 2 (ReportService for getReportsByTarget)

---

## Task 10: Implement Image Management

**Status:** pending

**Description:**
Add functionality to delete portfolio images from craftsman accounts.

**Acceptance Criteria:**
- [ ] Create `lib/admin/services/image_service.dart`
- [ ] Implement deletePortfolioImage method
- [ ] Remove image URL from craftsman document
- [ ] Optionally delete image file from Firebase Storage
- [ ] Add confirmation dialog before deletion
- [ ] Update UI in real-time after deletion

**Files to Create:**
- `lib/admin/services/image_service.dart`

**Dependencies:**
- Task 9 (UserDetailPage)

---

## Task 11: Create Cloud Function - onReportCreated

**Status:** pending

**Description:**
Create Firebase Cloud Function to handle report creation events.

**Acceptance Criteria:**
- [ ] Create `functions/src/index.ts` (or index.js)
- [ ] Implement onReportCreated trigger on user_reports collection onCreate
- [ ] Increment reportCount on target entity using FieldValue.increment
- [ ] Send FCM notification to admin_notifications topic
- [ ] Include report metadata in FCM data payload
- [ ] Add error logging
- [ ] Deploy function to Firebase

**Files to Create:**
- `functions/src/index.ts`
- `functions/package.json`

**Commands:**
```bash
firebase init functions
cd functions
npm install firebase-admin firebase-functions
```

---

## Task 12: Configure Firestore Security Rules

**Status:** pending

**Description:**
Update Firestore security rules to enforce admin role-based access.

**Acceptance Criteria:**
- [ ] Update `firestore.rules` file
- [ ] Add isAdmin() and isModerator() helper functions
- [ ] Add rules for user_reports collection (users can create, admins can manage)
- [ ] Add rules for craftsmen collection (public read, admin-only update for admin fields)
- [ ] Add rules for markets collection (same as craftsmen)
- [ ] Add rules for courier_requests collection (same as craftsmen)
- [ ] Add rules for users collection (admin-only update for role/conversion fields)
- [ ] Deploy rules to Firebase

**Files to Modify:**
- `firestore.rules`

**Commands:**
```bash
firebase deploy --only firestore:rules
```

---

## Task 13: Create Composite Indexes

**Status:** pending

**Description:**
Create composite indexes for efficient Firestore queries.

**Acceptance Criteria:**
- [ ] Create `firestore.indexes.json` file
- [ ] Add index for user_reports (status ASC, createdAt DESC)
- [ ] Add index for user_reports (targetId ASC, createdAt DESC)
- [ ] Add index for craftsmen (adminStatus ASC, createdAt DESC)
- [ ] Add index for craftsmen (adminStatus ASC, totalCalls DESC)
- [ ] Deploy indexes to Firebase

**Files to Create:**
- `firestore.indexes.json`

**Commands:**
```bash
firebase deploy --only firestore:indexes
```

---

## Task 14: Add Admin Navigation Routes

**Status:** pending

**Description:**
Add admin routes to app routing configuration.

**Acceptance Criteria:**
- [ ] Update app routing file (GoRouter or MaterialApp routes)
- [ ] Add route for /admin/dashboard
- [ ] Add route for /admin/reports
- [ ] Add route for /admin/reports/:reportId
- [ ] Add route for /admin/users
- [ ] Add route for /admin/users/:userId
- [ ] Add admin role check middleware
- [ ] Redirect unauthorized users to home page

**Files to Modify:**
- `lib/router/app_router.dart` (or equivalent routing file)

**Dependencies:**
- Task 5, 6, 7, 8, 9

---

## Task 15: Create Admin Navigation Drawer

**Status:** pending

**Description:**
Create navigation drawer for admin pages.

**Acceptance Criteria:**
- [ ] Create `lib/admin/widgets/admin_drawer.dart`
- [ ] Add links to Dashboard, Users, Reports, Images pages
- [ ] Highlight current page
- [ ] Show admin name and role
- [ ] Add logout button
- [ ] Use only if user has admin or moderator role

**Files to Create:**
- `lib/admin/widgets/admin_drawer.dart`

---

## Task 16: Implement Error Handling

**Status:** pending

**Description:**
Add comprehensive error handling across all admin services and pages.

**Acceptance Criteria:**
- [ ] Add try-catch blocks in all service methods
- [ ] Handle 'not-found' errors with Arabic message "المستخدم غير موجود"
- [ ] Handle 'permission-denied' errors with Arabic message "ليس لديك صلاحيات"
- [ ] Handle network errors with retry button and message "حدث خطأ، حاول مرة أخرى"
- [ ] Add 30-second timeout for Firestore operations
- [ ] Log all errors for debugging
- [ ] Display user-friendly error messages in SnackBar or AlertDialog

**Files to Modify:**
- All service files
- All page files

**Dependencies:**
- Task 2, 3, 4

---

## Task 17: Add Input Validation

**Status:** pending

**Description:**
Add validation for all admin input forms.

**Acceptance Criteria:**
- [ ] Validate report resolution text (minimum 10 characters)
- [ ] Validate rejection reason (non-empty)
- [ ] Validate suspension reason (non-empty)
- [ ] Validate ban reason (non-empty)
- [ ] Trim whitespace from all text inputs
- [ ] Show validation error messages below input fields
- [ ] Disable submit buttons until validation passes

**Files to Modify:**
- `lib/admin/pages/report_detail_page.dart`
- `lib/admin/pages/user_detail_page.dart`

**Dependencies:**
- Task 7, 9

---

## Task 18: Add denormalized counters to existing collections

**Status:** pending

**Description:**
Update craftsmen, markets, and courier_requests collections to include admin fields.

**Acceptance Criteria:**
- [ ] Create migration script to add default admin fields to existing documents
- [ ] Add adminStatus: 'active' to all existing craftsmen
- [ ] Add reportCount: 0, totalCalls: 0, totalWhatsApp: 0, totalViews: 0 to all craftsmen
- [ ] Add same fields to markets
- [ ] Add adminStatus and reportCount to courier_requests
- [ ] Run migration script on production database

**Files to Create:**
- `scripts/migrate_admin_fields.dart` (or .js)

**Commands:**
```bash
dart scripts/migrate_admin_fields.dart
```

---

## Task 19: Test Admin Authentication

**Status:** pending

**Description:**
Test Firebase Custom Claims for admin role enforcement.

**Acceptance Criteria:**
- [ ] Create test users with admin and moderator roles
- [ ] Set Custom Claims using Firebase Admin SDK
- [ ] Verify admin can access all admin pages
- [ ] Verify moderator can access reports pages only
- [ ] Verify regular user cannot access admin pages
- [ ] Test role check on every admin page load
- [ ] Test Security Rules enforcement

**Commands:**
```bash
# Set custom claims using Firebase CLI
firebase auth:export users.json
# Edit users.json to add customClaims
firebase auth:import users.json
```

---

## Task 20: Integration Testing

**Status:** pending

**Description:**
Test complete admin workflow end-to-end.

**Acceptance Criteria:**
- [ ] Test report creation by regular user
- [ ] Verify Cloud Function increments reportCount
- [ ] Verify admin receives FCM notification
- [ ] Test report resolution by admin
- [ ] Test report dismissal by admin
- [ ] Test account approval workflow
- [ ] Test account rejection with reason
- [ ] Test account suspension
- [ ] Test account ban
- [ ] Test account deletion (soft delete + role conversion)
- [ ] Test account restoration
- [ ] Test dashboard statistics display
- [ ] Test image deletion from portfolio

---

## Implementation Order

1. **Day 1**: Tasks 1, 2, 18 (Data models + ReportService + Migration)
2. **Day 2**: Tasks 3, 11 (AdminAccountService + Cloud Function)
3. **Day 3**: Tasks 4, 5 (DashboardService + Dashboard Page)
4. **Day 4**: Tasks 6, 7 (Reports Pages)
5. **Day 5**: Tasks 8, 9 (Users Pages)
6. **Day 6**: Tasks 10, 14, 15 (Image Management + Navigation + Drawer)
7. **Day 7**: Tasks 12, 13, 16, 17, 19, 20 (Security + Validation + Testing)

**Total Duration: 1 week (7 days)**
