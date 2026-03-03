# Product Requirements Document (PRD)

## Focus or Else (FoE) - Mobile Application

**Version:** 1.0  
**Date:** March 2, 2026  
**Team:** CS206 G3T2  
**Platform:** Flutter (iOS & Android)  
**Figma Design:** https://www.figma.com/design/n61kR1advg5QOKNYClV2Iz/Focus-or-Else?node-id=0-1&p=f&t=1WqSjTu324wRh0lF-0

---

## 1. Executive Summary

### 1.1 Product Overview

Focus or Else (FoE) is a social accountability mobile application designed to help university students in Singapore overcome procrastination and maintain consistency with their goals. By combining social accountability, pre-agreed consequences, and gamification, FoE transforms productivity from a solo struggle into an engaging, socially-enforced commitment system.

### 1.2 Problem Statement

University students have access to countless productivity apps, yet they still struggle with procrastination and consistency. Key problems include:

- **The Willpower Deficit**: Existing apps assume self-discipline, which procrastinating students lack
- **The Temporal Disconnect**: Future rewards (exams in 3 months) feel abstract vs. immediate gratification
- **The Pressure Paradox**: High academic pressure sometimes causes more procrastination
- **The Social Isolation of Productivity**: Students are socially connected but productivity remains a solo journey

### 1.3 Target Market

**Primary Users:** University students in Singapore, ages 19-23

- Education: NUS, NTU, SMU, SIM, SUTD, and polytechnics
- Income: S$800-2,000/month
- Tech-native, active on social platforms (Instagram, Telegram, TikTok)
- Motivated by peer perception and social validation

---

## 2. Product Vision & Goals

### 2.1 Vision Statement

To become the leading social accountability platform that helps students transform good intentions into consistent actions through friend-enforced commitments and playful consequences.

### 2.2 Product Goals

1. **Behavioral Change**: Increase task completion rate by 50% compared to traditional to-do apps
2. **User Engagement**: Achieve 4+ sessions per week average user activity
3. **Social Network Growth**: Viral growth through friend-based verification (minimum 2 users per pact)
4. **Retention**: 60% 30-day retention rate
5. **Market Penetration**: Reach 5,000+ active users across Singapore universities within 6 months of launch

### 2.3 Success Metrics

- **Primary KPI**: Task completion rate (target: 70%+)
- **Engagement**: Daily Active Users (DAU) / Monthly Active Users (MAU) ratio
- **Social**: Average number of accountability partners per user
- **Retention**: Week-1, Week-4, and Week-12 retention rates
- **Monetization**: Premium conversion rate (target: 5-8%)

---

## 3. User Personas

### Persona 1: Chloe Lim - The Socially-Driven Scholar

- **Age:** 21, Year 2 Business Student (SMU)
- **Income:** S$1,200/month
- **Pain Points:** Vague deadlines, social media spiral, guilt-procrastination loop
- **Motivation:** Social pressure, maintaining reputation, achieving consulting internship
- **Quote:** _"If Sarah's going to see me not finishing? That's different."_

### Persona 2: Wei Qiang - The Tech-Head Optimizer

- **Age:** 23, Final Year CS Student (NTU)
- **Income:** S$2,200/month
- **Pain Points:** Internal bargaining, lack of immediate consequences, perfectionism
- **Motivation:** Landing FAANG job, building consistent LeetCode habit
- **Quote:** _"If there's no skin in the game, it's not a commitment — it's just a suggestion."_

### Persona 3: Maya Tan - The Overwhelmed Overachiever

- **Age:** 20, Year 2 Double Degree (NUS)
- **Income:** S$900/month
- **Pain Points:** Overcommitment, planning without execution, decision fatigue
- **Motivation:** Managing multiple commitments effectively
- **Quote:** _"FoE doesn't let me reschedule my way out of commitments. That's the kind of rigidity I need."_

---

## 4. Functional Requirements

### 4.1 User Authentication & Onboarding

**Priority:** P0 (Critical)

#### FR-1.1: User Registration

- Support sign-up via Google (OAuth)
- Support sign-up via Apple (OAuth)
- Support email/password registration
- Collect user profile: username, display name, profile picture
- Verify .edu email for student status (optional, unlocks student perks)

#### FR-1.2: Onboarding Flow

- Welcome screen explaining core concept
- Quick tutorial on creating first pact
- Prompt to add at least one friend
- Set notification preferences

### 4.2 Pact Creation & Management

**Priority:** P0 (Critical)

#### FR-2.1: Create Pact - Quick Mode

- **Task Definition**: Text input (150 character limit)
- **Deadline**: Date and time picker with "irreversible" indicator
- **Recurrence**: None, Daily, Weekly, Monthly
- **Verification Method**: Friend or AI
- **Friend Selection**: Choose from friends list or invite via link
- **Consequence**: Select from consequence library
- **Contract Summary**: Review screen before sealing
- **Seal Pact**: Tap-and-hold gesture to confirm

**Time Constraint:** Max 60 seconds to create a pact (UX optimization)

#### FR-2.2: Smart Defaults

- Default verification: Friend (most effective based on research)
- Default consequence: System suggests based on user history and task type
- Common task templates: Study session, Exercise, Reading, Coding practice

#### FR-2.3: Active Pact Limits

- Free users: Maximum 3 active pacts simultaneously
- Premium users: Maximum 10 active pacts simultaneously
- Prevents overwhelm and maintains focus

#### FR-2.4: Pact Details View

- Large countdown timer (HH:MM:SS)
- Task description and category tags
- Verifier information and status
- "The Stakes" section showing consequence
- Activity feed (comments, friend views)
- "Submit Proof" CTA button

### 4.3 Evidence Submission & Verification

**Priority:** P0 (Critical)

#### FR-3.1: Submit Evidence (User)

- Upload photos (up to 5, max 5MB each)
- Upload videos (up to 2, max 30MB each)
- Written explanation (minimum 50 words for text-based tasks)
- Markdown support for formatting
- Preview before submission
- Submit to designated verifier

#### FR-3.2: Review Evidence (Verifier)

- View submitted media and text
- See user's current streak and reliability stats
- Approve or Reject evidence
- Provide feedback/comments
- **Rejection flow**: User has 1 hour to resubmit before penalty triggers

#### FR-3.3: AI Verification (Optional)

- Text analysis: Check for coherence, length, relevance
- Image analysis: Basic content verification
- Video analysis: Duration and basic validation
- Generate "fairness score" to assist human verifier
- Note: AI is support layer; human verifier has final say

### 4.4 Consequences System

**Priority:** P0 (Critical)

#### FR-4.1: Consequence Library

**Social Consequences:**

- The Public Apology: Post video saying "I let my inner sloth win today"
- Unfiltered Confession: Post photo of cluttered space
- The "Roast Me" Prompt: AI generates roast; user posts with selfie
- The Fan Club: Write 50-word tribute to friend's productivity

**Effort-Based Consequences:**

- The Fitness Penalty: 20 push-ups or 1-minute plank video
- The Hand-Written Note: Write "I will not procrastinate" 20 times
- The Knowledge Check: AI quiz on random topic (must score 80%+)

**Currency-Based Consequences:**

- The Redistribution: Transfer coins to friend
- The Burn: Percentage of coins deleted
- The Voucher Freeze: Cannot redeem for 48-72 hours

**Status-Based Consequences:**

- The "Chicken" Badge: Failure icon for 3 days
- The Blackout: Profile picture replaced with default avatar
- The Streak Breaker: Consistency score penalty

**Playful Consequences:**

- The Lyricist: Record singing chorus of cheesy pop song
- The Bad Fashion Statement: Photo in mismatched outfit
- The AI Puppet: AI rewrites bio for 24 hours

#### FR-4.2: Consequence Selection Methods

- User selects from library (default)
- "Mystery Consequence" - user commits to severity level without knowing specific penalty
- Friend sets consequence (experimental feature)
- Random consequence generator

#### FR-4.3: Consequence Execution

- Automatic trigger if deadline missed and no resubmission
- In-app posting mechanism (not external platforms)
- Time-limited consequences (e.g., 24-hour bio change)
- Consequence completion verification

### 4.5 Social Features

**Priority:** P0 (Critical)

#### FR-5.1: Friends System

- Add friends via username search
- Send/accept friend requests
- View friends list with activity status
- See friends' active pacts (privacy settings respected)
- Direct messaging for pact-related communication

#### FR-5.2: Feed (Home Page)

- Vertical scrolling feed (TikTok-style)
- Display friends' completed pacts
- Show consequence posts (when applicable)
- Like and comment functionality
- Filter by: All Friends, Close Friends, Trending

#### FR-5.3: Notifications

- Pact deadline reminders: 6 hours, 2 hours, 1 hour, 15 minutes
- Evidence pending review
- Evidence approved/rejected
- Friend created new pact
- Friend completed pact
- Comments on your posts
- Push notifications with customizable preferences

### 4.6 Gamification & Progression

**Priority:** P1 (High)

#### FR-6.1: Coins System

- **Earning**: Complete pacts to earn coins (scaled by task difficulty and consistency)
   - Easy task: 10 coins
   - Medium task: 25 coins
   - Hard task: 50 coins
   - Streak bonus: +5 coins per day in streak
- **Spending**: Use coins for consequence payments
- **Redemption**: Exchange coins for real vouchers (Grab, Foodpanda, Gong Cha, etc.)
   - 500 coins = S$5 voucher
   - 1000 coins = S$12 voucher

#### FR-6.2: Stats & Tracking

- Current streak (consecutive days with completed pacts)
- Success rate percentage
- Total pacts created/completed
- Reliability score (0-100, based on completion rate and streak)
- Weekly/monthly summaries
- Charts showing completion patterns

#### FR-6.3: Badges & Achievements

- Milestone badges: 10, 50, 100, 500 pacts completed
- Streak achievements: 7-day, 30-day, 100-day streak
- Category mastery: Complete 50 pacts in one category
- Perfect week: Complete all pacts for 7 consecutive days
- Social butterfly: Help verify 100 pacts

### 4.7 Profile Management

**Priority:** P1 (High)

#### FR-7.1: User Profile

- **Posts Tab**: Grid view of pact evidence and consequence posts
- **Stats Tab**: Charts showing performance metrics
- **Integrations Tab**: Connect Apple Health, Google Calendar
- Edit profile: bio, profile picture, username
- Privacy settings: Who can see your pacts, who can send requests

#### FR-7.2: Profile Visibility

- Public stats (for friends): Reliability score, current streak
- Private history: Detailed analytics only visible to user
- Consequence posts: Visible according to user privacy settings

### 4.8 Settings & Preferences

**Priority:** P2 (Medium)

#### FR-8.1: App Settings

- Notification preferences (per notification type)
- Default pact settings
- Privacy controls
- Theme selection (Light/Dark mode)
- Language preferences
- Account management (delete account, export data)

---

## 5. Non-Functional Requirements

### 5.1 Performance

**Priority:** P0 (Critical)

- **App Launch Time**: < 2 seconds on mid-range devices
- **Pact Creation Time**: < 60 seconds (including user input)
- **Feed Load Time**: < 1.5 seconds for initial 10 posts
- **Media Upload**: Support background uploads with progress indicator
- **Offline Support**: Cache pact details and allow evidence prep offline; sync when online

### 5.2 Security & Privacy

**Priority:** P0 (Critical)

- **Authentication**: OAuth 2.0 for Google/Apple sign-in
- **Data Encryption**: All data encrypted in transit (HTTPS/TLS 1.3) and at rest
- **Media Storage**: Secure cloud storage with access controls (AWS S3 or similar)
- **Privacy Controls**: Users control visibility of pacts and posts
- **Data Retention**: Clear policy on media deletion after pact resolution
- **PDPA Compliance**: Comply with Singapore Personal Data Protection Act

### 5.3 Scalability

**Priority:** P1 (High)

- **User Base**: Support 10,000 concurrent users initially
- **Media Storage**: Scalable cloud storage solution
- **Database**: NoSQL (Firebase Firestore or similar) for flexible scaling
- **Push Notifications**: Reliable delivery service (Firebase Cloud Messaging)

### 5.4 Usability

**Priority:** P0 (Critical)

- **Intuitive Navigation**: Bottom navigation bar with max 4-5 tabs
- **Accessibility**: Support screen readers, adjustable font sizes
- **Error Handling**: Clear error messages with actionable next steps
- **Loading States**: Skeleton screens and progress indicators
- **Feedback**: Haptic feedback for critical actions (sealing pact)

### 5.5 Reliability

**Priority:** P0 (Critical)

- **Uptime**: 99.5% uptime target
- **Deadline Accuracy**: Consequences trigger within 5 minutes of missed deadline
- **Data Backup**: Automatic daily backups
- **Error Recovery**: Graceful degradation if services unavailable

### 5.6 Compatibility

**Priority:** P0 (Critical)

- **iOS**: iOS 13.0 and above
- **Android**: Android 8.0 (API level 26) and above
- **Screen Sizes**: Support phones and tablets
- **Network**: Function on 3G, optimized for 4G/5G/WiFi

---

## 6. Technical Architecture

### 6.1 Technology Stack

#### Frontend

- **Framework**: Flutter 3.x
- **State Management**: Provider or Riverpod
- **Navigation**: Go Router
- **Local Storage**: Shared Preferences for settings, SQLite for offline cache
- **Media Handling**: image_picker, video_player packages

#### Backend

- **Platform**: Firebase (Serverless)
   - **Authentication**: Firebase Auth
   - **Database**: Cloud Firestore
   - **Storage**: Firebase Storage
   - **Functions**: Cloud Functions for deadline triggers and notifications
   - **Messaging**: Firebase Cloud Messaging (FCM)
- **Alternative**: Node.js/Express with MongoDB (if more control needed)

#### AI Integration

- **Provider**: OpenAI API or Google Gemini API
- **Use Cases**:
   - Generate roast captions
   - Verify written reflections
   - Task difficulty classification
   - Content moderation

#### Payment & Rewards

- **In-app Purchases**: App Store / Google Play billing
- **Voucher API**: Integration with reward platforms (in future iterations)

### 6.2 Data Models

#### User

```
{
  userId: string,
  email: string,
  username: string,
  displayName: string,
  profilePictureUrl: string,
  bio: string,
  stats: {
    currentStreak: number,
    longestStreak: number,
    totalPacts: number,
    completedPacts: number,
    reliabilityScore: number,
    coins: number
  },
  friends: [userId],
  settings: {
    notificationPreferences: {},
    privacySettings: {}
  },
  createdAt: timestamp,
  lastActiveAt: timestamp
}
```

#### Pact

```
{
  pactId: string,
  userId: string,
  task: string,
  category: string,
  deadline: timestamp,
  recurrence: enum (none, daily, weekly, monthly),
  verificationType: enum (friend, ai),
  verifierId: string,
  consequenceType: string,
  consequenceDetails: {},
  status: enum (active, pending_verification, completed, failed),
  evidence: {
    mediaUrls: [string],
    explanation: string,
    submittedAt: timestamp
  },
  verificationResult: {
    approved: boolean,
    feedback: string,
    verifiedAt: timestamp
  },
  createdAt: timestamp,
  completedAt: timestamp
}
```

#### Consequence Post

```
{
  postId: string,
  userId: string,
  pactId: string,
  consequenceType: string,
  mediaUrl: string,
  caption: string,
  likes: [userId],
  comments: [
    {
      commentId: string,
      userId: string,
      text: string,
      createdAt: timestamp
    }
  ],
  expiresAt: timestamp,
  createdAt: timestamp
}
```

### 6.3 API Endpoints (if using custom backend)

**Authentication**

- `POST /auth/register` - Create new user
- `POST /auth/login` - Login user
- `POST /auth/logout` - Logout user

**Pacts**

- `POST /pacts` - Create new pact
- `GET /pacts/:pactId` - Get pact details
- `GET /pacts/active` - Get user's active pacts
- `GET /pacts/history` - Get completed/failed pacts
- `PUT /pacts/:pactId/evidence` - Submit evidence
- `PUT /pacts/:pactId/verify` - Verify evidence

**Social**

- `GET /friends` - Get friends list
- `POST /friends/request` - Send friend request
- `PUT /friends/request/:requestId` - Accept/reject request
- `GET /feed` - Get social feed
- `POST /posts/:postId/like` - Like post
- `POST /posts/:postId/comment` - Comment on post

**User**

- `GET /users/:userId` - Get user profile
- `PUT /users/:userId` - Update profile
- `GET /users/:userId/stats` - Get user stats

---

## 7. User Stories & Acceptance Criteria

### Epic 1: Onboarding & Account Setup

**US-1.1: As a new user, I want to quickly sign up so I can start using the app immediately**

- AC: Sign-up with Google/Apple completes in < 30 seconds
- AC: Username is validated for uniqueness
- AC: Profile picture can be uploaded or auto-imported

**US-1.2: As a new user, I want to understand how the app works without reading a manual**

- AC: Onboarding tutorial shows key features in < 2 minutes
- AC: User can skip tutorial if desired
- AC: Tutorial can be accessed again from settings

### Epic 2: Creating Accountability

**US-2.1: As a student, I want to create a pact for my study goal so someone holds me accountable**

- AC: Can create pact in < 60 seconds
- AC: Deadline cannot be in the past
- AC: Must select at least one verification method
- AC: Consequence must be selected before sealing
- AC: Confirmation screen shows all pact details

**US-2.2: As a user, I want to use smart defaults so I don't have to make too many decisions**

- AC: App suggests appropriate consequence based on task type
- AC: Common task templates available
- AC: Can override any default setting

**US-2.3: As a friend, I want to receive pact verification requests so I can help my friend stay accountable**

- AC: Receive in-app notification when friend creates pact with me as verifier
- AC: Can accept or decline being a verifier
- AC: Can see pact details before accepting

### Epic 3: Staying on Track

**US-3.1: As a user, I want to receive timely reminders so I don't forget my pact deadline**

- AC: Receive notifications at 6hr, 2hr, 1hr, 15min before deadline
- AC: Can customize notification timing
- AC: Notifications show task and consequence

**US-3.2: As a user, I want to see how much time I have left so I can plan my time**

- AC: Countdown timer visible on pact detail page
- AC: Timer updates in real-time
- AC: Visual warning when < 1 hour remains

### Epic 4: Proving Completion

**US-4.1: As a user, I want to submit proof of task completion so my verifier can approve it**

- AC: Can upload up to 5 photos
- AC: Can upload up to 2 videos
- AC: Must write minimum 50-word explanation for text tasks
- AC: Can preview submission before sending
- AC: Receive confirmation when submitted

**US-4.2: As a verifier, I want to review evidence fairly so I'm being a good friend**

- AC: Can view all submitted media clearly
- AC: Can see user's current streak (provides context)
- AC: Can approve or reject with feedback
- AC: If rejecting, must provide reason

**US-4.3: As a user, I want one more chance if my evidence is rejected so minor issues don't trigger harsh consequences**

- AC: Get 1-hour grace period after rejection
- AC: Can resubmit with improvements
- AC: Consequence only triggers if no valid resubmission

### Epic 5: Facing Consequences

**US-5.1: As a user who failed a pact, I want clear instructions on my consequence so I know what to do**

- AC: Receive notification explaining consequence
- AC: Consequence post template provided
- AC: Deadline to complete consequence (24 hours)
- AC: Consequence completion verified

**US-5.2: As a user, I want consequences to be fair and not traumatic so I feel comfortable using the app**

- AC: All consequences pre-screened for appropriateness
- AC: No consequences involve real financial loss > S$5
- AC: Can report inappropriate consequence suggestions
- AC: Extreme consequences require explicit opt-in

### Epic 6: Social Engagement

**US-6.1: As a user, I want to see my friends' progress so I feel connected and motivated**

- AC: Feed shows friends' completed pacts
- AC: Can like and comment on posts
- AC: Can see who's currently on a streak

**US-6.2: As a user, I want to celebrate my friends' wins so we support each other**

- AC: Can react with variety of emojis/reactions
- AC: Can leave encouraging comments
- AC: Receive notification when friends react to my posts

**US-6.3: As a user, I want to see funny consequence posts so the app feels playful not punishing**

- AC: Consequence posts appear in feed
- AC: Clear labeling that it's a consequence post
- AC: Users can opt out of showing consequence posts publicly

### Epic 7: Tracking Progress

**US-7.1: As a user, I want to see my stats so I can track my improvement over time**

- AC: Current streak prominently displayed
- AC: Success rate shown as percentage
- AC: Charts show weekly/monthly patterns
- AC: Can compare current month to previous months

**US-7.2: As a user, I want to earn coins for completing pacts so I have tangible rewards**

- AC: Earn coins immediately upon pact approval
- AC: Coin amount scales with task difficulty
- AC: Streak bonuses apply automatically
- AC: Coin balance always visible

**US-7.3: As a user, I want to redeem coins for real rewards so my effort has real-world value**

- AC: Clear conversion rate (500 coins = S$5 voucher)
- AC: Voucher catalog shows available options
- AC: Redemption processed within 24 hours
- AC: Receive voucher code via app and email

---

## 8. MVP Scope & Future Features

### 8.1 MVP Features (Iteration 1 - Weeks 1-5)

**Must Have for Launch:**

- ✅ User authentication (Google OAuth)
- ✅ Friend system (add, accept, list)
- ✅ Pact creation (quick mode only)
- ✅ Active pact limits (3 for all users)
- ✅ Friend verification flow
- ✅ Evidence submission (photo + text)
- ✅ Basic consequence library (5-7 consequences)
- ✅ Simple feed (completed pacts)
- ✅ Basic profile (posts tab with grid)
- ✅ Push notifications (deadline reminders)
- ✅ Stats tracking (streak, success rate)

### 8.2 Phase 2 Features (Weeks 6-10)

- AI verification support
- Extended consequence library (15+ options)
- Coins economy (earning mechanism)
- Enhanced feed (likes, comments)
- Stats dashboard with charts
- Pact templates
- Daily/weekly recurrence
- Video evidence support

### 8.3 Phase 3 Features (Weeks 11-16)

- Voucher redemption
- Premium subscription tier
- Mystery consequences
- Group pacts (multiple participants)
- Calendar integration
- Advanced analytics
- Badges & achievements
- Dark mode

### 8.4 Future Considerations

- Study group pacts (team accountability)
- Live verification (video call)
- Habit stacking suggestions
- Desktop companion app
- Third-party integrations (Notion, Todoist)
- Peer coaching marketplace
- Institutional partnerships (universities)
- International expansion

---

## 9. Design Requirements

### 9.1 Design Principles

1. **Low Friction, High Stakes**: Easy to create pacts, hard to ignore consequences
2. **Social-First**: Feel like Instagram/TikTok, not a productivity tool
3. **Playful Not Punishing**: Consequences should be lighthearted and fair
4. **Trust & Safety**: Users feel safe sharing their goals and failures
5. **Visual Clarity**: Clear countdown timers, status indicators, CTAs

### 9.2 Key UI Components

- **Bottom Navigation**: Home (Feed), Pacts, Create (+), Friends, Profile
- **Countdown Timer**: Large, prominent, color-coded (green > yellow > red)
- **Pact Cards**: Status badge, task name, deadline, verifier, quick actions
- **Feed Posts**: Full-screen cards with visual hierarchy
- **Consequence Modal**: Clear explanation of what will happen

### 9.3 Visual Design

- **Enhanced Color Palette** (Extracted from Figma + Improvements):
   - **Background Colors:**
      - Display Background: `#0A0A0B` (Deep Black)
      - Surface Background: `#16161A` (Dark Charcoal - Navbar)
      - Card Background: `#1F1E1F` (Dark Gray - Pact cards)
      - Card Background (Elevated): `#252425` (Slightly Lighter - for hover/focus states)
      - Toggle Background: `#272424` (Medium Dark Gray)
      - Overlay: `rgba(10, 10, 11, 0.85)` (Semi-transparent black for modals)
   - **Primary/Accent Colors:**
      - Primary Accent: `#FF2659` (Hot Pink - Active state, CTAs)
      - Primary Accent (Hover): `#FF3D6E` (Lighter Hot Pink - hover states)
      - Primary Accent (Light): `#FF5580` (Even Lighter - subtle highlights)
      - Action Button Gradient: Linear gradient `135deg, #FF4757 0%, #F97316 100%` (Red to Orange)
      - Secondary Accent: `#FF6B9D` (Soft Pink - for secondary actions, badges)
      - Tertiary Accent: `#FC4C6A` (Coral Red - for special highlights)
      - Interactive Blue: `#408BEC` (Sky Blue - Verification badges)
      - Interactive Blue (Hover): `#5A9EF0` (Lighter Blue - hover states)
   - **Border & Divider Colors:**
      - Border: `#757575` (Medium Gray)
      - Border (Subtle): `#3A3A3A` (Darker Gray - for less prominent dividers)
      - Border (Accent): `#FF2659` with 30% opacity (Pink tinted borders)
      - Red Accent Underline: Gradient from `rgba(223, 12, 12, 0.8)` to `rgba(223, 12, 12, 0.2)`
   - **Text Colors:**
      - Primary Text: `#FFFFFF` (White)
      - Secondary Text: `#B0B0B0` (Light Gray)
      - Tertiary Text: `#757575` (Medium Gray - timestamps, metadata)
      - Text on Accent: `#FFFFFF` (White text on pink/red backgrounds)
   - **Semantic Colors:**
      - Success: `#10B981` (Green) - for completed states
      - Success (Light): `#34D399` (Lighter Green - for success glow)
      - Warning: `#F59E0B` (Orange) - for at-risk pacts
      - Warning (Light): `#FBBF24` (Lighter Orange - for warning glow)
      - Danger: `#EF4444` (Red) - for failed states
      - Danger (Light): `#F87171` (Lighter Red - for danger glow)
      - Info: `#408BEC` (Blue) - for informational states

- **Subtle Gradients:**
   - **Card Gradients** (for depth and visual interest):
      - Pact Card: `linear-gradient(135deg, #1F1E1F 0%, #252425 100%)`
      - Elevated Card: `linear-gradient(135deg, #252425 0%, #2A2829 100%)`
      - Active Card Overlay: `linear-gradient(135deg, rgba(255, 38, 89, 0.05) 0%, rgba(249, 115, 22, 0.05) 100%)`
   - **Button Gradients:**
      - Primary CTA: `linear-gradient(135deg, #FF4757 0%, #F97316 100%)`
      - Secondary CTA: `linear-gradient(135deg, #FF2659 0%, #FF5580 100%)`
      - Disabled: `linear-gradient(135deg, #3A3A3A 0%, #2A2829 100%)`
   - **Background Accents:**
      - Top Fade: `linear-gradient(180deg, rgba(255, 38, 89, 0.03) 0%, transparent 100%)` (subtle pink fade from top)
      - Bottom Fade: `linear-gradient(0deg, rgba(10, 10, 11, 0.8) 0%, transparent 100%)` (fade to black at bottom)
   - **Timer Gradients** (based on urgency):
      - Safe (>2hr): `linear-gradient(135deg, #10B981 0%, #34D399 100%)`
      - Warning (1-2hr): `linear-gradient(135deg, #F59E0B 0%, #FBBF24 100%)`
      - Urgent (<1hr): `linear-gradient(135deg, #EF4444 0%, #FF4757 100%)`

- **Glow Effects:**
   - **Active Pact Card:** `box-shadow: 0px 0px 20px rgba(255, 38, 89, 0.15), 0px 4px 10px rgba(0, 0, 0, 0.3)`
   - **Primary CTA Button:** `box-shadow: 0px 10px 15px -3px rgba(255, 71, 87, 0.3), 0px 4px 6px -4px rgba(255, 71, 87, 0.3)`
   - **Urgent Countdown Timer:** `box-shadow: 0px 0px 30px rgba(239, 68, 68, 0.4), 0px 0px 60px rgba(239, 68, 68, 0.2)` (pulsing)
   - **Success Notification:** `box-shadow: 0px 0px 20px rgba(16, 185, 129, 0.3), 0px 4px 12px rgba(16, 185, 129, 0.2)`
   - **Coin Earned:** `box-shadow: 0px 0px 25px rgba(249, 115, 22, 0.5), 0px 0px 50px rgba(255, 71, 87, 0.3)` (sparkle effect)
   - **Badge Unlock:** `box-shadow: 0px 0px 30px rgba(255, 107, 157, 0.4), 0px 0px 60px rgba(255, 38, 89, 0.2)` (achievement glow)
   - **Card Hover State:** `box-shadow: 0px 0px 15px rgba(255, 38, 89, 0.1), 0px 4px 8px rgba(0, 0, 0, 0.2)`
   - **Input Focus:** `box-shadow: 0px 0px 0px 3px rgba(255, 38, 89, 0.25)` (focus ring)

- **Typography**: Inter font family (Bold, Semi-Bold, Regular, Medium weights), Modern sans-serif fallback (SF Pro / Roboto)
   - **Font Sizes:**
      - Display: 28px (page headers)
      - Headline: 18-20px (card titles, pact names)
      - Body: 14-16px (descriptions, labels)
      - Caption: 12px (timestamps, metadata)
      - Button: 16px (CTA buttons)
   - **Line Heights:** 1.4 for body text, 1.2 for headings
   - **Letter Spacing:** -0.02em for headings, normal for body

- **Iconography**: Tabler Icons, rounded and friendly icon style, 24px base size
- **Imagery**: User-generated content prominent with white rounded containers (10px border-radius)
- **Border Radius Standards:**
   - Cards: 12px
   - Buttons: 10-20px (depending on size)
   - Badges: 10px
   - Inputs: 8px
   - Modals: 16px
   - Avatar: 50% (circular)

### 9.4 Interaction Design

- **Pact Sealing**: Tap-and-hold gesture (builds commitment)
- **Evidence Review**: Swipe gestures for approve/reject
- **Feed Navigation**: Vertical scroll with infinite load
- **Haptic Feedback**: On critical actions (seal pact, submit evidence, badge unlocks)

### 9.5 Micro-Animations

**Purpose**: Provide visual feedback, guide attention, and create delight without overwhelming the user.

#### Loading & Transitions

- **Page Transitions**: 300ms ease-in-out fade + slide (20px vertical offset)
- **Card Entry**: Staggered fade-in with 100ms delay between cards, slide up from 30px
- **Modal Entry**: Scale from 0.95 to 1.0 with fade-in over 250ms, backdrop fade-in 200ms
- **Modal Exit**: Scale to 0.95 with fade-out over 200ms

#### Interactive Elements

- **Button Press**:
   - Scale down to 0.96 on press (100ms)
   - Release: Scale back to 1.0 + brief glow pulse (200ms)
   - Disabled state: No animation, reduced opacity to 0.5
- **Toggle Switch**:
   - Slide animation 250ms ease-out
   - Background color transition 200ms
   - Knob scale pulse 1.0 → 1.1 → 1.0 over 300ms
- **Tab Selection**:
   - Underline slide animation 300ms cubic-bezier(0.4, 0.0, 0.2, 1)
   - Text color fade 200ms
   - Scale active tab text to 1.05 briefly (150ms)

#### Countdown Timer

- **Normal State** (>2hr): Gentle scale pulse 1.0 → 1.02 → 1.0 every 3 seconds
- **Warning State** (1-2hr): Moderate pulse 1.0 → 1.04 → 1.0 every 2 seconds + color shift animation
- **Urgent State** (<1hr): Aggressive pulse 1.0 → 1.08 → 1.0 every 1 second + glow pulse + haptic every 5 seconds
- **Final Minute** (<60s): Continuous pulse with red glow, numbers flip animation every second

#### Success & Feedback Animations

- **Task Completed**:
   - Checkmark draw animation (SVG path) over 400ms
   - Card background flashes green gradient briefly (300ms)
   - Confetti burst from center (1s duration, 15-20 particles)
   - Coin counter increments with spring animation (500ms)
- **Streak Extended**:
   - Flame icon flicker animation (300ms)
   - Number count-up animation with easing (600ms)
   - Badge scale bounce 1.0 → 1.2 → 0.95 → 1.0 over 500ms
- **Badge Unlocked**:
   - Badge zooms in from 0.3 to 1.2 to 1.0 (600ms bounce)
   - Radial glow pulse expands from center (800ms)
   - Sparkle particles orbit badge (2s loop)
   - Title text types in character by character (40ms per character)

#### Failure & Consequence Animations

- **Task Failed**:
   - Card shake animation (horizontal vibration: -4px, 4px, -2px, 2px over 400ms)
   - Red overlay fades in and out (500ms)
   - Icon changes with rotation animation (300ms)
- **Consequence Trigger**:
   - Modal slides up from bottom with bounce (400ms)
   - Warning icon pulses with danger glow (looping)
   - Timer countdown with flip animation for digits

#### Social & Feed Animations

- **Like Animation**:
   - Heart icon scale 1.0 → 1.3 → 1.0 with rotation 0° → 12° → 0° (400ms)
   - Color fill animation from bottom to top (300ms)
   - Small pink particle burst (4-6 particles, 500ms)
- **Comment Added**:
   - New comment slides in from right with fade (300ms)
   - Avatar bounces slightly on entry (200ms)
- **Feed Refresh**:
   - Pull-to-refresh indicator rotates (looping)
   - Content items fade and slide up with stagger (100ms between items)
- **Post Uploaded**:
   - Progress ring animation (stroke-dasharray animation)
   - Success checkmark with green flash (300ms)

#### Progress & Stats Animations

- **Progress Bar Fill**:
   - Animated width increase over 800ms with ease-out
   - Shimmer effect passes over filled portion (1.5s)
   - Milestone markers pop in with scale bounce when reached
- **Number Counter** (coins, streaks, stats):
   - Count-up animation with easing (400-800ms depending on value change)
   - Brief scale pulse when value increases (200ms)
- **Chart Rendering**:
   - Bars/lines draw in from left to right (1s stagger)
   - Data points appear with small bounce (100ms delay between points)

#### Skeleton Loading

- **Content Loading**:
   - Shimmer gradient animation passing left to right (1.5s loop)
   - Pulse opacity 0.5 → 0.7 → 0.5 (1.5s loop)
   - Items fade in as they load (300ms)

#### Notification Animations

- **New Notification**:
   - Slide down from top with bounce (400ms)
   - Badge counter increments with spring animation (300ms)
   - Notification icon shakes briefly (200ms)
   - Auto-dismiss slides up after 3s (300ms)
- **In-App Alert**:
   - Toast notification slides up from bottom (300ms)
   - Progress bar animates to show time remaining (3-5s)
   - Swipe to dismiss with follow-through animation

#### Timing Guidelines

- **Micro-interactions**: 100-300ms (instant feel)
- **Transitions**: 300-500ms (smooth but not slow)
- **Celebrations**: 500-1000ms (allow moment to appreciate)
- **Loading states**: Loop until loaded (max 2s before showing message)
- **Respect reduced motion**: All animations should have reduced-motion alternatives (simple fades or instant transitions)

#### Animation Performance

- Use `transform` and `opacity` properties (GPU accelerated)
- Avoid animating `width`, `height`, `top`, `left` (causes layout recalculation)
- Use `will-change` sparingly and only during animation
- Limit concurrent animations to 5-7 elements
- Test on lower-end Android devices (target 60fps minimum)

### 9.6 Accessibility

- **WCAG 2.1 AA Compliance**: Color contrast ratios, text sizes
- **Screen Reader Support**: Semantic labels on all interactive elements
- **Text Scaling**: Support iOS/Android system font sizes
- **Reduced Motion**: Respect user's motion preferences

---

## 10. Quality Assurance

### 10.1 Testing Strategy

#### Unit Testing

- Test business logic components
- Test data models and validation
- Test utility functions
- Target: 80% code coverage

#### Integration Testing

- Test API integrations
- Test Firebase services
- Test payment flows
- Test notification delivery

#### UI Testing

- Test critical user flows (create pact, submit evidence)
- Test navigation between screens
- Test form validation
- Use Flutter integration tests

#### User Acceptance Testing (UAT)

- Beta test with 20-30 university students
- A/B test consequence selection mechanisms
- Gather feedback on onboarding flow
- Validate notification timing effectiveness

### 10.2 Performance Testing

- Load testing: 100 concurrent users creating pacts
- Media upload stress testing
- App memory usage profiling
- Battery consumption testing

### 10.3 Security Testing

- Penetration testing for authentication
- Data encryption verification
- Input validation and sanitization
- Privacy controls validation

---

## 11. Launch & Rollout Plan

### 11.1 Pre-Launch (Weeks 1-4)

- ✅ Complete MVP development
- ✅ Internal testing with development team
- ✅ Closed beta with 10 classmates (CS206 cohort)
- ✅ Iterate based on feedback
- ✅ Create marketing materials
- ✅ Set up app store listings

### 11.2 Soft Launch (Weeks 5-6)

- Launch to 50-100 users at one campus (e.g., NUS)
- Monitor metrics closely
- Rapid bug fixing
- Gather qualitative feedback
- Refine onboarding based on drop-off analysis

### 11.3 Public Launch (Week 7)

- Submit to App Store and Google Play
- Launch at 3 major universities (NUS, NTU, SMU)
- Social media campaign (Instagram, TikTok)
- Campus ambassador program
- Monitor server load and scale as needed

### 11.4 Post-Launch (Weeks 8-12)

- Weekly feature releases
- Community management
- Bug fixes and performance optimization
- Introduce premium tier (Week 10)
- Evaluation for expansion to polytechnics

---

## 12. Risk Management

### 12.1 Technical Risks

| Risk                                      | Impact | Probability | Mitigation                                                                    |
| ----------------------------------------- | ------ | ----------- | ----------------------------------------------------------------------------- |
| Firebase scaling issues                   | High   | Low         | Implement Cloud Functions optimization; have migration plan to custom backend |
| Media storage costs exceed budget         | Medium | Medium      | Implement file size limits; compress media; set up alerts for costs           |
| Push notifications not delivered reliably | High   | Medium      | Use FCM with fallback; implement in-app notification polling                  |
| AI API costs too high                     | Medium | Medium      | Cache AI responses; rate limit AI features; use tiered usage                  |

### 12.2 Product Risks

| Risk                                                  | Impact | Probability | Mitigation                                                                 |
| ----------------------------------------------------- | ------ | ----------- | -------------------------------------------------------------------------- |
| Users select easy consequences (validated in testing) | High   | High        | ✅ Implement "Mystery Consequence" and friend-set consequences             |
| Pact creation flow too complex (validated in testing) | High   | Medium      | ✅ Streamline to Quick Pact mode; implement smart defaults                 |
| Not enough friends using app                          | High   | Medium      | Viral mechanics (every pact requires friend); referral incentives          |
| Users abandon after initial enthusiasm                | High   | High        | Optimize week-1 retention; introduce streak incentives; push notifications |
| Consequences feel too harsh or soft                   | Medium | Medium      | A/B test consequence severity; allow user feedback; iterate library        |

### 12.3 Business Risks

| Risk                                   | Impact | Probability | Mitigation                                                                       |
| -------------------------------------- | ------ | ----------- | -------------------------------------------------------------------------------- |
| Low user acquisition                   | High   | Medium      | Campus ambassador program; organic social growth; partnerships with student orgs |
| Premium conversion rate too low        | Medium | Medium      | Ensure free tier remains valuable; clear premium benefits; student pricing       |
| Voucher redemption costs unsustainable | High   | Low         | Start with limited catalog; negotiate partnerships; set redemption limits        |
| Competitor launches similar app        | Medium | Medium      | Focus on unique social features; build community; rapid iteration                |

### 12.4 Legal & Compliance Risks

| Risk                                 | Impact | Probability | Mitigation                                                                 |
| ------------------------------------ | ------ | ----------- | -------------------------------------------------------------------------- |
| Privacy violation (PDPA)             | High   | Low         | Legal review; clear privacy policy; user consent flows; data minimization  |
| Inappropriate user-generated content | Medium | Medium      | Content moderation; reporting system; community guidelines                 |
| Consequences cause actual harm       | High   | Low         | Pre-approved consequence library only; no user-defined consequences in MVP |
| Underage users                       | Low    | Low         | Require 17+ age verification; parental consent for minors                  |

---

## 13. Success Criteria

### 13.1 Launch Success (Week 7)

- [ ] 500+ registered users across 3 campuses
- [ ] 100+ daily active users
- [ ] 50+ active pacts created per day
- [ ] < 5 critical bugs reported
- [ ] App Store rating ≥ 4.0 stars

### 13.2 Month 1 Success

- [ ] 2,000+ registered users
- [ ] 30% week-1 retention
- [ ] 70%+ task completion rate
- [ ] Average 2.5 friends per user
- [ ] 5+ positive testimonials/reviews

### 13.3 Month 3 Success

- [ ] 5,000+ registered users
- [ ] 50% 30-day retention
- [ ] 500+ daily active users
- [ ] 10% premium conversion rate (if launched)
- [ ] Expand to 5+ educational institutions

### 13.4 Month 6 Success

- [ ] 10,000+ registered users
- [ ] 60% 30-day retention
- [ ] Strong viral coefficient (K > 1.2)
- [ ] Featured in App Store education category
- [ ] Break-even on operational costs

---

## 14. Constraints & Assumptions

### 14.1 Constraints

- **Timeline**: 16-week development cycle (part-time student team)
- **Budget**: Limited budget for cloud services, API costs
- **Team Size**: 6 team members with varying skill levels
- **Platform**: Mobile-only (iOS and Android)
- **Geographic**: Singapore market only for MVP
- **Resources**: Free tier Firebase; limited AI API usage

### 14.2 Assumptions

- Target users have smartphones (iOS 13+ or Android 8+)
- Target users have reliable internet access
- Users willing to connect friends for accountability
- Students respond positively to gamification
- Social pressure is effective motivator for target demographic
- Users trust app with personal goal information
- Voucher partnerships can be established

### 14.3 Dependencies

- Firebase platform availability and pricing
- App Store and Google Play approval times
- OpenAI/Gemini API availability
- Voucher partner agreements
- Beta tester availability and feedback
- University approval for on-campus marketing

---

## 15. Appendices

### Appendix A: Glossary

- **Pact**: A commitment created by a user with specific task, deadline, verifier, and consequence
- **Foe**: The friend designated as accountability partner/verifier
- **Consequence**: Pre-agreed penalty that triggers if pact deadline is missed
- **Evidence**: Proof of task completion (photos, videos, written explanation)
- **Verification**: Process of approving or rejecting evidence by friend or AI
- **Streak**: Consecutive days with at least one completed pact
- **Reliability Score**: 0-100 metric based on completion rate and consistency
- **Coins**: In-app currency earned by completing pacts
- **Feed**: Social stream showing friends' pacts and consequence posts

### Appendix B: References

- Project Proposal (January 2026)
- Iter 1.1: Problem Definition
- Iter 1.2: Research (User, Technology, Competitor, Market)
- Iter 1.3: Prototype (Figma)
- Iter 1.4: Validation Report
- Survey Results (23 respondents)
- Validation Study (6 participants)

### Appendix C: Contact Information

**Product Owner:** Clemira Jenkins  
**Technical Lead:** Kevin Saputra  
**UX/UI Lead:** Daniella Setio  
**Team:** Andrew Murty, Ling Sing Ho, Matthew Wilson

**Course:** CS206 Software Product Management  
**Institution:** Singapore Management University  
**Instructor:** [Professor Name]

---

## Document History

| Version | Date          | Author    | Changes                                       |
| ------- | ------------- | --------- | --------------------------------------------- |
| 1.0     | March 2, 2026 | G3T2 Team | Initial PRD based on Iteration 1 deliverables |

---

**End of Product Requirements Document**
