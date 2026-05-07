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
```

## API 文档

### 认证

| 方法 | 路径 | 说明 |
|------|------|------|
| POST | `/api/auth/register` | 注册 |
| POST | `/api/auth/login` | 登录 |

### 工作记录

| 方法 | 路径 | 说明 |
|------|------|------|
| GET | `/api/worklogs?since=ms` | 获取工作记录（增量） |
| POST | `/api/worklogs` | 创建记录 |
| PUT | `/api/worklogs/:id` | 更新记录 |
| DELETE | `/api/worklogs/:id` | 删除记录 |

### 待办事项

| 方法 | 路径 | 说明 |
|------|------|------|
| GET | `/api/todos?since=ms` | 获取待办（增量） |
| POST | `/api/todos` | 创建待办 |
| PUT | `/api/todos/:id` | 更新待办 |
| DELETE | `/api/todos/:id` | 删除待办 |

### 同步

| 方法 | 路径 | 说明 |
|------|------|------|
| POST | `/api/sync` | 批量同步（推送 + 拉取） |

### 设置

| 方法 | 路径 | 说明 |
|------|------|------|
| GET | `/api/settings` | 获取用户设置 |
| PUT | `/api/settings` | 更新用户设置 |

### 健康检查

| 方法 | 路径 | 说明 |
|------|------|------|
| GET | `/api/health` | 服务状态 |

## 技术细节

- 离线优先架构：本地 SQLite 为主数据源，服务端负责同步
- 同步基于 `clientId` 去重（客户端自增 ID 作为 clientId 发送）
- 增量同步通过 `updatedAt` 时间戳实现
- JWT Token 有效期 30 天
