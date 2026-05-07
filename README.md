# Worktime Server

Worktime 打卡应用的后端 API 服务，基于 Dart Shelf 框架。

## 技术栈

- **Dart** + **Shelf** — HTTP 框架
- **SQLite** — 数据存储
- **bcrypt** — 密码哈希
- **JWT** — 身份认证（30 天有效期）

## 快速开始

```bash
# 安装依赖
dart pub get

# 运行服务（默认端口 8080）
dart run bin/server.dart

# 指定端口
PORT=9090 dart run bin/server.dart

# 指定 JWT 密钥（默认随机生成）
JWT_SECRET=my-secret dart run bin/server.dart
```

## API 文档

所有 API 返回 JSON，时间字段均为 Unix 毫秒时间戳。

### 认证

```
POST /api/auth/register
POST /api/auth/login
```

请求体：

```json
{
  "phone": "13800138000",
  "password": "123456",
  "nickname": "张三"
}
```

注册/登录成功返回：

```json
{
  "ok": true,
  "token": "eyJhbGciOiJIUzI1NiIs...",
  "user": {
    "id": "uuid",
    "phone": "13800138000",
    "nickname": "张三",
    "createdAt": 1718000000000
  }
}
```

之后的请求在 Header 中携带 Token：

```
Authorization: Bearer eyJhbGciOiJIUzI1NiIs...
```

### 工作记录

| 方法 | 路径 | 说明 |
|------|------|------|
| GET | `/api/worklogs?since=ms` | 增量获取工作记录 |
| POST | `/api/worklogs` | 创建记录 |
| PUT | `/api/worklogs/:id` | 更新记录 |
| DELETE | `/api/worklogs/:id` | 删除记录 |

`GET /api/worklogs` 返回：

```json
{
  "ok": true,
  "logs": [
    {
      "id": "uuid",
      "userId": "uuid",
      "clientId": "uuid",
      "title": "需求评审",
      "category": "会议",
      "startTime": 1718000000000,
      "endTime": 1718003600000,
      "duration": 60,
      "status": 2,
      "notes": "",
      "createdAt": 1718000000000,
      "updatedAt": 1718000000000
    }
  ]
}
```

`POST /api/worklogs` 请求体：

```json
{
  "clientId": "客户端自增ID",
  "title": "需求评审",
  "category": "会议",
  "startTime": 1718000000000,
  "endTime": 1718003600000,
  "duration": 60,
  "status": 2,
  "notes": ""
}
```

### 待办事项

| 方法 | 路径 | 说明 |
|------|------|------|
| GET | `/api/todos?since=ms` | 增量获取待办 |
| POST | `/api/todos` | 创建待办 |
| PUT | `/api/todos/:id` | 更新待办 |
| DELETE | `/api/todos/:id` | 删除待办 |

`GET /api/todos` 返回字段：

| 字段 | 类型 | 说明 |
|------|------|------|
| id | String | 服务端 UUID |
| clientId | String | 客户端自增 ID |
| userId | String | 用户 ID |
| title | String | 标题 |
| description | String | 备注 |
| priority | int | 优先级（0=低, 1=中, 2=高） |
| status | int | 状态（0=待办, 2=已完成） |
| dueDate | int? | 截止时间（毫秒时间戳） |
| category | String | 分类 |
| linkedWorkLogClientId | String? | 关联的工作记录 clientId |
| parentClientId | String? | 父待办 clientId（用于子任务） |
| recurringRule | String | 重复规则（daily/weekly/monthly） |
| sortOrder | int | 排序序号 |
| createdAt | int | 创建时间 |
| updatedAt | int | 更新时间 |

`POST /api/todos` 请求体：

```json
{
  "clientId": "客户端自增ID",
  "title": "完成需求文档",
  "description": "包含接口设计",
  "priority": 2,
  "status": 0,
  "dueDate": 1718083200000,
  "category": "工作",
  "recurringRule": "",
  "sortOrder": 0
}
```

### 批量同步

```
POST /api/sync
```

一次性推送本地的增改数据并拉取服务端增量。请求体：

```json
{
  "lastSyncAt": 1718000000000,
  "changes": [
    {
      "clientId": "本地ID",
      "title": "需求评审",
      "category": "会议",
      "startTime": 1718000000000,
      "endTime": null,
      "duration": 0,
      "status": 0,
      "notes": ""
    }
  ],
  "todoChanges": [
    {
      "clientId": "本地ID",
      "title": "完成需求文档",
      "description": "",
      "priority": 2,
      "status": 0,
      "dueDate": null,
      "category": "工作",
      "linkedWorkLogClientId": null,
      "parentClientId": null,
      "recurringRule": "",
      "sortOrder": 0
    }
  ]
}
```

返回：

```json
{
  "ok": true,
  "appliedCount": 2,
  "todoAppliedCount": 1,
  "syncAt": 1718003600000,
  "serverChanges": [],
  "todoServerChanges": []
}
```

### 用户设置

| 方法 | 路径 | 说明 |
|------|------|------|
| GET | `/api/settings` | 获取用户设置 |
| PUT | `/api/settings` | 更新用户设置 |

### 健康检查

| 方法 | 路径 | 说明 |
|------|------|------|
| GET | `/api/health` | 服务状态 |

返回 `{"ok": true, "status": "running"}`

## 技术细节

- **离线优先架构**：本地 SQLite 为主数据源，服务端负责同步备份
- **同步去重**：基于 `clientId`（客户端自增 ID）实现幂等，服务端按 clientId 查重
- **增量同步**：通过 `updatedAt` 时间戳拉取变更，客户端传入 `lastSyncAt`
- **JWT Token**：有效期 30 天，注册/登录时签发
- **密码存储**：bcrypt 加盐哈希
- **配置默认值**：工作时间 09:00-18:00，午休 60 分钟，久坐提醒和下班提醒默认关闭
