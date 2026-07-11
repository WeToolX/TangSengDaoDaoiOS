# App Store UGC Block User - 2026-07-11

## Requirement - CONFIRMED

Apple rejected build `1.0 (202607100022)` under Guideline 1.2 because the app has user-generated chat content and the chat details page did not expose a clear abusive-user blocking mechanism.

Confirmed direction: keep the existing report/complaint feature and expose the existing blacklist action directly on the single-chat details page.

## Architecture - CONFIRMED

- Reuse the current conversation setting blacklist flow.
- Reuse the existing backend endpoints:
  - `POST user/blacklist/{uid}`
  - `DELETE user/blacklist/{uid}`
- Do not copy unrelated friend-profile actions such as removing friendship or Moments visibility into chat details.
- Blocking keeps the existing behavior: delete the recent conversation locally, mark the channel as blacklist, update channel info, and return to the root view.

## Development Plan - CONFIRMED

- Fix the single-chat blacklist setting item so it has a unique channel setting endpoint id.
- Keep the report item and clear-chat item unchanged.
- Keep the visible single-chat order stable: report, blacklist, clear chat history.

## Acceptance Criteria - CONFIRMED

- Single-chat details page shows `拉入黑名单` when the user is not blacklisted.
- Single-chat details page shows `拉出黑名单` when the user is already blacklisted.
- Tapping `拉入黑名单` uses the existing confirmation sheet and blacklist API.
- Group chat details do not show the person blacklist action.
- `xcodebuild` generic iOS build succeeds.

## Progress

- Requirement: CONFIRMED
- Architecture: CONFIRMED
- Development: DONE
- Validation: ACCEPT_PASS
- Closure: DONE

## Validation Evidence

- `rg -n 'setMethod:@"channelsetting\.(report|blacklist|clearchat)"' Modules/WuKongBase/WuKongBase/Classes/Sections/ConversationSetting/WKConversationSettingVM.m`: confirmed distinct endpoint ids for report, blacklist, and clear-chat.
- `git diff --check`: passed.
- `xcodebuild -workspace TangSengDaoDaoiOS.xcworkspace -scheme WuKongChatiOS -configuration Release -destination 'generic/platform=iOS' build CODE_SIGNING_ALLOWED=NO`: passed.
