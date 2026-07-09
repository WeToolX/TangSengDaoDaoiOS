# App Store CallKit Removal - 2026-07-09

## Requirement - CONFIRMED

Apple review rejected build `1.0 (202607061419)` because China mainland is an available territory and the app has active CallKit functionality.

Confirmed direction: keep China mainland availability, remove CallKit from the iOS app, and keep in-app VoIP audio/video calling.

## Development Plan - CONFIRMED

- Remove CallKit framework linkage from `WuKongBase`.
- Remove `CXProvider`, `CXCallController`, and all system incoming-call reporting paths.
- Keep PushKit handling only as a VoIP payload delivery path; incoming calls must open the existing in-app call UI.
- Keep RTC session, LiveKit media engine, ringtone, and app call screen behavior.
- Rename app audio setup methods so no CallKit bridge remains in the app target.

## Acceptance Criteria - CONFIRMED

- Source code outside old logs has no `CallKit`, `CXProvider`, `CXCall`, or `reportNewIncomingCall` references.
- Release build succeeds.
- The app package does not link `CallKit.framework`.
- Incoming RTC payloads still route to `WKRTCCallViewController`.

## Progress

- Requirement: CONFIRMED
- Development: DONE
- Validation: ACCEPT_PASS
- Closure: DONE
