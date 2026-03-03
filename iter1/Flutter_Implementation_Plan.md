# Flutter Implementation Plan for Focus or Else (FoE)

**Document Created:** March 3, 2026  
**Figma Source:** Frame ID `1030:4396` - "samplescreens01"  
**Figma File:** https://www.figma.com/design/n61kR1advg5QOKNYClV2Iz/Focus-or-Else?node-id=1030:4396

---

## Table of Contents

1. [Overview](#overview)
2. [Screen Inventory & Analysis](#screen-inventory--analysis)
3. [Design System & Reusable Components](#design-system--reusable-components)
4. [Technical Implementation Details](#technical-implementation-details)
5. [Answered Questions & Clarifications](#answered-questions--clarifications)

---

## Overview

This document outlines my understanding of the Figma designs in the `samplescreens01` frame and provides a detailed plan for implementing these screens in Flutter. The goal is to ensure alignment with the PRD requirements and the visual design before proceeding with implementation.

### Figma Frame Reference

- **Frame ID:** `1030:4396`
- **Frame Name:** `samplescreens01`
- **Location:** x=6600, y=-1557
- **Dimensions:** 6412 × 8319 pixels

---

## Screen Inventory & Analysis

Based on my analysis of the `samplescreens01` frame, I've identified **34 unique screens** organized by functionality. Below is my understanding of each screen and its purpose:

### 1. Authentication & Onboarding

#### Screen 1.1: Sign Up

- **Figma ID:** `536:4349`
- **Purpose:** User registration/sign-up screen
- **Key Elements:**
   - OAuth button (Google Sign-In only for MVP)
   - Email/password input fields
   - Terms & conditions checkbox
- **Implementation Priority:** HIGH (MVP - needs CREATION)
- **Status:** Create from Figma design
- **Note:** See "Answered Questions & Clarifications" section for authentication details

---

### 2. Home/Feed Screens

#### Screen 2.1: Home Page (Feed)

- **Purpose:** Social feed showing friends' completed/failed pacts
- **Key Elements:**
   - Vertical scrolling feed
   - FYP (For You Page) navigation
   - Pact posts with like/comment buttons
   - Consequence posts
   - Bottom navigation bar
- **Implementation Priority:** HIGH (MVP - needs MODIFICATION)
- **Status:** Need to modify existing screen
- **Notes:** Currently shows TikTok-style vertical feed - aligns with PRD's "social-first" approach

---

### 3. Pact Management Screens

#### Screen 3.1: PactScreen (Main View - Multiple States)

- **Figma IDs:** `635:3885`, `635:4808`, `635:5484`, `650:4493`
- **Purpose:** Main pact management dashboard
- **Note:** These IDs represent different states of the same screen - review each against PRD requirements
- **Key Elements:**
   - Tab navigation: "Active" / "Expired"
   - Calendar view (month selector with navigation)
   - Featured active pact card with:
      - Pact category badge
      - Task title and description
      - Deadline countdown timer (HH:MM:SS)
      - Time remaining indicator
      - Friends/verifiers avatars
      - Consequence preview
      - "Submit Evidence" CTA button
   - "Upcoming Pacts" section with mini pact cards
   - "Recent Activity" feed section
- **Implementation Priority:** HIGH (MVP - needs CREATION)
- **Status:** Create new screen
- **Design Notes:**
   - Uses calendar as main navigation paradigm
   - Prominent countdown timer with color-coded urgency
   - Clean card-based layout
   - Matches PRD color scheme (dark theme with pink accents)

#### Screen 3.2: Pact Screen Active (Part of 3.1 States)

- **Note:** These variations are handled as different states within the main PactScreen component (3.1), not separate screens

#### Screen 3.3: Pact Screen Expired

- **Figma ID:** `647:3959`
- **Purpose:** View for expired/completed pacts
- **Key Elements:**
   - Shows historical pacts
   - Completion status indicators
   - Consequence execution status
   - Post-pact statistics
- **Implementation Priority:** MEDIUM (MVP)
- **Status:** Create new screen

#### Screen 3.4: Pact Details (Multiple States)

- **Figma IDs:** `635:4689`, `635:5035`, `635:5354`, `650:4035`
- **Purpose:** Detailed view of a specific pact
- **Note:** Each ID represents a different state. Review all versions and align with PRD specifications
- **Key Elements:**
   - Full task description
   - Deadline with countdown
   - Verifier information
   - Verification method badge
   - Consequence details (with emoji/icon)
   - Evidence submission section
   - Metadata/stats (reliability score, streak info)
   - Action buttons: "Reject" / "Approve & Complete"
- **Implementation Priority:** HIGH (MVP)
- **Status:** Create new screen
- **Design Notes:**
   - Clean information hierarchy
   - Uses badges for status indicators
   - Consequence shown in bordered box with warning icon
   - Floating action buttons at bottom

#### Screen 3.5: Pact Details: Evidence Submission

- **Figma IDs:** `228:677`, `314:3028`
- **Purpose:** Submit proof of task completion
- **Key Elements:**
   - Photo upload interface
   - Video upload interface (indicated by icon)
   - Text explanation field
   - Preview of submitted content
   - Submit button
- **Implementation Priority:** HIGH (MVP)
- **Status:** Create new screen
- **Notes:** May need to implement two versions (photo focus vs. text focus)

---

### 4. Pact Creation Flow

#### Screen 4.1: Create Pact - Consolidated Single Screen

- **Figma IDs:** `467:2978`, `582:3095`, `650:5025`
- **Purpose:** All-in-one pact creation screen with multiple steps
- **Key Elements:**
   - Task input field (text area, 150 char limit)
   - Deadline selection (separate picker screen)
   - Friend/Verifier selection
   - Consequence selection (from pre-defined library)
   - Quick action buttons / templates
   - Category selection
   - "Continue" / "Next Step" navigation
- **Implementation Priority:** HIGH (MVP)
- **Status:** Create new screen
- **Design Notes:** Single screen with all pact creation steps consolidated. Separate deadline picker screen. Pre-defined consequences only (no custom input).

#### Screen 4.2: Create Pact: Review Pact

- **Figma IDs:** `521:3620`, `651:4768`
- **Purpose:** Review and confirm pact before sealing
- **Key Elements:**
   - Summary of all pact details
   - Task description
   - Deadline display
   - Selected verifier
   - Selected consequence
   - "Seal Pact" button (tap-and-hold gesture)
- **Implementation Priority:** HIGH (MVP)
- **Status:** Create new screen
- **Notes:** PRD mentions tap-and-hold gesture for commitment psychology

#### Screen 4.3: Create Pact: Congrats

- **Figma IDs:** `530:3112`, `651:4868`
- **Purpose:** Success confirmation after creating pact
- **Key Elements:**
   - Celebratory message
   - Pact summary
   - Navigation to view pact or return home
- **Implementation Priority:** MEDIUM (MVP)
- **Status:** Create new screen
- **Notes:** Short celebration moment, then navigate to main screen

#### Screen 4.4: Task Input Section

- **Figma ID:** `625:3190`
- **Purpose:** Component/section for entering task details
- **Key Elements:**
   - Multi-line text input
   - Character counter (150 char limit per PRD)
   - Template suggestions
- **Implementation Priority:** HIGH (MVP)
- **Status:** Create component
- **Notes:** This appears to be a reusable component

---

### 5. Social/Friends Screens

#### Screen 5.1: Friends List

- **Figma IDs:** `631:3211`, `631:3571`
- **Purpose:** Display list of all friends with their status and stats
- **Key Elements:**
   - Friend cards with avatars
   - Online/activity status indicators
   - Current streak display
   - Reliability score
   - Quick actions (message, view profile)
- **Implementation Priority:** HIGH (MVP)
- **Status:** Create new screen
- **Design Notes:**
   - Clean list layout
   - Shows relevant friend stats
   - Aligns with PRD's social features

#### Screen 5.2: 1-on-1 Chat Screen

- **Figma ID:** `607:3167`
- **Purpose:** Direct messaging screen for chatting with a specific friend
- **Key Elements:**
   - Chat message history
   - Text input field
   - Send button
   - Friend's profile info at top
- **Implementation Priority:** HIGH (MVP)
- **Status:** Create new screen
- **Notes:** This is NOT a friends list - it's a chat interface for 1-on-1 conversations

#### Screen 5.3: Friend Request

- **Figma ID:** `631:3502`
- **Purpose:** Send or accept friend requests
- **Key Elements:**
   - Search for users
   - Pending requests list
   - Accept/Reject buttons
   - Username display
- **Implementation Priority:** MEDIUM (MVP)
- **Status:** Create new screen

---

### 6. Profile Screens

#### Screen 6.1: My Profile Frame

- **Figma ID:** `600:3137`
- **Purpose:** User's own profile view
- **Key Elements:**
   - Profile header (avatar, name, bio)
   - Stats overview (streak, success rate, coins)
   - Tab navigation (Posts, Stats, Integrations)
   - Grid of pact posts
- **Implementation Priority:** HIGH (MVP)
- **Status:** Create new screen
- **Design Notes:** TikTok-style profile layout with grid view

#### Screen 6.2: Profile Post Grid

- **Figma IDs:** `650:4183`, `650:5887`
- **Purpose:** Grid view of user's posts
- **Key Elements:**
   - 3-column grid layout
   - Post thumbnails
   - Completion/failure indicators
   - Tap to view full post
- **Implementation Priority:** HIGH (MVP)
- **Status:** Create new screen/component

#### Screen 6.3: Profile Stats

- **Figma IDs:** `650:4214`, `650:5918`
- **Purpose:** Detailed statistics view
- **Key Elements:**
   - Charts/graphs
   - Current streak prominently displayed
   - Success rate percentage
   - Category breakdown
   - Weekly/monthly summaries
- **Implementation Priority:** MEDIUM (Post-MVP)
- **Status:** Create new screen
- **Notes:** May defer detailed charts to Phase 2

---

### 7. Notifications (Background Feature - Not Screens)

**Note:** Notifications are a system feature, not individual screens. They run in the background and display as system-level or in-app alerts.

#### Notification System Requirements:

- **Firebase Cloud Messaging (FCM)** for push notifications
- **Background Operation:** Notifications must work even when app is closed
- **Permission Request:** Ask user AFTER login (not on first launch)
- **Lock Screen Notifications:** System-level push (Figma ID: `643:3965`)
- **In-App Notifications:** Banner/card UI (Figma IDs: `604:3311`, `635:4212`)
- **Implementation Priority:** HIGH (MVP)
- **Status:** Configure FCM, create in-app notification components

---

### 8. Modals & Dialogs

#### Screen 8.1: Warning/Info Modal

- **Figma ID:** `405:1772581`
- **Purpose:** Display warnings or informational messages
- **Key Elements:**
   - Modal overlay
   - Icon (warning/info)
   - Message text
   - Action buttons (OK, Cancel)
- **Implementation Priority:** HIGH (MVP)
- **Status:** Create reusable modal component
- **Notes:** Generic modal for various use cases

---

### 9. Navigation & Components

#### Component: Navbar (Bottom Navigation)

- **Figma IDs:** Referenced in multiple screens
- **Purpose:** Main app navigation
- **Elements:**
   - 5 tabs: Home, Friends, Add (+), Pacts, Profile
   - Icon + label for each tab
   - Active state indicator
   - Center "Add" button with special styling
- **Implementation Priority:** HIGH (MVP)
- **Status:** Create reusable component
- **Design Notes:**
   - Matches PRD specification (max 4-5 tabs)
   - Center button is visually prominent

#### Component: Small Calendar

- **Figma IDs:** Referenced in PactScreen
- **Purpose:** Calendar widget for date navigation
- **Elements:**
   - Month/year display
   - Navigation arrows
   - Date grid with current date highlighted
   - Dates with pacts have indicators
- **Implementation Priority:** HIGH (MVP)
- **Status:** Create reusable component

---

## Design System & Reusable Components

### Core Components to Build

#### 1. **Countdown Timer Component**

- **Purpose:** Display time remaining for pacts
- **Features:**
   - Real-time countdown
   - Color-coded urgency (green > yellow > red)
   - Pulsing animation for urgent states
   - Format: HH:MM:SS or custom
- **Priority:** HIGH

#### 2. **Pact Card Component**

- **Purpose:** Display pact summary in lists/feed
- **Variants:**
   - Mini card (for lists)
   - Featured card (for main view)
   - Feed post card (for social feed)
- **Features:**
   - Category badge
   - Title and description
   - Deadline display
   - Progress indicator
   - Friend avatars
   - Consequence preview
   - Action buttons
- **Priority:** HIGH

#### 3. **Avatar Component**

- **Purpose:** Display user profile pictures
- **Features:**
   - Circular crop
   - Border options
   - Size variants (small, medium, large)
   - Online status indicator
   - Fallback to initials
- **Priority:** HIGH

#### 4. **Badge Component**

- **Purpose:** Display status indicators, categories
- **Features:**
   - Color variants (per category/status)
   - Icon + text or text only
   - Size variants
- **Priority:** HIGH

#### 5. **Calendar Widget**

- **Purpose:** Date navigation and pact scheduling
- **Features:**
   - Month/year display
   - Navigation arrows
   - Date grid
   - Pact indicators on dates
   - Date selection
- **Priority:** HIGH

#### 6. **Bottom Sheet Modal**

- **Purpose:** Display content in modal overlay
- **Features:**
   - Slide-up animation
   - Backdrop blur
   - Drag-to-dismiss gesture
   - Various heights (half, full)
- **Priority:** MEDIUM

#### 7. **Progress Bar Component**

- **Purpose:** Visual progress indicators
- **Features:**
   - Gradient fills
   - Percentage-based
   - Animated transitions
   - Color-coded for urgency
- **Priority:** MEDIUM

#### 8. **Consequence Card Component**

- **Purpose:** Display consequence information
- **Features:**
   - Icon/emoji
   - Description text
   - Warning styling
   - Border accent
- **Priority:** HIGH

---

## Technical Implementation Details

### Missing Screens - Clarification

Based on PRD requirements, the following screens are not in the Figma frame but are needed:

1. **Login Screen:**
   - **Status:** Login screen EXISTS in current codebase
   - **Action:** Will be MODIFIED to match design system and Figma style
2. **Sign Up Screen:**
   - **Figma ID:** `536:4349`
   - **Status:** Will be CREATED from Figma design
   - **Note:** Only Google OAuth for MVP (no Apple Sign-In, no email verification)

3. **Forgot Password Screen:**
   - **Status:** Not in Figma, needs to be GENERATED
   - **Action:** Create based on existing design style and patterns from other auth screens
4. **Pact Creation Intermediate Screens:**
   - Deadline selection
   - Verifier selection
   - Consequence selection
   - **Status:** Consolidated into single "Create Pact" screen with all steps (Screen 4.1)
   - Separate deadline picker screen
5. **Settings Screen:**
   - **Status:** Out of scope for MVP, can be added later if needed

### Authentication Implementation

- **Google Sign-In ONLY** for MVP
- No Apple Sign-In
- No email verification flow
- Notification permission requested AFTER login (not on first launch)

### Pact Creation Flow

**Single consolidated screen with all pact creation steps:**

- Task input (150 character limit from PRD)
- Category selection
- Deadline selection (separate picker screen)
- Friend/Verifier selection
- Consequence selection from pre-defined library (no custom consequences)
- Review step with tap-and-hold "Seal Pact" gesture
- Success confirmation

**Goal:** 60-second pact creation (PRD requirement)

### Evidence Submission Specifications

- **Maximum Photos:** 5 images per submission
- **Maximum Video:** 5 minutes length
- **Media Compression:** Recommended before upload to Firebase Storage
- **Preview:** YES - users must see preview before submission
- **Editing After Submission:** NO - evidence cannot be edited/replaced once submitted
- **Storage:** Firebase Storage for all media files

### Feed/Home Screen Behavior

- **Feed Order:** Chronological (not algorithmic)
- **Initial Load:** Load recent posts from friends
- **Empty State:** Display "No current posts right now" for new users with no friends or no activity
- **Filtering:** Basic filtering by friend activity

### Calendar Widget

- **Display Only:** Calendar shows pacts scheduled on dates
- **No Device Sync:** No integration with Apple Calendar or Google Calendar for MVP
- **Interaction:** Clicking dates navigates to that day's pacts

### Media Handling & Storage

- **Backend:** Firebase Storage for all uploaded media
- **Image Compression:** Recommend implementing compression before upload
- **Thumbnail Generation:** Consider generating thumbnails for performance
- **File Size Limits:** Follow Firebase Storage limits and enforce reasonable maximums

### Animations & Polish

- **PRD Animation Specs:** Implement ALL animations specified in PRD Section 9.5
- **Critical Animations for MVP:**
   - Countdown timer pulses (urgency indicator)
   - Button press effects
   - Success celebrations (confetti)
   - Badge unlock animations
   - Smooth transitions between screens
- **Haptic Feedback:** DITCHED for MVP (can add later)

### Theme & Color Scheme

**Dark Mode (Primary):**

- Background: #0A0A0B (Deep Black), #1F1E1F (Charcoal)
- Primary: #FF2659 (Hot Pink)
- Accent: #F97316 (Orange)
- Typography: Inter font family

**Light Mode:**

- **Status:** Both dark and light modes to be implemented
- **Action:** Create light mode color mappings for all UI elements
- **Priority:** HIGH (MVP includes both themes)

### State Management

- **Options:** Provider or Riverpod
- **Recommendation:** Use Provider for simplicity, migrate to Riverpod if state complexity increases
- **Pact Timers:** Use Streams for real-time countdown updates

### Firebase Configuration

- **Already Set Up:** `google-services.json` exists in project
- **Services to Use:**
   - Firebase Auth (Google OAuth)
   - Cloud Firestore (user data, pact data, friend relationships)
   - Firebase Storage (photos, videos)
   - Firebase Cloud Messaging (push notifications)
   - Cloud Functions (for backend logic like deadline checks, consequence triggers)

### Offline Support

- **Status:** DITCHED for MVP
- **Reason:** Complexity vs. value trade-off for initial release
- **Future:** Can add Firestore offline persistence in later versions

### Database Structure Recommendations

**Firestore Collections:**

```
users/
  - userId
  - displayName
  - email
  - photoURL
  - reliabilityScore
  - currentStreak
  - createdAt

pacts/
  - pactId
  - ownerId
  - taskDescription
  - deadline
  - category
  - consequence
  - verifierId
  - status (active, completed, failed, expired)
  - evidenceSubmitted
  - verificationStatus
  - createdAt

evidence/
  - evidenceId
  - pactId
  - userId
  - mediaUrls[] (Firebase Storage URLs)
  - textExplanation
  - submittedAt
  - verificationStatus

friends/
  - relationshipId
  - userId1
  - userId2
  - status (pending, accepted, blocked)
  - createdAt

feed_posts/
  - postId
  - userId
  - pactId
  - type (completion, failure, consequence)
  - mediaUrls[]
  - likes[]
  - comments[]
  - createdAt
```

### Notifications Background Operation

- **Requirement:** Notifications must work even when app is completely closed
- **Implementation:** Firebase Cloud Messaging with background handlers
- **Permission Timing:** Ask user AFTER successful login (better UX)
- **Types:**
   - Deadline reminders (customizable intervals)
   - Friend activity notifications
   - Verification requests
   - Pact status updates

---

## Answered Questions & Clarifications

Below are all design, functional, technical, and UI/UX clarifications with answers incorporated:

### Design Clarifications

**1. Screen Variations (Same Title, Multiple IDs):**

- **Answer:** Screens with the same title represent different STATES of the same functionality
- **Action:** Review each variation and align with PRD requirements
- **Examples:**
   - Pact Details (4 IDs) = Active state, expired state, under verification state, completed state
   - Pact Screen Active (3 IDs) = Different active pact states

**2. Missing Screens:**

- **Login:** Exists in codebase, will be modified
- **Sign Up:** In Figma (`536:4349`), will be created
- **Forgot Password:** Not in Figma, will be generated based on style
- **Pact Creation Steps:** Consolidated into single screen (4.1)
- **Settings:** Out of scope for MVP
- **Onboarding Tutorial:** Out of scope for MVP

**3. Friends List Screens:**

- **Friends List Newest (`631:3211`, `631:3571`):** List of all friends with stats
- **Friends List Updated (`607:3167`):** 1-on-1 chat screen (NOT a friends list)
- **Action:** Implement both - one as friends list, one as chat interface

**4. Task Input Section (`625:3190`):**

- **Answer:** This is a COMPONENT within the consolidated Create Pact screen
- **Use:** Reusable input field for task entry with character counter

**5. SVG Component (`651:4981`):**

- **Answer:** Icon library or asset export from Figma
- **Action:** Extract icons as needed for implementation

### Functional Clarifications

**6. Authentication:**

- **Apple Sign-In:** NO - not included in MVP
- **Google Sign-In:** YES - only OAuth method for MVP
- **Email Verification:** NO - not required for MVP
- **.edu Email:** Not enforced in MVP (social accountability features provide validation)

**7. Pact Creation Flow:**

- **Flow Steps:** Single screen with all steps consolidated (Screen 4.1)
- **Deadline Selection:** Separate picker screen
- **Consequence Selection:** Pre-defined library only (no custom input)
- **Target Time:** 60-second creation goal (PRD requirement)

**8. Evidence Submission:**

- **Max Photos:** 5 images
- **Max Video:** 5 minutes length
- **Max File Size:** Follow Firebase Storage limits, enforce reasonable maximums
- **Preview:** YES - show preview before submission
- **Editing:** NO - cannot edit or replace after submission

**9. Notifications:**

- **Background Operation:** YES - must work when app is closed
- **Grace Period:** Implementation decision - consider 5-10 minute buffer
- **Permission Request:** AFTER login (not on first launch)
- **Technology:** Firebase Cloud Messaging (FCM)

**10. Feed/Home Screen:**

- **Feed Order:** Chronological (not algorithmic)
- **Initial Load:** Recent posts from friends
- **Empty State:** Show "No current posts right now" for new users
- **Filtering:** Basic filtering available

**11. Calendar Integration:**

- **Display Only:** Shows pacts on dates, navigates to pact details
- **No Device Sync:** No Apple Calendar or Google Calendar integration for MVP
- **Interaction:** Click date to view that day's pacts

### Technical Clarifications

**12. State Management:**

- **Choice:** Provider (recommended for simplicity)
- **Alternative:** Riverpod (if state complexity increases)
- **Pact Timers:** Use Streams for real-time countdown updates

**13. Firebase Setup:**

- **Already Configured:** `google-services.json` exists
- **Services to Use:**
   - Firebase Auth
   - Cloud Firestore
   - Firebase Storage
   - Firebase Cloud Messaging (FCM)
   - Cloud Functions
- **Answer:** YES - use Firebase for everything

**14. Media Handling:**

- **Storage:** Firebase Storage
- **Compression:** YES - recommend implementing image compression before upload
- **Thumbnails:** YES - consider generating thumbnails for performance optimization

**15. Offline Support:**

- **Answer:** DITCHED for MVP
- **Reason:** Complexity trade-off
- **Future:** Can add Firestore offline persistence later
- **Pact Creation Offline:** NO
- **Evidence Upload Queue:** NO (for MVP)

### UI/UX Clarifications

**16. Animations:**

- **Answer:** Implement ALL animations from PRD Section 9.5
- **Critical for MVP:**
   - Countdown timer pulses (urgency)
   - Button press effects
   - Success celebrations (confetti)
   - Badge unlock animations
   - Screen transitions
- **Priority:** HIGH - animations are core to app experience

**17. Dark Mode:**

- **Answer:** Implement BOTH dark and light modes for MVP
- **Primary:** Dark mode (as shown in Figma)
- **Light Mode:** Create color mappings for all UI elements
- **Priority:** HIGH (both themes required)

**18. Haptic Feedback:**

- **Answer:** DITCHED for MVP
- **Reason:** Can add in polish phase if time permits
- **Future:** Add haptic feedback for critical actions (seal pact, deadline hit, verification)
- **Priority:** LOW (nice-to-have, not MVP blocker)

---

## Implementation Strategy

### Development Approach

1. **Design System Foundation First:**
   - Set up theme configuration (dark + light modes)
   - Create color palette constants from PRD
   - Implement typography system (Inter font family)
   - Build reusable UI components library

2. **Authentication & Core Navigation:**
   - Modify existing login screen
   - Create sign up screen from Figma
   - Generate forgot password screen
   - Implement bottom navigation bar
   - Set up routing structure

3. **Core Features (Pact System):**
   - Create pact management screens (view, details, states)
   - Implement consolidated pact creation flow
   - Build evidence submission system
   - Set up Firebase backend integration

4. **Social Features:**
   - Modify home/feed screen
   - Create friends list and chat screens
   - Implement friend request system
   - Add like/comment functionality

5. **Profile & Polish:**
   - Create profile screens (view, stats, post grid)
   - Implement notification system (FCM)
   - Add all PRD animations
   - Test thoroughly across both themes

---

## Code Organization

Recommended Flutter project structure:

```
lib/
├── main.dart
├── theme/
│   ├── app_theme.dart
│   ├── colors.dart
│   ├── typography.dart
│   └── animations.dart
├── models/
│   ├── user.dart
│   ├── pact.dart
│   ├── consequence.dart
│   └── evidence.dart
├── providers/
│   ├── auth_provider.dart
│   ├── pact_provider.dart
│   ├── friend_provider.dart
│   └── feed_provider.dart
├── screens/
│   ├── auth/
│   │   ├── signup_screen.dart
│   │   └── login_screen.dart
│   ├── home/
│   │   └── home_screen.dart
│   ├── pacts/
│   │   ├── pact_screen.dart
│   │   ├── pact_details_screen.dart
│   │   └── pact_expired_screen.dart
│   ├── create_pact/
│   │   ├── create_pact_start.dart
│   │   ├── create_pact_review.dart
│   │   └── create_pact_congrats.dart
│   ├── evidence/
│   │   └── evidence_submission_screen.dart
│   ├── friends/
│   │   ├── friends_list_screen.dart
│   │   └── friend_request_screen.dart
│   └── profile/
│       ├── profile_screen.dart
│       ├── profile_posts_screen.dart
│       └── profile_stats_screen.dart
├── widgets/
│   ├── common/
│   │   ├── app_button.dart
│   │   ├── app_input.dart
│   │   ├── app_card.dart
│   │   ├── app_badge.dart
│   │   └── avatar.dart
│   ├── navigation/
│   │   └── bottom_nav_bar.dart
│   ├── pacts/
│   │   ├── pact_card.dart
│   │   ├── countdown_timer.dart
│   │   ├── calendar_widget.dart
│   │   └── consequence_card.dart
│   └── feed/
│       ├── feed_post.dart
│       └── feed_card.dart
├── services/
│   ├── auth_service.dart
│   ├── firestore_service.dart
│   ├── storage_service.dart
│   └── notification_service.dart
└── utils/
    ├── constants.dart
    ├── helpers.dart
    └── validators.dart
```

---

## Summary

This plan covers **34+ screens and components** identified in the `samplescreens01` frame (Figma ID: `1030:4396`). All clarification questions have been answered and incorporated into this document.

**Core Implementation Areas:**

- **Authentication:** Google Sign-In only, existing login screen to modify, sign up and forgot password screens to create
- **Pact System:** Consolidated single-screen creation flow, multiple state management, real-time countdown timers
- **Social Features:** Chronological feed, friends list, 1-on-1 chat, like/comment system
- **Evidence Submission:** Max 5 photos, 5-minute video, preview required, no editing after submission
- **Profile & Stats:** User profiles, post grid, statistics dashboard
- **Notifications:** FCM background notifications, permission requested after login
- **Themes:** Both dark and light modes required for MVP

**Technical Stack Confirmed:**

- **State Management:** Provider (recommended)
- **Backend:** Firebase (Auth, Firestore, Storage, FCM, Cloud Functions)
- **Media:** Firebase Storage with compression
- **Animations:** All PRD Section 9.5 specs to be implemented
- **Offline Support:** Ditched for MVP
- **Haptic Feedback:** Ditched for MVP

**Implementation Priorities:**

✅ **MVP Features:**

- Authentication (Google OAuth)
- Home Feed (modified from existing)
- Pact Management (view, create, details, evidence submission)
- Friends List & Chat
- Basic Profile & Stats
- Push Notifications
- Both dark and light themes
- All PRD animations

🔮 **Post-MVP:**

- AI verification
- Advanced statistics and charts
- Voucher redemption system
- Settings screen
- Haptic feedback
- Offline support

---

## Next Steps - Ready to Proceed

### Confirmation

✅ All 18 clarification questions have been answered  
✅ Screen purposes and states clarified  
✅ Missing screens addressed  
✅ Technical architecture confirmed  
✅ Implementation priorities set

### Upon Your Approval, I Will:

1. **Begin Design System Setup:**
   - Set up dark and light theme configurations
   - Create color palette and typography constants
   - Build common component library (buttons, inputs, cards, badges, avatars)
   - Implement bottom navigation bar

2. **Implement Authentication:**
   - Modify existing login screen to match Figma style
   - Create sign up screen from Figma design (`536:4349`)
   - Generate forgot password screen following design patterns
   - Integrate Firebase Auth with Google OAuth

3. **Build Core Pact Features:**
   - Create pact management screens with countdown timers
   - Implement consolidated pact creation flow
   - Build evidence submission with media handling
   - Set up Firestore data models and services

4. **Add Social & Profile Features:**
   - Modify home/feed screen
   - Create friends list and chat interfaces
   - Implement profile screens with post grid
   - Add like/comment functionality

5. **Implement Notifications & Polish:**
   - Configure FCM for background notifications
   - Implement all PRD animations
   - Test across both themes
   - Optimize performance and media handling

### Confirmation Required

Please confirm you're ready to proceed with Flutter implementation. Once you give approval, I'll start with the design system foundation and work through each implementation area systematically.

---

**Status:** ✅ Planning complete - Ready to begin implementation upon your approval
