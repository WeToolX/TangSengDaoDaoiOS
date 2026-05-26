# RTC iOS 对接同步说明

同步日期：2026-05-25

来源文档：

- `/Volumes/SSD_1/DevelopmentProject/go/IMServer/docs/rtc-api.md`
- `/Volumes/SSD_1/DevelopmentProject/go/IMServer/docs/rtc-client-integration.md`

## 依赖策略

- 现有业务模块继续使用 CocoaPods。
- LiveKit Swift SDK 使用 Swift Package Manager 接入。
- LiveKit SPM 仓库：`https://github.com/livekit/client-sdk-swift.git`
- 当前锁定规则：`upToNextMajorVersion`，最低版本 `2.14.1`。

## 已对齐接口

代码只封装服务端文档中明确存在的接口：

- `POST /v1/rtc/calls`
- `POST /v1/rtc/calls/{call_id}/join`
- `POST /v1/rtc/calls/{call_id}/reject`
- `POST /v1/rtc/calls/{call_id}/cancel`
- `POST /v1/rtc/calls/{call_id}/close`
- `POST /v1/rtc/calls/{call_id}/leave`
- `POST /v1/rtc/calls/{call_id}/invite`
- `POST /v1/rtc/calls/{call_id}/join_code`
- `GET /v1/rtc/channels/{channel_type}/{channel_id}/state`
- `POST /v1/user/device_token`

文档没有定义“同步媒体开关状态”的接口，因此 iOS 端麦克风和摄像头开关只调用 LiveKit 本地发布状态，不额外调用未定义 HTTP 接口。

## iOS 处理要点

- `device_id` 使用现有 Keychain 持久化的 `UIDevice getUUID`，发起、加入接口放在 body，拒绝、取消、关闭、离开等接口放在 header。
- PushKit VoIP token 上传时 `device_type=IOS`，`bundle_id` 使用主 Bundle ID 加 `.voip`。
- 收到 VoIP push 后先解析 `rtc_call.call_id`，立即进入本地来电流程并上报 CallKit；用户接听后再调用 `join` 获取 LiveKit token。
- LiveKit token 只来自后端发起或加入接口响应，不持久化，不写日志。
- 收到 `rtc.closed`、`rtc.cancelled`、`rtc.timeout` 等终态 CMD 后，立即断开 LiveKit 并关闭 CallKit/应用内通话页。

## 本次已补齐能力

- 摄像头前后置翻转：通话页视频态展示“翻转”，通过 LiveKit 本地摄像头采集器切换。
- `rtc_notice`/`rtc_record` 持久消息：字符串 `type` 映射到本地 RTC 消息类型，展示通话卡片；`rtc_notice` 点击加入，`rtc_record` 仅展示记录。
- 群聊加入/离开提示：LiveKit 成员进出房间通知到通话页，群聊展示成员昵称提示。
- 私聊对方离开即挂断：私聊远端成员离开 LiveKit 房间时，本地按通话结束处理。
- 弱网提示：成员网络质量为 `poor` 或 `lost` 时展示弱网文案；重连态展示正在重连。
- 错误码专项文案：已按服务端文档补齐 `40001`、`40003`、`40004`、`40005`、`40006`、`40007`、`40008`、`50001`、`50002`、`50003` 的中文 UI 文案。
- 成员头像/昵称展示：通话页和消息卡片优先使用本地已知用户资料，取不到昵称时回退 UID，头像按现有头像接口回退。
- 视频订阅降级：群聊网格只订阅当前可见远端视频，隐藏成员保留音频；LiveKit 房间开启 `adaptiveStream` 和 `dynacast`。

## 端到端联调清单

- 私聊视频：A 发起，B 接听，双方能看到本地与远端画面；A/B 均能切换前后摄像头。
- 私聊离开：B 直接断开或离开房间，A 端应结束通话并展示“对方已离开，通话已结束”。
- 群聊普通入口：发起群通话后，群消息列表生成 `rtc_notice` 卡片，普通成员点击卡片能加入当前通话。
- 群聊记录：通话结束后生成 `rtc_record` 卡片，点击只提示通话已结束，不重新加入。
- 群聊成员状态：成员加入和离开时，通话页展示对应昵称提示，成员列表头像和昵称与本地资料一致。
- 弱网恢复：模拟丢包或断网后，通话页出现弱网或重连提示；网络恢复后媒体状态能继续刷新。
- 错误码：后端分别返回文档内业务错误码，iOS 端展示对应中文文案。
- 视频降级：群聊超过可见网格人数时，抓包或服务端指标确认隐藏成员视频未订阅，音频仍可听到。
- 多端终态：`rtc.closed`、`rtc.cancelled`、`rtc.timeout` 到达后，所有相关 iOS 端关闭通话页并断开 LiveKit。
- 离线同步：普通群成员离线期间产生的 `rtc_notice`，上线同步消息后卡片仍可点击加入；若服务端状态已结束，应展示结束提示。
