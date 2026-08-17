# 变更记录

## 1. 2026-08-17

- 建立 REQ-MOMENT-001 及 DEV-MOMENT-001。
- 记录朋友圈接口修复范围和验收条件。
- 修复发布幂等、可见性前置校验、通知已读状态、通知预览字段、评论交互、媒体元数据、上传 MIME/路径校验、封面缓存和 mentions 解析。
- iOS `WuKongContacts`、`WuKongChatiOS` 模拟器构建通过；后端 `go test ./modules/moment` 与 `go vet ./modules/moment` 通过。
- 修复发布前直接读取 `textView.text` 导致正文为空的问题，改用 UITextView 文本存储和输入系统回退读取。
- 增加 UITextView 委托实时保存草稿文本，并在发送前输出文本长度用于真机链路核验。
- 修复朋友圈时间线和发布预览中的播放字符被系统渲染为 emoji，统一改用原生 `play.fill` 图标。
