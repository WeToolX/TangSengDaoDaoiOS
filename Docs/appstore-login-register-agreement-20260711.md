# App Store Login Register Agreement - 2026-07-11

## Requirement - CONFIRMED

Apple Guideline 1.2 review requires the app to present the EULA or terms of use agreement before users register or log in.

Confirmed user request to be validated before development:

- Add an agreement area at the bottom of the login page: `我已阅读并同意 用户协议 和 隐私政策`.
- Change the register page to use the same explicit agreement checkbox style.
- If the agreement is not checked, tapping login or register must show: `请先阅读并同意用户协议和隐私政策`.
- `用户协议` and `隐私政策` must remain tappable and open the existing WebView URLs.

## Architecture - CONFIRMED

- Reuse existing configured URLs:
  - `WKApp.shared.config.userAgreementUrl`
  - `WKApp.shared.config.privacyAgreementUrl`
- Reuse existing WebView route with `WKWebViewVC`.
- Keep the change inside the login module:
  - `Modules/WuKongLogin/WuKongLogin/Classes/Login/Src/WKLoginView.m`
  - `Modules/WuKongLogin/WuKongLogin/Classes/Login/Src/WKRegisterVC.m`
- Do not change backend APIs, registration parameters, login parameters, or App Store metadata.

## Development Plan - CONFIRMED

- Add checkbox state and agreement label handling to `WKLoginView`.
- Add a callback from `WKLoginView` to open agreement links from `WKLoginVC`, or push `WKWebViewVC` directly using the existing navigation manager if dependencies are already available.
- Replace register page passive text `点击“注册”即表示已阅读并同意...` with explicit checkbox text.
- Gate login and register button actions before network calls.
- Keep existing visual style: theme color for links/check state and existing font scale.

## Acceptance Criteria - CONFIRMED

- Login page shows `我已阅读并同意 用户协议 和 隐私政策` before login.
- Register page shows `我已阅读并同意 用户协议 和 隐私政策` before registration.
- Login without checking agreement does not call login API and shows `请先阅读并同意用户协议和隐私政策`.
- Register without checking agreement does not call register API and shows `请先阅读并同意用户协议和隐私政策`.
- Tapping `用户协议` opens `WKApp.shared.config.userAgreementUrl`.
- Tapping `隐私政策` opens `WKApp.shared.config.privacyAgreementUrl`.
- Existing login, register, invite-code, and country-code behavior remains unchanged after agreement is checked.
- `git diff --check` passes.
- Release generic iOS build with `CODE_SIGNING_ALLOWED=NO` passes.

## Progress

- Requirement: CONFIRMED
- Architecture: CONFIRMED
- Development: DONE
- Validation: ACCEPT_PASS
- Closure: DONE

## Validation Evidence

- `git diff --check`: passed.
- `xcodebuild -workspace TangSengDaoDaoiOS.xcworkspace -scheme WuKongChatiOS -configuration Release -destination 'generic/platform=iOS' build CODE_SIGNING_ALLOWED=NO`: passed.
- `rg -n "BUILD SUCCEEDED|BUILD FAILED|error:" build/AppStore/agreement-build-20260711.log`: confirmed `** BUILD SUCCEEDED **`.
