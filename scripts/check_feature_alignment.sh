#!/usr/bin/env bash
set -euo pipefail

ROOT="$(cd "$(dirname "$0")/.." && pwd)"

require_pattern() {
  local pattern="$1"
  local file="$2"
  local message="$3"
  if ! grep -Eq "$pattern" "$ROOT/$file"; then
    echo "FAIL: $message" >&2
    exit 1
  fi
  echo "PASS: $message"
}

require_pattern "moment/setting/%@" "Modules/WuKongContacts/WuKongContacts/Classes/Src/Moments/WKMomentVM.m" "iOS moments exposes user state endpoint"
require_pattern "user\\.info\\.momentState" "Modules/WuKongContacts/WuKongContacts/Classes/WKContactsModule.m" "iOS user card shows moments state"
require_pattern "fallbackMomentIcon" "Modules/WuKongContacts/WuKongContacts/Classes/Src/Moments/WKMomentTimelineVC.m" "iOS moments uses fallback icons for like/comment"
require_pattern "longmenus\\.receipt" "Modules/WuKongBase/WuKongBase/Classes/WKApp.m" "iOS long press has message receipt entry"
require_pattern "longmenus\\.customSticker" "Modules/WuKongBase/WuKongBase/Classes/WKApp.m" "iOS long press has custom sticker entry"
