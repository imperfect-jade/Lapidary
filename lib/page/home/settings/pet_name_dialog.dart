import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:todolist/page/pet/pet_controller.dart';

/// 弹出宠物改名对话框。
///
/// 输入校验放在这里，实际改名和保存仍委托给 [PetController]。
void showPetNameDialog(PetController petController, String? currentName) {
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
    // 对话框关闭后释放输入控制器，避免多次打开设置时残留文本控制器。
  ).whenComplete(nameController.dispose);
}
