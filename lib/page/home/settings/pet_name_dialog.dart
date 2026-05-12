part of '../home.dart';

void _showPetNameDialog(PetController petController, String? currentName) {
  final nameController = TextEditingController(text: currentName ?? '');
  Get.dialog(
    AlertDialog(
      title: const Text('修改宠物名字'),
      content: TextField(
        controller: nameController,
        autofocus: true,
        maxLength: 8,
        decoration: const InputDecoration(
          labelText: '宠物名字',
          hintText: '最多 8 个字符',
          border: OutlineInputBorder(),
        ),
      ),
      actions: [
        TextButton(onPressed: () => Get.back(), child: const Text('取消')),
        ElevatedButton(
          onPressed: () async {
            final name = nameController.text.trim();
            if (name.isEmpty) {
              Get.snackbar(
                '名字不能为空',
                '给宠物取一个简短的名字吧',
                snackPosition: SnackPosition.BOTTOM,
              );
              return;
            }
            if (name.length > 8) {
              Get.snackbar(
                '名字太长',
                '宠物名字最多 8 个字符',
                snackPosition: SnackPosition.BOTTOM,
              );
              return;
            }
            final success = await petController.renamePet(name);
            if (!success) {
              Get.snackbar(
                '修改失败',
                '请检查名字后再试',
                snackPosition: SnackPosition.BOTTOM,
              );
              return;
            }
            Get.back();
          },
          child: const Text('保存'),
        ),
      ],
    ),
  ).whenComplete(nameController.dispose);
}
