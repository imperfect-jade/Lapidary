/// 宠物业务动作枚举，作为 Controller、UI 动画和浮层事件之间的轻量协议。
///
/// 新增动作时需要同步检查精灵动作映射、局部反馈和全局浮层展示逻辑。
enum PetAction { idle, pet, feed, sleep, taskComplete, overdue }
