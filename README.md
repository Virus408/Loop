# Loop - iOS 循环录音工作站

一款 iPhone 端实时音频循环录音 App，灵感来自 Boss RC-505 Loop Station。使用 AVAudioEngine 实现 6 轨道录音、循环播放、叠加录制，具有极低延迟。

## 功能一览

| 功能 | 说明 |
|------|------|
| 6 轨道录音 | 每条轨道独立录制麦克风音频 |
| 循环播放 | 录制结束后自动无限循环 |
| 叠加录制 (Overdub) | 在播放中的轨道上叠加新的音频层 |
| 循环长度锁定 | 第一条录制的轨道确定循环长度，后续轨道自动对齐 |
| 撤销 | 撤销最后一次叠加录制 |
| 清除轨道 | 清空某条轨道的全部内容 |
| 轨道音量 | 每条轨道独立音量控制 |
| 静音 | 单独静音某条轨道 |
| 实时监听 | 戴耳机时实时听到麦克风输入（可开关） |
| 节拍器 | 可调 BPM 简单节拍器 |
| 混响效果 | 大教堂混响，可调干湿比 |
| 延迟效果 | 可调反馈和干湿比的延迟 |
| 保存/加载工程 | 存储和加载完整的 Loop 工程 |
| 导出音频 | 将混音结果导出为 M4A 文件并分享 |
| 深色舞台风格 | 黑色背景 + 高对比度状态色，适合舞台/户外 |
| 竖屏/横屏自适应 | 竖屏单列 6 轨，横屏双列 3+3 |
| 触觉反馈 | 所有按钮按下时有 Haptic 反馈 |
| 大按钮设计 | 主按钮最小 52pt 高，适合手指操作 |

## 系统要求

- iOS 16.0+
- iPhone（已针对单手手指操作优化）
- 麦克风权限
- 建议使用耳机（避免监听时啸叫）

---

## 构建方法

你有三种方式构建此 App。**推荐使用 GitHub Actions**（无需 Mac 电脑）。

### 方法一：GitHub Actions 自动构建（推荐 - 无需 Mac）

#### 第 1 步：创建 GitHub 仓库

1. 打开 [github.com](https://github.com)，点击右上角 **+** → **New repository**
2. 仓库名填 `Loop`，选择 **Private**（私有），勾选 **Add a README file**
3. 点击 **Create repository**

#### 第 2 步：上传代码

**在 Windows 上安装 Git（如果还没装）：**
- 去 [git-scm.com](https://git-scm.com/download/win) 下载并安装

**打开 Git Bash 或命令行，执行：**

```bash
# 进入项目目录
cd "你的项目路径/Loop"

# 初始化 Git 仓库
git init

# 添加所有文件
git add .

# 提交
git commit -m "Loop app initial commit"

# 关联远程仓库（把下面的 URL 换成你自己的）
git remote add origin https://github.com/你的用户名/Loop.git

# 推送
git branch -M main
git push -u origin main
```

#### 第 3 步：等待自动构建

1. 推送代码后，GitHub 会自动开始构建
2. 进入仓库页面 → 点击 **Actions** 标签页
3. 可以看到 **Build Loop** 工作流正在运行
4. 等待约 5-10 分钟，绿色对勾 ✓ 表示构建成功

#### 第 4 步：下载构建产物

1. 在 Actions 页面点击最新一次成功的构建
2. 页面底部 **Artifacts** 区域有两个文件：
   - **Loop-ipa** — IPA 安装包（推荐，用于 Sideloadly 安装）
   - **Loop-app** — .app 文件夹（用于 Xcode 安装）
   - **build-log** — 构建日志（如果构建失败可以查看）
3. 点击 **Loop-ipa** 下载，得到 `Loop.ipa` 文件

> **如果构建失败：** 下载 **build-log**，在日志中搜索 `error:` 查看具体错误信息。

---

### 方法二：在 Mac 上用 Xcode 构建

```bash
# 1. 安装 XcodeGen
brew install xcodegen

# 2. 克隆仓库
git clone https://github.com/你的用户名/Loop.git
cd Loop

# 3. 生成 Xcode 工程
xcodegen generate

# 4. 用 Xcode 打开
open Loop.xcodeproj
```

在 Xcode 中：
1. 选择你的 iPhone 作为构建目标
2. 在 **Signing & Capabilities** 标签页选择你的开发者团队
3. 按 `Cmd+R` 构建并运行

---

### 方法三：云 Mac

1. 租用云 Mac（如 [MacinCloud](https://www.macincloud.com)、[MacStadium](https://www.macstadium.com)，约 $20/月）
2. 在云 Mac 上按 **方法二** 操作

---

## 安装到 iPhone

你有两种方式将构建好的 App 安装到 iPhone 上。

### 方式一：用 Sideloadly 安装（推荐 - Windows 可用）

#### 准备工作
- 下载并安装 [Sideloadly](http://sideloadly.io)（Windows 版）
- 准备一个 Apple ID（免费的即可）
- iPhone 用数据线连接到电脑
- 下载好的 `Loop.ipa` 文件

#### 操作步骤

1. **打开 Sideloadly**
   - 在顶部输入框填入你的 Apple ID 邮箱
   - 点击 **Available targets** 下拉框，选择你的 iPhone

2. **选择 IPA 文件**
   - 点击左侧的 **IPA 图标** 按钮
   - 选择你下载的 `Loop.ipa` 文件

3. **设置 Bundle ID（重要）**
   - 在 **Bundle ID** 输入框中，把 `com.loop.app` 改成你自己的
   - 例如：`com.你的名字.loopapp`
   - 这是因为免费 Apple ID 不能使用默认的 Bundle ID

4. **开始安装**
   - 点击 **Start** 按钮
   - 第一次使用会要求输入 Apple ID 密码
   - 等待进度条完成，显示 **Done** 即安装成功

5. **信任开发者证书（必须）**
   - 在 iPhone 上打开 **设置 → 通用 → VPN与设备管理**
   - 找到你的 Apple ID 对应的开发者描述文件
   - 点击 → **信任**
   - 现在可以在桌面看到 Loop 图标并打开了

> **注意：** 免费 Apple ID 签名的 App **每 7 天需要重新签名**。到时间后 App 会闪退，重新用 Sideloadly 安装一次即可。如果购买 Apple Developer 会员（$99/年），签名有效期为 1 年。

---

### 方式二：用 AltStore 安装

1. 在电脑上安装 [AltServer](https://altstore.io)
2. iPhone 连接电脑
3. 通过 AltServer 在 iPhone 上安装 AltStore
4. 在 AltStore 中导入 `Loop.ipa` 安装
5. 同样需要在 **设置 → 通用 → VPN与设备管理** 中信任证书

---

### 方式三：用 Xcode 直接安装（需要 Mac）

1. 用数据线连接 iPhone 到 Mac
2. 在 Xcode 中打开 `Loop.xcodeproj`
3. 在 **Signing & Capabilities** 中选择你的开发者团队
4. 选择 iPhone 作为目标设备
5. 按 `Cmd+R` 构建并安装

---

## 使用指南

### 基本录音流程

1. **点击任意轨道的大按钮** → 开始录制（红色脉冲）
2. **再次点击** → 结束录制，轨道进入循环播放（绿色）
3. 第一条录制的轨道确定循环长度

### 叠加录制 (Overdub)

1. 轨道播放中（绿色）时，**点击该轨道按钮** → 开始叠加录制（琥珀色）
2. 新的音频会叠加到现有循环上
3. **再次点击** → 结束叠加，新的层被永久混合进去

### 轨道控制

| 操作 | 说明 |
|------|------|
| 音量滑块 | 调节每条轨道的音量 |
| 喇叭图标 | 点击静音/取消静音 |
| 垃圾桶图标 | 清除该轨道全部内容 |

### 主控制栏

| 按钮 | 功能 |
|------|------|
| Start All | 所有有内容的轨道同时开始播放 |
| Stop All | 停止所有轨道（内容保留） |
| Undo | 撤销最后一次叠加录制 |
| FX | 打开混响和延迟效果控制 |
| Save | 保存当前工程 |
| Load | 加载已保存的工程 |
| Export | 导出混音为 M4A 文件并分享 |

### 顶部控制栏

| 按钮 | 功能 |
|------|------|
| BPM -/+ | 调节节拍器速度 |
| Metro | 开关节拍器 |
| Monitor | 开关实时监听（请戴耳机使用） |

### 轨道状态颜色

| 状态 | 颜色 | 点击后 |
|------|------|--------|
| 空闲 | 灰色 | 开始录制 |
| 录制中 | 红色（脉冲） | 停止录制，开始循环 |
| 播放中 | 绿色 | 开始叠加录制 |
| 叠加中 | 琥珀色 | 停止叠加 |
| 已停止 | 暗绿色 | 恢复播放 |

---

## 项目结构

```
Loop/
├── project.yml                      # XcodeGen 项目配置
├── README.md                        # 本文件
├── .github/workflows/build.yml      # GitHub Actions 自动构建
├── .gitignore
└── Loop/                            # App 源代码
    ├── LoopApp.swift                # App 入口
    ├── Info.plist                   # XcodeGen 自动生成
    ├── Assets.xcassets/             # 图标和资源
    ├── Models/
    │   └── TrackState.swift         # 轨道状态枚举
    ├── Audio/
    │   ├── AudioEngine.swift        # 核心音频引擎
    │   ├── LoopTrack.swift          # 轨道录音/循环/叠加逻辑
    │   └── Metronome.swift          # 节拍器
    ├── ViewModels/
    │   └── LoopViewModel.swift      # 视图模型
    └── Views/
        ├── ContentView.swift        # 主界面 + 弹窗
        ├── TrackRowView.swift       # 轨道行视图
        └── MasterControlsView.swift # 底部主控制栏
```

## 技术细节

- **音频引擎**: AVAudioEngine + 6 个 AVAudioPlayerNode → 主混音器
- **信号链**: 轨道 + 监听 + 节拍器 → 主混音器 → 混响 → 延迟 → 输出
- **音频格式**: 44.1 kHz, 单声道, Float32（低延迟）
- **循环机制**: AVAudioPlayerNode.scheduleBuffer + `.loops` 选项
- **叠加录制**: 实时麦克风采集混合到现有 PCM buffer 的正确位置
- **IO 缓冲**: 5ms 首选 IO 缓冲时长，最低延迟
- **会话模式**: `.playAndRecord` + `.defaultToSpeaker` + `.allowBluetooth`

## 常见问题

**录音时没有声音**
- 确认已戴耳机（通过扬声器监听会产生啸叫）
- 检查 设置 → 隐私 → 麦克风 中是否授权了 Loop

**音频有延迟**
- 使用有线耳机代替蓝牙耳机
- 关闭其他后台音频 App

**Sideloadly 安装失败**
- 确认 Bundle ID 已改成你自己的（不能是 com.loop.app）
- 确认 iPhone 已用数据线连接并在 Sideloadly 中被识别
- 尝试重新输入 Apple ID 密码

**App 闪退（7天后）**
- 这是免费 Apple ID 签名的限制
- 重新用 Sideloadly 安装一次即可

**GitHub 构建失败**
- 在 Actions 页面下载 **build-log** 产物
- 用文本编辑器打开，搜索 `error:` 查看具体错误
- 常见原因：代码语法错误、Info.plist 配置问题

## 许可

个人项目，保留所有权利。
