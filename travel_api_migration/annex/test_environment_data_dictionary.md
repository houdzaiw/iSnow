# Travel test 环境数据字典

| 数据项 | 来源 | 类型 | 用途 | 敏感级别 |
|---|---|---|---|---|
| `environment` | 构建配置 | `String` | 固定为 `test` | 公开 |
| `bootstrapUrl` | travel test 配置 | `String` | Bootstrap 公共入口 | 公开 |
| `bootstrapAadPath` | travel test 配置 | `String` | Bootstrap AES AAD 路径 | 公开 |
| `bootstrapKid` | travel test 配置 | `String` | Bootstrap 密钥标识 | 公开 |
| `bootstrapPublicKeyPem` | travel test 配置 | `String` | RSA-OAEP 加密一次性会话密钥 | 公开 |
| `channel` | travel test 配置 | `String` | 服务端包身份渠道 | 公开 |
| `platform` | 设备信息 | `ANDROID` / `IOS` | Bootstrap 外层身份 | 公开 |
| `packageName` | App 包信息 | `String` | 服务端包配置匹配 | 公开 |
| `clientVersion` | App 包信息 | `String` | 服务端版本识别 | 公开 |
| `deviceId` | 设备信息 | `String` | 设备识别和 x-auth-token | 设备标识 |
| `appLanguage` | 系统 locale | `String` | 服务端语言和内容分流 | 公开 |
| `apiBaseUrl` | Bootstrap 响应 | `String` | 本次运行公共 API 基地址 | 运行时地址 |
| `crypto.key` | client.init 响应 | Base64URL | 业务 AES-GCM 密钥 | 会话敏感 |
| `crypto.salt` | client.init 响应 | Base64URL | `v/b` 请求签名盐 | 会话敏感 |
| `oauth-token` | 登录响应 | `String` | 登录后认证 | 凭据 |
| `pub-uid` | 登录响应 | `String` | 用户身份 | 用户标识 |

## 约束

- Bootstrap、client.init 和业务响应失败时不得继续使用 iSnow 旧域名。
- token、AES key、salt 和完整请求体不得进入日志。
- `apiBaseUrl` 必须先通过协议与环境策略校验，再写入内存运行会话。
