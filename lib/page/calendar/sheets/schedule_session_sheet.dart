part of '../calendar.dart';

void _showScheduleSessionDetailSheet(
  ScheduleController controller,
  List<ScheduleSessionModel> sessions,
) {
  final title = sessions.length == 1 ? sessions.first.name : '冲突课程';
  Get.bottomSheet(
    Container(
      padding: const EdgeInsets.fromLTRB(20, 18, 20, 20),
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      child: SafeArea(
        top: false,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 10),
            ...sessions.map(
              (session) => Card(
                margin: const EdgeInsets.only(bottom: 8),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
                child: ListTile(
                  title: Text(
                    session.name,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  subtitle: Text(
                    [
                      session.chineseTime,
                      session.location ?? '未知地点',
                      if (session.online == true) '线上',
                    ].join(' · '),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  trailing: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      IconButton(
                        icon: const Icon(Icons.edit_outlined),
                        tooltip: '编辑',
                        onPressed: () {
                          Get.back();
                          _showScheduleSessionDialog(
                            Get.context!,
                            controller,
                            session: session,
                          );
                        },
                      ),
                      IconButton(
                        icon: const Icon(
                          Icons.delete_outline,
                          color: Colors.red,
                        ),
                        tooltip: '删除',
                        onPressed: () {
                          Get.back();
                          _confirmDeleteScheduleSession(controller, session);
                        },
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    ),
    isScrollControlled: true,
  );
}

void _confirmDeleteScheduleSession(
  ScheduleController controller,
  ScheduleSessionModel session,
) {
  Get.dialog(
    AlertDialog(
      title: const Text('删除课程'),
      content: Text('确定要删除「${session.name}」这条课程安排吗？'),
      actions: [
        TextButton(onPressed: () => Get.back(), child: const Text('取消')),
        ElevatedButton(
          style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
          onPressed: () async {
            await controller.deleteSession(session);
            Get.back();
            Get.snackbar('已删除', '课程安排已删除');
          },
          child: const Text('删除'),
        ),
      ],
    ),
  );
}
