# Douyu

[Douyu](https://www.douyu.com) 是中国的直播平台。

## URL 格式
``` 
https://www.douyu.com/{房间号}
https://www.douyu.com/topic/{房间号}
```

## 功能
- ✅ FLV 和 HLS 流
- ✅ 弹幕采集
- ✅ 搜索
- ✅ 分类
- ✅ 多画质选项
- ✅ 登录功能

## 认证

长效直播流需要账号认证，否则只能试看五分钟。

平台目前支持两种登录方式：扫码登录(推荐)，手动设置Cookie。


### 扫码登录(推荐)

1. 平台配置 → Douyu平台，点击登录后，选择**扫码登录**
2. 下载Douyu手机 App 扫码。
3. 登录完成后，会自动退出登录界面。
4. 平台配置页面显示你的Douyu用户名和头像，则代表登录成功。

### 手动设置 Cookie

平台配置 → Douyu平台，点击登录后，选择**Cookie登录**，在弹窗处粘贴已登录浏览器会话的 Cookie：

| 验证字段| 必需 | 说明 |
|--------|------|------|
| `cookie` | 是 | 会话令牌 |
| `dy_did` | 是 | 账号登录设备码 |
| `LTP0` | 是 | 更新续签令牌 |

#### 配置方法

- cookie：随便打开一个斗鱼直播间页面按F12均可
- ltp0 & dy_did: 按F12访问此网页 [douyu](https://passport.douyu.com)  在network搜索 'https://passport.douyu.com/' 即可在cookie 找到ltp0和dy_did
- cookie 有七天时效性，ltp0和dy_did配置后会自动刷新失效的cookie


## 注意事项

::: tip 提示
### 登录或同步账号数据后无法正常播放
- 首先重启app
- 项目没有后端不能控cookie绝对有效期；本地保存的cookie会在到期后申请新的cookie。
- 如果你是单一设备没问题，如果多设备你使用超过七天后，手机A登录账号A获取 didA+cookieA，手机B登录账号A获取didA+cookieB，会直接导致cookieA失效！
### 解决方案
- 更新到最新版，新的版本会在判定cookie失效后会自动申请有效的cookie，但请不要过于高频切换设备观看，可能会导致账号被风控
- 多设备经常数据同步，这样保证用的是同一个有效cookie
- 单独账号登录，不同步账号数据

:::

::: warning
登录后仍然无法观看1080P及以上画质或无法搜索，可能是账号或ip被风控了
:::

