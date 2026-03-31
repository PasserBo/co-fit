This is a concise, high-level project specification designed to serve as the "source of truth" for your AI-assisted development (Cursor/GitHub).

---

# Cloud Gym: Social Fitness via Virtual Presence

**Cloud Gym** is a "low-pressure" social fitness application that transforms individual workouts into a shared, synchronized experience. Inspired by "Idle Games" (like *Tabi Kaeru*) and focus-apps (like *Gogh*), it uses 2.5D vector avatars to represent real-time physical activity in virtual rooms.

## 1. Core Concept
* **Virtual Presence:** Users join "Rooms" (Channels) where their 2.5D avatars (Duolingo-style) perform fitness actions in sync with the user.
* **Zero-Friction Tracking:** No manual data entry. Users select "Action Cards" (e.g., 10min Squat) to trigger both the workout timer and the avatar's animation.
* **Social Interaction:** A non-intrusive "neighborhood" view allows users to peek into different gym channels to see friends' activity without the pressure of a video call.

## 2. Implementation Plan

### A. Real-Time Action Sync (via Ably)
* **Pub/Sub Architecture:** High-frequency workout data (action ID, progress, heart rate) is broadcasted via **Ably Channels**.
* **Presence API:** Ably manages real-time "In-Room" status, automatically showing/hiding avatars as users connect or disconnect.
* **State Mapping:** Incoming Ably payloads trigger **Rive State Machines**, ensuring the virtual avatar's movement matches the remote user's activity with sub-100ms latency.

### B. Identity & Persistent Data (via Firebase)
* **Authentication:** **Firebase Auth** (Apple Sign-in / Anonymous) ensures a "one-tap" onboarding experience.
* **Metadata Storage:** **Cloud Firestore** stores low-frequency data: Room configurations, user profiles (skins/stats), and gym channel memberships.
* **Hybrid Logic:** Firestore handles the "Who is in which room?" (static), while Ably handles the "What are they doing right now?" (dynamic).

### C. Visual Engine (via Rive + Flutter)
* **Skeletal Animation:** Using **Rive** for high-performance vector animations. One skeleton rig supports multiple "skins" (male/female/custom) to reduce asset overhead.
* **Isometric Hub:** The main page is a 2.5D scrollable "Neighborhood" where rooms are represented as houses. Ambient light and silhouettes indicate activity levels via Ably metadata.

### D. System Integration (iOS Focus)
* **Live Activities & Dynamic Island:** Uses **ActivityKit** to show friend activity on the lock screen.
* **Push Pipeline:** Ably Reactor Rules $\rightarrow$ Firebase Cloud Functions $\rightarrow$ **APNs** to update Dynamic Island when the app is in the background.

## 3. Tech Stack & Architecture
* **Frontend:** Flutter (iOS target).
* **State Management:** Riverpod / Provider (following Hexagonal/Clean Architecture).
* **Real-time Engine:** Ably (WebSockets).
* **Backend:** Firebase (Auth, Firestore, Cloud Functions).
* **Animation:** Rive (Vector).

## 4. MVP Roadmap
1.  **Phase 1:** Firebase Auth + Ably Presence (See who is online).
2.  **Phase 2:** Action Cards + Rive Animation Sync (See who is doing what).
3.  **Phase 3:** Room Creation & Isometric Neighborhood Hub.
4.  **Phase 4:** iOS Live Activities & HealthKit Integration.