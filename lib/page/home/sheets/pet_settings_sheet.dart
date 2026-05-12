part of '../home.dart';

void _showPetSettingsSheet() {
  Get.bottomSheet(
    Container(
      padding: const EdgeInsets.all(20),
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      child: const SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '宠物',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            SizedBox(height: 18),
            _PetSettingsSection(),
            SizedBox(height: 8),
          ],
        ),
      ),
    ),
    isScrollControlled: true,
  );
}
