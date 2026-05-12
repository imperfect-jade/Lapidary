# Todolist

Todolist 是一个使用 Flutter 开发的本地优先待办应用，围绕任务管理、番茄钟、四象限规划、日历视图和像素风宠物陪伴构建。项目使用 GetX 管理状态，使用 Hive 做本地持久化，适合学习 Flutter 多页面应用、离线数据建模和轻量交互设计。

## 功能特性

- 待办任务：创建、筛选、查看和管理任务。
- 番茄钟：支持专注计时、休息模式和今日统计。
- 四象限：按重要性和紧急度组织任务。
- 日历视图：按日期查看任务和日程内容。
- 像素宠物：支持精灵图动画、互动反馈、喂食、睡觉和奖励机制。
- 个性化设置：支持主题、字体和宠物相关设置。

## 技术栈

- Flutter / Dart
- GetX
- Hive / Hive Flutter
- table_calendar
- device_calendar
- permission_handler

## 项目结构

```text
lib/
  constants/      全局常量和主题
  model/          Hive 数据模型
  page/           页面、控制器和页面内组件
  routes/         应用入口路由
  assets/         图片、宠物精灵图、字体和文本资源
test/             测试入口
android/ ios/     移动端平台工程
linux/ macos/
web/ windows/     桌面端和 Web 平台工程
```

## 环境要求

- Flutter SDK 3.x
- Dart SDK 3.x
- Android Studio、Xcode 或对应平台构建工具

## 快速开始

```bash
flutter pub get
flutter run
```

常用开发命令：

```bash
flutter analyze
flutter test
dart run build_runner build --delete-conflicting-outputs
```

修改 Hive 模型时，需要重新运行 `build_runner` 生成对应的 `*.g.dart` 文件。

## 隐私与安全

本项目默认不包含任何云端服务密钥或私密配置。提交代码前请确认没有加入 `.env`、签名证书、密钥文件、Firebase 配置或本地开发说明文件。项目已在 `.gitignore` 中忽略常见敏感文件。

## 路线图

- 完善像素宠物陪伴体验。
- 增加拍照扫描并生成自定义像素宠物的能力。
- 补充与当前应用入口匹配的自动化测试。
- 优化多端构建和发布流程。

## 贡献

欢迎提交 Issue 和 Pull Request。建议在提交前运行 `flutter analyze` 和 `flutter test`，并保持代码风格与现有 GetX、Hive 结构一致。

## 许可证

本项目基于 Apache License 2.0 开源，详见 [LICENSE](LICENSE)。
