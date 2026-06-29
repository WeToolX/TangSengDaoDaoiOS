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
require_pattern "tgReactionChip" "Modules/WuKongBase/WuKongBase/Classes/Sections/Messages/WKReactionBaseView.m" "iOS reactions render as embedded TG-style chips"
require_pattern "refreshReactionCellAtIndexPath" "Modules/WuKongBase/WuKongBase/Classes/Sections/Conversation/WKMessageListView.m" "iOS reaction updates refresh visible message cell immediately"
require_pattern "rowHeightChanged" "Modules/WuKongBase/WuKongBase/Classes/Sections/Conversation/WKMessageListView.m" "iOS reaction updates recalculate message row height"
require_pattern "ensureChatPasswordBeforeToggle" "Modules/WuKongBase/WuKongBase/Classes/Sections/ConversationSetting/WKConversationSettingVM.m" "iOS chat password toggle requires password setup first"
require_pattern "verifyChatPasswordIfNeeded" "Modules/WuKongBase/WuKongBase/Classes/Sections/Conversation/WKConversationVC.m" "iOS verifies chat password when entering protected chats"
require_pattern "\"login_pwd\":\\[WKMD5Util md5HexDigest:self\\.loginPwd" "Modules/WuKongBase/WuKongBase/Classes/Sections/Me/Security/WKConversationPasswordVM.m" "iOS hashes login password before setting chat password"
require_pattern "common/chatbg" "Modules/WuKongBase/WuKongBase/Classes/Sections/ConversationSetting/WKConversationSettingVM.m" "iOS chat background comes from backend list"
require_pattern "WKChatBackgroundListVC" "Modules/WuKongBase/WuKongBase/Classes/Sections/ConversationSetting/WKConversationSettingVM.m" "iOS chat background opens backend list page"
require_pattern "chatBackgroundPreviewPath" "Modules/WuKongBase/WuKongBase/Classes/Sections/ConversationSetting/WKConversationSettingVM.m" "iOS chat background list renders backend cover/url previews"
require_pattern "reactionBubbleBottomInset" "Modules/WuKongBase/WuKongBase/Classes/Sections/Messages/WKMessageCell.m" "iOS reaction chip expands message bubble bottom padding"
require_pattern "WKStickerCollectionVC" "Modules/WuKongBase/WuKongBase/Classes/Sections/Conversation/StickerStore/WKStickerMyPackagesVC.m" "iOS sticker store exposes custom sticker manager"
require_pattern "openUserTimeline:" "Modules/WuKongContacts/WuKongContacts/Classes/Src/Moments/WKMomentTimelineVC.m" "iOS moments avatar opens user timeline"
require_pattern "openUserTimelineWithActor" "Modules/WuKongContacts/WuKongContacts/Classes/Src/Moments/WKMomentTimelineVC.m" "iOS moments passes nickname when opening user timeline"
require_pattern "WKMomentMenuIconImage|WKMomentIconView" "Modules/WuKongContacts/WuKongContacts/Classes/Src/Moments/WKMomentTimelineVC.m" "iOS moments action icons keep fixed aspect size"
require_pattern "moment/feed/%@" "Modules/WuKongContacts/WuKongContacts/Classes/Src/Moments/WKMomentVM.m" "iOS user moments use backend moment feed by uid"
require_pattern "self\\.uid\\.length == 0 \\? \\[self\\.vm timelineWithPageIndex" "Modules/WuKongContacts/WuKongContacts/Classes/Src/Moments/WKMomentTimelineVC.m" "iOS only root moments page uses mixed friend feed"
require_pattern "sticker/custom" "Modules/WuKongBase/WuKongBase/Classes/Sections/Conversation/WKStickerCollectionVC.m" "iOS custom sticker upload uses backend custom endpoint"
