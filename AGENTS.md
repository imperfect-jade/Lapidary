# AGENTS.md

## 项目概览
- 这是一个 Flutter 待办应用，使用 Dart、GetX 和 Hive。
- 已实现功能：待办任务、番茄钟、四象限、日历。
- 宠物功能目前只有 `lib/page/pet/pet.dart` 占位页，后续开发应优先补齐这里。
- 宠物功能应类似于codex的宠物功能，以像素风实现，起到陪伴用户的功能。
- 宠物功能应有简单的交互，如点击宠物、喂食、睡觉等。
- 宠物功能应有简单的动画效果，如宠物移动、喂食动画等。
- 主要代码位于 `lib/`，多端平台目录只在需要原生配置时修改。

## 代码结构
- `lib/main.dart`：初始化 Hive、注册 Adapter、打开 Box、注册全局 Controller。
- `lib/routes/index.dart`：应用根路由，目前入口为 `HomePage`。
- `lib/page/<feature>/`：功能页面和对应 Controller。
- `lib/model/`：Hive 数据模型；`*.g.dart` 为生成文件，不要手改。
- `lib/constants/theme.dart`：全局主题颜色。
- `lib/assets/images/`：底部导航图标资源。

## 开发约定
- 状态管理沿用 GetX：页面用 `Get.find` 获取已注册 Controller，响应式 UI 使用 `Obx`。
- 本地数据沿用 Hive：新增持久化模型时要添加 `@HiveType`、稳定分配 `typeId` 和 `@HiveField` 编号，并在 `main.dart` 注册 Adapter、打开 Box。
- 修改 Hive 模型后运行：
  `dart run build_runner build --delete-conflicting-outputs`
- 不要直接编辑 `*.g.dart`，它们由 `hive_generator` 生成。
- 中文文案和注释请保持 UTF-8 编码，避免乱码。
- UI 风格保持当前浅蓝主题和底部五栏导航，不要无关重做整体视觉。

## 常用命令
- 安装依赖：`flutter pub get`
- 静态检查：`flutter analyze`
- 运行测试：`flutter test`
- 运行应用：`flutter run`

## 注意事项
- 当前 `test/widget_test.dart` 仍是 Flutter 默认 Counter 测试，和现有 `main.dart` 不匹配；改动测试前应先按当前应用入口重写。
- 任何删除文件操作都必须先询问获得许可
- 受权限影响，部分需要使用flutter命令的操作可交由用户自己执行
