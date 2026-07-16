# IM 私聊/群聊音视频通知与 HTTP 接口对接文档

版本：v1.0  
时间：2026-07-16  
适用端：Android、iOS  
状态：CONFIRMED

本文件是 Android 前端接入 RTC 的对齐文档。服务端完整实现以 `/Volumes/SSD_1/DevelopmentProject/go/IMServer/docs/rtc-api.md` 和 `rtc-client-integration.md` 为准；本文补充 iOS 当前代码实际使用的字段、通知分工和 UI 入口。

## 1. 先记住这四条

1. HTTP 负责创建/加入/结束通话，IM CMD 和 Push 只负责通知，不能用通知里的数据直接连接 LiveKit。
2. `rtc.invite` 是强邀请/来电，会弹窗和响铃；`rtc.notice` 是在线普通群提醒，不弹窗、不响铃。
3. `rtc_notice` 是群聊持久 IM 消息，消息列表里的“正在通话”入口；它和 `rtc.notice` 不是同一种协议。
4. 拿到 `call_id` 后，接听或加入必须调用 `POST /v1/rtc/calls/{call_id}/join`，成功后才使用响应里的 `livekit.url` 和 `livekit.token`。

## 2. 基础约定

### 2.1 请求

```http
Base URL: https://{api-host}
token: {user_login_token}
Content-Type: application/json
```

| 字段 | 取值 |
| --- | --- |
| `channel_type=1` | 私聊，`channel_id` 为对方 UID |
| `channel_type=2` | 群聊，`channel_id` 为群编号 |
| `call_type=audio` | 语音 |
| `call_type=video` | 视频 |
| 时间字段 | Unix 秒级时间戳 |

`device_id` 是安装实例持久化 UUID，不使用厂商 Push Token、IMEI、OAID 或广告 ID。发起/加入放 body；拒绝、取消、关闭、离开、邀请、创建加入码建议同时在 header 传 `device_id`。

### 2.2 错误

```json
{
  "msg": "邀请已过期",
  "status": 40005
}
```

| status | 含义 |
| ---: | --- |
| 40001 | 自己或对方正在通话中 |
| 40003 | 无权发起通话 |
| 40004 | 通话不存在或已结束 |
| 40005 | 邀请已过期 |
| 40006 | 无权加入通话、不是群成员/被邀请人或加入码无效 |
| 40007 | 无权关闭房间 |
| 40008 | 已在其他设备接听 |
| 50001 | LiveKit 房间或 token 创建失败 |
| 50002 | 通知发送失败 |
| 50003 | LiveKit 状态查询失败 |

## 3. HTTP 接口

### 3.1 接口清单

| 方法 | 路径 | 用途 |
| --- | --- | --- |
| POST | `/v1/rtc/calls` | 发起私聊/群聊通话 |
| POST | `/v1/rtc/calls/{call_id}/join` | 接听或加入 |
| POST | `/v1/rtc/calls/{call_id}/reject` | 拒绝私聊来电/强邀请 |
| POST | `/v1/rtc/calls/{call_id}/cancel` | 发起方未接通前取消 |
| POST | `/v1/rtc/calls/{call_id}/close` | 关闭整个房间 |
| POST | `/v1/rtc/calls/{call_id}/leave` | 当前用户离开群房间 |
| POST | `/v1/rtc/calls/{call_id}/invite` | 通话中邀请成员 |
| POST | `/v1/rtc/calls/{call_id}/join_code` | 创建一次性加入码 |
| GET | `/v1/rtc/channels/{channel_type}/{channel_id}/state` | 查询频道当前有效通话 |
| POST | `/v1/user/device_token` | 注册 APNs/厂商 Push Token |

### 3.2 发起通话

```http
POST /v1/rtc/calls
```

```json
{
  "request_id": "uuid-每次点击生成，同一次重试不变",
  "channel_id": "g_10000",
  "channel_type": 2,
  "call_type": "video",
  "device_id": "install-uuid",
  "invite_uids": ["u_20001"]
}
```

`invite_uids` 仅用于群聊强邀请，可为空。服务端会过滤非群成员、系统账号、被禁用账号、已在本通话或其他通话中的账号。

成功响应：

```json
{
  "call_id": "call_01HF",
  "existing": false,
  "room_name": "group:g_10000:call_01HF",
  "expire_at": 1779540000,
  "status": "calling",
  "permissions": ["join", "leave", "invite", "cancel"],
  "livekit": {
    "url": "wss://rtc.example.com",
    "token": "caller-livekit-jwt"
  }
}
```

群聊已有有效房间时返回 `existing=true` 和当前房间 token；Android 直接进入已有房间，不重复创建通话消息。

### 3.3 接听/加入

```http
POST /v1/rtc/calls/{call_id}/join
```

```json
{
  "device_id": "install-uuid",
  "join_code": ""
}
```

私聊接听、群聊强邀请接听、群消息入口加入、加入码加入都走这个接口。成功后返回同结构 `CallResp`，Android 只能使用本次响应的 LiveKit token。

### 3.4 结束类接口

```http
POST /v1/rtc/calls/{call_id}/reject
POST /v1/rtc/calls/{call_id}/cancel
POST /v1/rtc/calls/{call_id}/leave
```

以上接口无 body，建议 header 传：

```http
device_id: install-uuid
```

关闭整个房间：

```http
POST /v1/rtc/calls/{call_id}/close
device_id: install-uuid
Content-Type: application/json
```

```json
{"reason":"hangup"}
```

私聊已接通后挂断使用 `close`；群聊普通成员退出使用 `leave`；群房主/有 `close` 权限的用户结束整个群通话使用 `close`。

### 3.5 邀请与加入码

```http
POST /v1/rtc/calls/{call_id}/invite
device_id: install-uuid
```

```json
{"uids":["u_20001","u_20002"]}
```

```http
POST /v1/rtc/calls/{call_id}/join_code
device_id: install-uuid
```

```json
{"call_id":"call_01HF","join_code":"739421","expire_at":1779540000}
```

### 3.6 查询群聊当前通话

```http
GET /v1/rtc/channels/2/{group_id}/state
```

无通话：

```json
{"existing":false}
```

有通话：

```json
{
  "existing": true,
  "call_id": "call_01HF",
  "room_name": "group:g_10000:call_01HF",
  "status": "connected",
  "call_type": "audio",
  "from_uid": "u_10001",
  "invite_uids": [],
  "expire_at": 1779540000
}
```

消息入口展示“加入”前建议查询一次；以后端返回的 `call_id/status` 为准，不信任过期本地消息。

### 3.7 注册设备 Push Token

```http
POST /v1/user/device_token
```

```json
{
  "device_token": "android-vendor-token",
  "device_type": "MI",
  "bundle_id": "com.example.im"
}
```

Android `device_type`：`MI`、`OPPO`、`VIVO`、`HMS`、`HONOR`；`bundle_id` 为应用包名。登录后、Token 刷新后都应重新注册。

## 4. 通知协议

### 4.1 在线 IM CMD

```json
{
  "type": 99,
  "cmd": "rtc.invite",
  "param": {
    "call_id": "call_01HF",
    "room_name": "group:g_10000:call_01HF",
    "channel_id": "g_10000",
    "channel_type": 2,
    "call_type": "video",
    "from_uid": "u_10001",
    "from_name": "张三",
    "invite_uids": ["u_20001"],
    "expire_at": 1779540000
  }
}
```

`param` 通用字段：`call_id`、`room_name`、`channel_id`、`channel_type`、`call_type`、`from_uid`、`from_name`、`invite_uids`、`expire_at`、`uid`、`reason`、`answer_device_id`。CMD 不携带 `livekit.token`。

| cmd | 私聊 | 群聊 | Android 行为 |
| --- | --- | --- | --- |
| `rtc.invite` | 被叫来电 | `invite_uids` 强邀请 | 弹窗、响铃；点击接听调用 `join` |
| `rtc.notice` | 不使用 | 普通在线成员 | 刷新会话通话条，不弹窗、不响铃 |
| `rtc.joined` | 更新接通 | 更新成员列表 | 刷新成员/状态 |
| `rtc.rejected` | 发起方停止响铃 | 标记某成员拒绝 | 群房间不关闭 |
| `rtc.cancelled` | 关闭来电 | 关闭对应强邀请 | `answered_on_other_device` 只停止本设备响铃 |
| `rtc.closed` | 退出通话页 | 退出通话页 | 断开 LiveKit、移除通话入口 |
| `rtc.timeout` | 未接超时 | 强邀请停止或房间超时 | 关闭来电/刷新入口 |

### 4.2 持久 IM 消息：`rtc_notice`

```json
{
  "type": "rtc_notice",
  "call_id": "call_01HF",
  "room_name": "group:g_10000:call_01HF",
  "channel_id": "g_10000",
  "channel_type": 2,
  "call_type": "audio",
  "record_type": "",
  "duration": 0,
  "from_uid": "u_10001",
  "target_uids": [],
  "answer_uid": "",
  "started_at": 0,
  "ended_at": 0
}
```

它是群消息流里的普通消息，不响铃。Android 收到消息同步后渲染“正在通话，点击加入”；点击前查频道状态，点击后调用 `join`。

### 4.3 持久 IM 消息：`rtc_record`

字段与 `rtc_notice` 相同，`type` 为 `rtc_record`，`record_type` 为：

| record_type | 文案 |
| --- | --- |
| `answered` | 通话时长 `HH:mm:ss` |
| `missed` | 发起方“对方未接听”，被叫方“未接来电” |
| `rejected` | 发起方“对方已拒绝”，被叫方“已拒绝” |
| `cancelled` | 通话已取消 |

`rtc_record` 只展示记录；点击可按原 `call_type` 重新发起新通话，不可复用原 `call_id` 加入。

## 5. 两种群聊入口必须分开

### 5.1 群聊被邀请：强邀请链路

适用：发起人传 `invite_uids`，或通话中调用 `/invite`。

1. 服务端向目标在线用户发送 `rtc.invite`；离线时发送厂商 Push。
2. Android 展示来电弹窗/全屏来电页并响铃，显示发起人、群名、语音/视频、倒计时。
3. 点击接听：申请麦克风/摄像头权限，调用 `join`，成功后连接 LiveKit。
4. 点击拒绝：调用 `reject`；群房间继续存在。
5. 其他设备收到 `rtc.cancelled` 且 `reason=answered_on_other_device` 时，只关闭本设备来电 UI。
6. 强邀请过期只停止提醒，不关闭群房间；仍可从 `rtc_notice` 加入。

### 5.2 群消息内 UI 通话提示栏：普通入口链路

适用：没有被强邀请，或离线普通群成员上线后从消息同步进入。

1. 发起成功后服务端写入群消息 `rtc_notice`。
2. 在线普通成员同时收到 `rtc.notice`，仅用于立即刷新顶部通话条。
3. 打开群会话或同步消息时，以 `rtc_notice` 作为持久入口。
4. 通话条/消息卡片展示“正在通话，点击加入”，不得弹私聊来电页，不得响铃。
5. 点击后先查 `/channels/2/{group_id}/state`，有效则调用 `join`。
6. `join` 成功后连接 LiveKit；失败或状态已结束则隐藏“加入”，显示已结束。

## 6. Android 状态机与媒体规则

```text
idle
 ├─ start 成功 -> outgoing -> LiveKit connected -> in_call
 ├─ rtc.invite/离线 Push -> incoming -> join -> in_call
 └─ rtc.notice/rtc_notice -> checking -> join -> in_call
in_call -> leave/close/rtc.closed/rtc.timeout -> ended -> idle
```

- `audio` 只发布麦克风；`video` 发布麦克风和摄像头。
- LiveKit token 不落盘、不从 CMD 读取、不复用旧通话 token。
- 收到 `rtc.closed`、`rtc.cancelled`、`rtc.timeout`，无论 LiveKit 当前是否仍连接，都主动断开并关闭通话页。
- 私聊对端离开房间视为通话结束；群聊成员离开只更新成员列表，不关闭房间。
- 群视频窗口展示和订阅是客户端行为，不调用额外 HTTP；最多同时展示 4 个视频，其他成员保留音频并放入成员列表。

## 7. Android 对接验收清单

- [ ] `device_id` 持久化且发起/加入请求均传递。
- [ ] 已处理全部 7 个 RTC CMD。
- [ ] `rtc.invite` 与 `rtc.notice` UI 完全分开。
- [ ] 已注册 Android 厂商 Push Token，并按厂商填写 `device_type`。
- [ ] 离线 Push 点击后先取 `rtc_call.call_id`，再调用 `join`，不直接连 LiveKit。
- [ ] 私聊语音、私聊视频均可发起、接听、拒绝、取消、挂断。
- [ ] 群聊普通语音/视频均能从 `rtc_notice` 和 `rtc.notice` 加入。
- [ ] 群聊强邀请语音/视频均能弹窗响铃、接听、拒绝。
- [ ] `40005`、`40006`、`40008` 有明确 UI；其他错误可展示 `msg`。
- [ ] `rtc_notice`、`rtc_record` 注册为字符串消息类型，不显示“不支持的消息类型”。
- [ ] 收到关闭/超时/取消后，通话页、悬浮入口、群消息加入按钮同步清理。

## 8. iOS 当前实现差异

iOS 当前代码已实现上述 HTTP、CMD、Push 和持久消息模型；但 `WKConversationVC` 的顶部提示栏判断目前只放行 `channel_type=2 && call_type=audio`。因此当前 iOS 实际上群语音会显示顶部栏，群视频的 `rtc_notice` 仍应进入消息/其他入口但不会显示同一个顶部栏。

如果产品要求“群语音和群视频都必须显示同一条消息内通话提示栏”，需要把 iOS 顶部栏条件改为只判断群聊和有效 `call_id`，再让 Android 按本文的 audio/video 两种类型实现。

## 9. 版本记录

版本：v1.0  
时间：2026-07-16  
修改人：Codex  
修改原因：补齐 Android 与 iOS 的私聊/群聊音视频 HTTP、IM CMD、Push、持久消息和 UI 入口契约。  
影响范围：Android RTC 前端、iOS RTC 联调、IM 消息渲染、厂商离线推送。  
关联 ID：RTC-ANDROID-ALIGN-001
