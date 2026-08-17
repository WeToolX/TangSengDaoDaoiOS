# API 对接记录

## 1. 现有接口

- `POST /v1/moment/publish`
- `GET /v1/moment/notices/sync`
- `POST /v1/moment/notices/read`
- `POST/DELETE /v1/moment/posts/{post_id}/comments`
- 文件上传接口由 IMServer 文件模块提供。

## 2. 兼容性

保持服务端现有 JSON 字段风格；新增响应字段只用于补齐 iOS 已有模型，不删除现有字段。
