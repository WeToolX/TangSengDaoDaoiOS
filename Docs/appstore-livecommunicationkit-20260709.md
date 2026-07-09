# App Store LiveCommunicationKit Calling - 2026-07-09

## Requirement - CONFIRMED

China mainland remains an available App Store territory.

The app must not restore CallKit. Incoming audio/video calls should use PushKit plus LiveCommunicationKit where supported, so lock-screen/background/terminated-state calls can be surfaced by the system without CallKit.

## Architecture - CONFIRMED

- iOS 17.4 and later: register PushKit VoIP token, receive VoIP push, report the incoming conversation to LiveCommunicationKit immediately, then route accepted actions into the existing RTC join flow.
- iOS earlier than 17.4: do not use naked PushKit for calls. Use normal APNs alert notifications and enter the RTC flow after the user opens the app.
- Foreground IM command (`rtc.invite`) continues to open the existing in-app call UI.
- Background or lock-screen IM command (`rtc.invite`) must not open the in-app call UI or start the app-side ringtone directly; it must report to LiveCommunicationKit on supported systems.
- End/cancel/timeout commands must end the active RTC session and report the ended conversation event to LiveCommunicationKit when applicable.
- CallKit remains fully absent from source, Pods, and built binaries.

## Development Plan - CONFIRMED

- Keep PushKit only for iOS 17.4+ devices that can report through LiveCommunicationKit.
- Add a small Swift LiveCommunicationKit bridge because LiveCommunicationKit is Swift-only in the SDK.
- In PushKit incoming callback:
  - Parse RTC payload.
  - On iOS 17.4+, report `ConversationManager.reportNewIncomingConversation` or the suitable incoming VoIP payload API.
  - Do not directly present the in-app call UI until the user accepts from LiveCommunicationKit, unless the app is already foreground.
  - On unsupported iOS versions, complete quickly and rely on normal APNs alert fallback.
- Implement `ConversationManagerDelegate` actions:
  - `JoinConversationAction`: call existing `acceptIncomingCallWithCompletion`.
  - `EndConversationAction`: call existing reject/end flow.
  - audio activation/deactivation: route to existing RTC audio session setup/teardown.
- Preserve ordinary APNs registration for chat messages and fallback call alerts.
- Keep `UIBackgroundModes` `voip` only because PushKit is now paired with LiveCommunicationKit.
- Update RTC integration docs and server requirements:
  - Store/use VoIP token only for iOS 17.4+ LCK-capable clients.
  - Send normal APNs alert fallback for unsupported clients or failed LCK registration.

## Acceptance Criteria - CONFIRMED

- `rg "CallKit|CXProvider|CXCall|reportNewIncomingCall" TangSengDaoDao Modules Pods/Target\ Support\ Files Podfile Podfile.lock` has no active references.
- PushKit references remain only in the LiveCommunicationKit path.
- Built app links `LiveCommunicationKit.framework` and does not link `CallKit.framework`.
- App Store-oriented build succeeds from `TangSengDaoDaoiOS.xcworkspace` with scheme `WuKongChatiOS`.
- iOS 17.4+ incoming VoIP push reports a LiveCommunicationKit conversation before RTC UI presentation.
- LiveCommunicationKit answer action keeps the in-app RTC page in incoming/joining/connecting flow until join succeeds or fails.
- iOS below 17.4 does not use PushKit as a naked call wake-up path.
- Foreground RTC invite still opens `WKRTCCallViewController`.
- Background or lock-screen RTC invite received over the IM socket reports to LiveCommunicationKit instead of using the app-side incoming-call page/ringtone path.
- LiveCommunicationKit incoming call UI displays the caller nickname or remark instead of the caller UID when local profile data is available.
- Normal APNs chat notifications still work.
- iOS below 17.4 local/normal APNs call notifications open the existing RTC incoming-call page after the user taps the notification.
- iOS below 17.4 pending local call notifications open the existing RTC incoming-call page when the user manually opens the app while the invite is still valid.
- iOS below 17.4 local call notifications use the bundled RTC ring asset as notification sound when iOS can play notification sound.

## Progress

- Requirement: CONFIRMED
- Architecture: CONFIRMED
- Development: DONE
- Validation: DONE
- Closure: DONE

## Validation Evidence

- `xcodebuild -workspace TangSengDaoDaoiOS.xcworkspace -scheme WuKongChatiOS -configuration Debug -destination 'generic/platform=iOS' build CODE_SIGNING_ALLOWED=NO`: passed.
- `xcodebuild -workspace TangSengDaoDaoiOS.xcworkspace -scheme WuKongChatiOS -configuration Release -destination 'generic/platform=iOS' build CODE_SIGNING_ALLOWED=NO`: passed.
- `rg "CallKit|CXProvider|CXCall|reportNewIncomingCall|CXCallController|CXAnswerCallAction|CXEndCallAction" TangSengDaoDao Modules Pods/Target\ Support\ Files Podfile Podfile.lock`: no active code references.
- Release app binary links `PushKit.framework` and weak-links `LiveCommunicationKit.framework`; it does not link `CallKit.framework`.
- Runtime log review on 2026-07-09 showed background/lock-screen `rtc.invite` was arriving over the IM socket, not PushKit. Follow-up fix routes that path through LiveCommunicationKit as well.
- Follow-up Debug and Release generic iOS builds for the background IM invite path passed on 2026-07-09.
- Runtime log review on 2026-07-09 showed unsupported-LCK devices created the local incoming-call notification, but notification tap was not routed back to `WKRTCSessionManager`.
- Follow-up Release generic iOS build for notification tap routing passed on 2026-07-09.
- Runtime log review on 2026-07-09 showed manually opening the app after a local call notification did not route the pending invite back to `WKRTCSessionManager`.
- Follow-up local notification ringtone fix copies the bundled RTC ring asset to `Library/Sounds` before scheduling local call notifications.
- Follow-up Release generic iOS build for pending invite activation and local notification ringtone preparation passed on 2026-07-09.
- Runtime review on 2026-07-09 showed LiveCommunicationKit incoming call UI could display caller UID when `from_name` was absent.
- Follow-up Release generic iOS build for LiveCommunicationKit caller display name fallback passed on 2026-07-09.
- Runtime review on 2026-07-09 showed LiveCommunicationKit answer action could enter the in-app RTC page while the pending session was still `Idle`, causing the page to close immediately.
- Follow-up Release generic iOS build for preserving `IncomingRinging` state before LiveCommunicationKit answer passed on 2026-07-09.
