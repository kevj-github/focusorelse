# Focus or Else (FoE) — Product UI/UX + Flutter Execution Plan

**Last Updated:** March 4, 2026  
**Primary Design Source:** Figma frame `samplescreens01` (`1030:4396`)  
**Execution Philosophy:** Use Figma as visual direction, but prioritize usability, consistency, accessibility, and implementation quality.

---

## 1) Plan Intent

This is the **build guide** for implementation. It is intentionally stricter and clearer than the original visual draft.

This plan:

- Uses Figma for visual language and core layouts.
- Allows deliberate divergence when UX quality, technical reliability, or accessibility improves.
- Defines screen behavior, state handling, component rules, and acceptance criteria.

---

## 2) Product UX Principles (Non-Negotiable)

1. **Fast to act:** Critical actions must be reachable in ≤2 taps from the current context.
2. **Clarity over decoration:** Every screen must communicate “what to do next” immediately.
3. **State transparency:** Deadlines, verification state, and consequences must always be visible.
4. **Social accountability first:** Friend context and public/peer consequences are not secondary features.
5. **Fail safely:** Errors should be recoverable and never lead to silent loss of user input.
6. **Accessible by default:** Contrast, tappable area, focus order, and readable hierarchy are mandatory.

---

## 3) Information Architecture

## Primary Navigation (Bottom Bar)

Order and behavior:

1. **Dashboard**
2. **Feed**
3. **Plus (+)** (center elevated action)
4. **Friends**
5. **Profile**

Rules:

- Keep labels always visible (no icon-only mode).
- Add button always opens pact creation entry point.
- Selected tab keeps in-memory state when switching tabs.
- Tab reselection scrolls to top of that tab’s primary list view.

---

## 4) Design System Specification

## Color + Theme

**Dark mode (default):**

- Background: `#0A0A0B`
- Surface: `#1F1E1F`
- Border: `#2D2D30`
- Primary action: `#FF2659`
- Accent: `#F97316`
- Text primary: white
- Text secondary: muted gray (`#9BA1A6` equivalent)

**Light mode (required):**

- Keep same semantic token names.
- Only swap token values; never hard-code alternate colors inside screens.

## Typography

- Font family: **Inter**
- Heading scale: clear visual jump between page title, section title, body.
- Avoid tiny low-contrast text for critical deadlines or consequence labels.

## Spacing + Radius

- 4pt spacing system (4, 8, 12, 16, 20, 24, 32).
- Standard card radius: 12–16.
- Touch targets: minimum 44x44.

## Motion

- Use short transitions (150–250ms) for tab/screen state change.
- Countdown urgency can pulse; avoid continuous distracting motion.
- Success moments (pact sealed, verification approved) can use stronger animation.

---

## 5) Screen-by-Screen Build Specs

## 5.1 Authentication

### Login

Purpose: Fast entry and immediate recovery path.

Required:

- Email + password sign-in.
- Google OAuth sign-in.
- “Forgot password” and “Create account” clearly visible.
- Error message area near form actions.

States:

- Idle, loading, invalid credentials, network failure, success.

UX requirements:

- Disable primary action while request is in flight.
- Preserve typed inputs on recoverable errors.

### Sign Up

Purpose: Low-friction account creation.

Required:

- Display name, email, password.
- Google OAuth option.
- Link back to login.

### Forgot Password

Purpose: Reliable account recovery.

Required:

- Email input + send reset link.
- Success confirmation with next-step microcopy.

---

## 5.2 Home (Feed)

Purpose: Social accountability visibility.

Required:

- Chronological feed of friend activity (completion/failure/consequence).
- Post card with actor, pact context, timestamp, reaction affordance.
- Empty state: “No current posts right now.”

States:

- First load, empty, populated, pagination loading, error + retry.

Divergence from Figma allowed:

- Prefer stable vertical list over complex feed interactions if it improves readability.

---

## 5.3 Pacts

### Pact Dashboard (Active / Expired)

Purpose: Show what needs action now.

Required:

- Tab switch: Active / Expired.
- Calendar strip or month navigation.
- Featured active pact card with countdown and submit evidence CTA.
- Upcoming pacts list.

Critical behavior:

- Countdown updates in real time.
- Overdue state must be visually obvious.

### Pact Details

Purpose: Single source of truth for a pact.

Required:

- Task summary, deadline, verifier, consequence, status, evidence section.
- Action area changes by role/state (owner vs verifier).

States:

- Active, waiting verification, approved, rejected, expired.

### Evidence Submission

Purpose: Prove completion clearly and quickly.

Required:

- Up to 5 photos, up to 5-minute video, optional text note.
- Pre-submit preview.
- Submission finality warning (non-editable after submit).

---

## 5.4 Create Pact Flow

Primary approach: **Consolidated flow** with progressive sections.

Sections in order:

1. Task input (150-char guidance)
2. Category
3. Deadline picker
4. Friend/verifier selection
5. Consequence selection (predefined)
6. Review
7. Seal Pact (hold-to-confirm)
8. Success confirmation

UX goals:

- Complete in ~60 seconds.
- Keep user context visible (summary panel/chips of previous choices).

Validation rules:

- Cannot seal without task, deadline, verifier, consequence.
- Inline validation, not blocking modal spam.

---

## 5.5 Friends + Chat

### Friends List

Required:

- Friend cards (avatar, status signal, streak/reliability summary).
- Entry points: open profile, open chat.

### Friend Requests

Required:

- Search users.
- Pending requests list.
- Accept/reject actions with immediate status feedback.

### 1-on-1 Chat

Required:

- Message history, input, send action.
- Basic delivery feedback.

Note:

- Figma naming may say “Friends List (updated)” while actual UX purpose is chat.

---

## 5.6 Profile

### Profile Overview

Required:

- Header (avatar, identity, core stats).
- Tabs/sections for posts and stats.

### Profile Post Grid

Required:

- 3-column media/status grid.
- Tap into post details.

### Profile Stats

Required:

- Current streak, completion rate, pact summary chart (bar chart).
- Start with simple visualizations before advanced analytics.

---

## 5.7 Notifications

Notifications are feature behavior, not full screens.

Required:

- FCM background notifications.
- Permission prompt after login context.
- In-app banner pattern for live updates while app is open.

Notification types:

- Deadline reminders
- Verifier actions required
- Friend activity
- Pact state transitions

---

## 6) Reusable Component Contract

## Required Components

1. `BottomNavBar`

- Supports 5 destinations with center primary action.
- Accepts `selectedIndex`, `onTabSelected`, `onPlusTap`.

2. `PactCard`

- Variants: featured, list, feed.
- Supports state badges and urgency visuals.

3. `CountdownTimer`

- Live ticking.
- Styling variant by urgency range.

4. `AppButton`

- Variants: primary, secondary, outline, danger.
- Loading + disabled states.

5. `AppInput`

- Label, helper, error text, icon support.

6. `AppBadge`

- Status/category variants.

7. `AppAvatar`

- Size variants + fallback initials.

8. `AppModal/BottomSheet`

- Configurable height and action slots.

---

## 7) State + Data UX Rules

## Global UI States (all screens)

Every major screen must define:

- Loading skeleton/placeholder
- Empty state
- Error state with retry
- Success feedback

## Data Rules

- Firestore is source of truth for users/pacts/friends/feed metadata.
- Firebase Storage for evidence media.
- Media uploads use compression before network transfer.

## Timer/Deadline Rules

- Time shown in local timezone.
- Use consistent urgency thresholds:
   - Normal
   - Warning
   - Critical
   - Overdue

---

## 8) Accessibility + Quality Standards

Minimum requirements:

- Contrast ratio suitable for text readability.
- Touch targets ≥ 44x44.
- Keyboard/focus-safe forms.
- Semantic labels for actionable icons.
- Screen-reader-friendly button labels for countdown/verification actions.

Content quality:

- Action text must be explicit: “Submit Evidence”, “Approve & Complete”, “Reject Evidence”.
- Avoid ambiguous labels like “Continue” when context is unclear.

---

## 9) Flutter Implementation Blueprint

## Folder Direction

Use this structure as source of truth:

```text
lib/
  theme/
  widgets/common/
  widgets/navigation/
  widgets/pacts/
  screens/auth/
  screens/home/
  screens/pacts/
  screens/create_pact/
  screens/friends/
  screens/profile/
  services/
  providers/
  models/
```

## Coding Standards

- No hard-coded visual values in screen files when a token/component exists.
- Keep business logic in providers/services; keep screens focused on presentation + orchestration.
- Prefer small composable widgets over long monolithic screen files.

---

## 10) Build Sequence (Execution Order)

1. Theme tokens + common widgets
2. Bottom navigation shell
3. Auth stack (login/signup/forgot)
4. Home feed skeleton + states
5. Pact dashboard + details + timer
6. Evidence submission flow
7. Create pact flow
8. Friends + chat + friend requests
9. Profile + stats
10.   Notifications + polish + QA

---

## 11) Definition of Done (Per Screen)

A screen is complete only if all are true:

- Matches design intent and token system.
- Handles loading/empty/error/success states.
- Supports accessibility minimums.
- Navigation in/out is fully wired.
- Analytics hooks/events added for key actions.
- No analyzer errors in changed files.

---

## 12) Figma Mapping Reference (for traceability)

Use these as source anchors, not hard constraints:

- Sign Up: `536:4349`
- Pact dashboard/state set: `635:3885`, `635:4808`, `635:5484`, `650:4493`
- Pact expired: `647:3959`
- Pact details set: `635:4689`, `635:5035`, `635:5354`, `650:4035`
- Evidence submission: `228:677`, `314:3028`
- Create pact start set: `467:2978`, `582:3095`, `650:5025`
- Create pact review: `521:3620`, `651:4768`
- Create pact success: `530:3112`, `651:4868`
- Task input section: `625:3190`
- Friends list: `631:3211`, `631:3571`
- Friends/chat variant: `607:3167`
- Friend request: `631:3502`
- Profile frame: `600:3137`
- Profile post grid: `650:4183`, `650:5887`
- Profile stats: `650:4214`, `650:5918`
- Notification lock/home: `643:3965`, `604:3311`, `635:4212`
- Warning/info modal: `405:1772581`
- SVG asset source: `651:4981`

---

## 13) Final Direction

This plan is now optimized for implementation quality, not just design inventory.

When Figma and usability conflict, choose the option that improves:

- task completion speed,
- state clarity,
- accessibility,
- consistency with system tokens and reusable components.

That decision rule should guide all upcoming screen work.

---

## 14) Current Implementation Snapshot (As-Built: March 4, 2026)

This section reflects the **actual code status** in `lib/` and should be used for sprint planning.

### Implemented

- App shell + theme tokens (`dark` theme active) and bottom nav with 5 destinations + center plus action.
- Auth stack: login, sign-up, forgot password with email/password and Google sign-in.
- Dashboard (Active/Expired): live pact loading, calendar strip, featured pact, upcoming/expired lists, refresh, loading/empty/error states.
- Create Pact consolidated flow: task/category/deadline/verifier/consequence/review + validation + success state.
- Profile redesign:
   - Editable username, bio, profile picture URL.
   - Posts tab with real post creation + Firestore-backed user post grid + post detail bottom sheet.
   - Stats tab with streak, success rate, and pact summary bar chart.
- Firestore data layer for users, pacts, friends, and posts (including user post streams).
- Storage service support for profile image/pact evidence upload methods (service level).

### In Progress / Partial

- Notification service class exists (FCM + local notification plumbing), but app-level UX wiring is still partial.
- Evidence submission backend/provider methods exist, while full user-facing evidence UI flow is not fully wired from dashboard/profile interactions.
- Settings icon now replaces profile icon in top app bar; in-app settings screen is intentionally deferred.

### Not Yet Implemented (Planned)

- Feed screen UI/UX and friend post timeline rendering.
- Friends screens (list, requests, chat).
- Dedicated notifications UX (permission timing flow, in-app banner pattern per spec).
- Advanced profile analytics (reliability score trend, long-range comparisons, integrations tab).

### Notes for Next Iteration

- Reuse `PostProvider`/`FirestoreService.streamPostsByAuthorIds(...)` to implement friend feed quickly.
- Promote current profile post composer from URL-based input to media picker + upload flow.
- Add settings screen scaffold and move notification/privacy controls there.
