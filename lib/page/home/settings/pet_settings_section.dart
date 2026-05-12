part of '../home.dart';

class _PetSettingsSection extends StatelessWidget {
  const _PetSettingsSection();

  @override
  Widget build(BuildContext context) {
    final petController = Get.find<PetController>();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          '宠物设置',
          style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
        ),
        const SizedBox(height: 10),
        Obx(() {
          final pet = petController.pet.value;
          final species = pet?.species ?? PetSpecies.cat;
          return Column(
            children: [
              _PetNameEditor(
                name: pet?.name ?? '小云',
                onEdit: () => _showPetNameDialog(petController, pet?.name),
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: _PetOptionCard(
                      title: '像素小猫',
                      subtitle: species == PetSpecies.cat ? '当前伙伴' : '可选择',
                      icon: Icons.pets,
                      selected: species == PetSpecies.cat,
                      enabled: true,
                      onTap: () =>
                          petController.selectPetSpecies(PetSpecies.cat),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: _PetOptionCard(
                      title: '像素小狗',
                      subtitle: species == PetSpecies.dog ? '当前伙伴' : '可选择',
                      icon: Icons.pets,
                      selected: species == PetSpecies.dog,
                      enabled: true,
                      onTap: () =>
                          petController.selectPetSpecies(PetSpecies.dog),
                    ),
                  ),
                ],
              ),
            ],
          );
        }),
      ],
    );
  }
}

class _PetNameEditor extends StatelessWidget {
  final String name;
  final VoidCallback onEdit;

  const _PetNameEditor({required this.name, required this.onEdit});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: TaskTheme.primaryColor,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.white),
      ),
      child: Row(
        children: [
          const Icon(Icons.badge_outlined, size: 20),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              '宠物名字：$name',
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(fontWeight: FontWeight.w600),
            ),
          ),
          TextButton.icon(
            onPressed: onEdit,
            icon: const Icon(Icons.edit, size: 16),
            label: const Text('修改'),
          ),
        ],
      ),
    );
  }
}

class _PetOptionCard extends StatelessWidget {
  final String title;
  final String subtitle;
  final IconData icon;
  final bool selected;
  final bool enabled;
  final VoidCallback? onTap;

  const _PetOptionCard({
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.selected,
    required this.enabled,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      borderRadius: BorderRadius.circular(8),
      onTap: enabled ? onTap : null,
      child: Opacity(
        opacity: enabled ? 1 : 0.55,
        child: Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: TaskTheme.primaryColor,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(
              color: selected ? TaskTheme.selectedColor : Colors.white,
              width: selected ? 2 : 1,
            ),
          ),
          child: Column(
            children: [
              Icon(icon, size: 30, color: TaskTheme.selectedColor),
              const SizedBox(height: 8),
              Text(title, style: const TextStyle(fontWeight: FontWeight.bold)),
              const SizedBox(height: 4),
              Text(
                subtitle,
                style: const TextStyle(fontSize: 12, color: Colors.grey),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
