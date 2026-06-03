#!/usr/bin/env bash
set -euo pipefail

fail=0
check() {
  local pattern="$1"
  local file="$2"
  local desc="$3"
  if ! rg -q "$pattern" "$file"; then
    echo "FAIL: $desc"
    fail=1
  else
    echo "PASS: $desc"
  fi
}

check_absent() {
  local pattern="$1"
  local file="$2"
  local desc="$3"
  if rg -q "$pattern" "$file"; then
    echo "FAIL: $desc"
    fail=1
  else
    echo "PASS: $desc"
  fi
}

check "user/invite/bind" "Modules/WuKongBase/WuKongBase/Classes/WKApp.m" "login user can bind invite code"
check_absent "WKPOINT_ME_INVITE handler|WKMyInviteCodeVC" "Modules/WuKongBase/WuKongBase/Classes/WKApp.m" "normal users do not see my invite code entry"
check "forceRequestAppConfig" "Modules/WuKongBase/WuKongBase/Classes/WKAppConfig.h" "remote appconfig can be forced after binding"
check "SDWebImageDownloaderRequestModifier" "Modules/WuKongBase/WuKongBase/Classes/WKApp.m" "image downloads attach auth headers"
check "invite_code" "Modules/WuKongLogin/WuKongLogin/Classes/Login/Src/WKLoginVM.m" "login response persists invite code"
check "登录后重新拉取带 token 的 App 配置" "Modules/WuKongBase/WuKongBase/Classes/WKApp.m" "login refreshes token-scoped appconfig"
check "syncContacts" "Modules/WuKongBase/WuKongBase/Classes/WKApp.m" "binding refreshes contacts immediately"
check "WKPOINT_CATEGORY_ME sort:5900" "Modules/WuKongBase/WuKongBase/Classes/WKApp.m" "bind invite setting appears below common setting"
check "self\\.inviteCodeBoxView\\.hidden = NO" "Modules/WuKongLogin/WuKongLogin/Classes/Login/Src/WKRegisterVC.m" "register screen always shows invite input"
check "CGFloat top = self\\.inviteCodeBoxView\\.lim_bottom" "Modules/WuKongLogin/WuKongLogin/Classes/Login/Src/WKRegisterVC.m" "register button sits below invite input"
check "registerInviteOn && inviteCode\\.length == 0" "Modules/WuKongLogin/WuKongLogin/Classes/Login/Src/WKRegisterVC.m" "required invite registration validates input"
check "resp\\.inviteCode\\.length == 0" "Modules/WuKongLogin/WuKongLogin/Classes/Login/Src/WKRegisterVC.m" "successful registration persists entered invite code"
check "result\\.data\\[@\"token\"\\]" "Modules/WuKongBase/WuKongBase/Classes/WKApp.m" "scan add friend accepts qr token field"
check "@\"token\":vercode\\?:@\"\"" "Modules/WuKongBase/WuKongBase/Classes/Sections/Common/WKUserInfoVM.m" "friend apply sends qr token field"

exit "$fail"
