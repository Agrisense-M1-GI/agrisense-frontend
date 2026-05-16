import 'package:flutter/material.dart';
import '../../app_colors.dart';
import '../../widget.dart';
import 'modifier_profil_page.dart';

class ProfilScreen extends StatefulWidget {
  const ProfilScreen({super.key});

  @override
  State<ProfilScreen> createState() => _ProfilScreenState();
}

class _ProfilScreenState extends State<ProfilScreen> {
  String _selectedLanguage = 'fr';
  bool _notificationsEnabled = true;

  @override
  Widget build(BuildContext context) {
    
    return Scaffold(
      backgroundColor: AppColors.bg,
      appBar: AppBar(title: Text('Mon profil')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            // ── Avatar cliquable ──────────────────────────────────────────
            Center(
              child: Column(
                children: [
                  GestureDetector(
                    onTap: () => Navigator.push(
                      context,
                      MaterialPageRoute(
                          builder: (_) => const ModifierProfilScreen()),
                    ),
                    child: Stack(
                      children: [
                        const CircleAvatar(
                          radius: 46,
                          backgroundColor: AppColors.green200,
                          child: Text(
                            'KN',
                            style: TextStyle(
                                fontSize: 28,
                                fontWeight: FontWeight.w500,
                                color: AppColors.green700),
                          ),
                        ),
                        Positioned(
                          bottom: 0,
                          right: 0,
                          child: Container(
                            width: 26,
                            height: 26,
                            decoration: BoxDecoration(
                              color: AppColors.green600,
                              shape: BoxShape.circle,
                              border: Border.all(
                                  color: AppColors.white, width: 2),
                            ),
                            child: const Icon(Icons.edit,
                                color: AppColors.white, size: 13),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 12),
                  const Text(
                    'Kouam Njankou',
                    style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.w500,
                        color: AppColors.text),
                  ),
                  const Text(
                    'Agriculteur · Dschang, Cameroun',
                    style: TextStyle(
                        fontSize: 13, color: AppColors.textMuted),
                  ),
                  const SizedBox(height: 12),
                  /*OutlinedButton.icon(
                    onPressed: () => Navigator.push(
                      context,
                      MaterialPageRoute(
                          builder: (_) => const ModifierProfilScreen()),
                    ),
                    icon: const Icon(Icons.edit_outlined, size: 15),
                    label: const Text('Modifier le profil'),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: AppColors.green700,
                      side: const BorderSide(
                          color: AppColors.green600, width: 1.5),
                      padding: const EdgeInsets.symmetric(
                          horizontal: 18, vertical: 8),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(20)),
                      textStyle: const TextStyle(
                          fontSize: 12, fontWeight: FontWeight.w500),
                    ),
                  ),*/
                ],
              ),
            ),

            const SizedBox(height: 20),

            /*const SectionLabel('Mon exploitation'),
AppCard(
  child: Column(
    children: const [
      _ProfileRow(
        icon: Icons.agriculture,
        label: 'Champ actif',
        value: 'Champ Nord',
      ),
      _ProfileRow(
        icon: Icons.straighten,
        label: 'Superficie',
        value: '4.2 ha',
      ),
      _ProfileRow(
        icon: Icons.sensors,
        label: 'Capteurs',
        value: '8 capteurs',
      ),
      _ProfileRow(
        icon: Icons.eco,
        label: 'Culture',
        value: 'Maïs',
        isLast: true,
      ),
    ],
  ),
),

            const SizedBox(height: 12),

            const SectionLabel('Paramètres'),*/
            const SizedBox(height: 12),
            AppCard(
  child: Column(
    children: [
      ///  Notifications (Switch)
      _ProfileRow(
        icon: Icons.notifications_outlined,
        label: 'Notifications',
        trailing: Switch(
          value: _notificationsEnabled,
          onChanged: (value) {
            setState(() => _notificationsEnabled = value);
          },
          materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
        ),
      ),

      ///  Langue (Popup)
      _ProfileRow(
        icon: Icons.language,
        label: 'Langue',
        trailing: PopupMenuButton<String>(
          onSelected: (value) {
            setState(() => _selectedLanguage = value);
          },
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                _selectedLanguage == 'fr'
                    ? 'Français'
                    : 'English',
                style: const TextStyle(
                    fontSize: 14, color: AppColors.textMuted),
              ),
              const SizedBox(width: 4),
              const Icon(Icons.expand_more,
                  size: 18, color: AppColors.textMuted),
            ],
          ),
          itemBuilder: (context) => const [
            PopupMenuItem(value: 'fr', child: Text('Français')),
            PopupMenuItem(value: 'en', child: Text('English')),
          ],
        ),
      ),

      const _ProfileRow(
        icon: Icons.lock_outline,
        label: 'Sécurité',
        value: '',
      ),

      const _ProfileRow(
        icon: Icons.help_outline,
        label: 'Aide & support',
        value: '',
        isLast: true,
      ),
    ],
  ),
),

            const SizedBox(height: 12),

            SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                onPressed: () => _showLogoutDialog(context),
                icon: const Icon(Icons.logout, size: 16),
                label: const Text('Se déconnecter'),
                style: OutlinedButton.styleFrom(
                  foregroundColor: AppColors.red800,
                  side: const BorderSide(
                      color: AppColors.red600, width: 1),
                  padding: const EdgeInsets.symmetric(vertical: 13),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(11)),
                ),
              ),
            ),
            const SizedBox(height: 8),

            SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                onPressed: () => _showDeleteAccountDialog(context),
                icon: const Icon(Icons.delete, size: 16),
                label: const Text('Supprimer le compte'),
                style: OutlinedButton.styleFrom(
                  foregroundColor: AppColors.red800,
                  side: const BorderSide(
                      color: AppColors.red600, width: 1),
                  padding: const EdgeInsets.symmetric(vertical: 13),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(11)),
                ),
              ),
            ),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
  }

  void _showLogoutDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        shape:
            RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('Se déconnecter',
            style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w500,
                color: AppColors.text)),
        content: const Text(
            'Êtes-vous sûr de vouloir vous déconnecter ?',
            style:
                TextStyle(fontSize: 13, color: AppColors.textMuted)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Annuler',
                style: TextStyle(color: AppColors.textMuted)),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.red600,
              foregroundColor: AppColors.white,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8)),
            ),
            child: const Text('Déconnecter'),
          ),
        ],
      ),
    );
  }

  void _showDeleteAccountDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        shape:
            RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('Supprimer le compte',
            style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w500,
                color: AppColors.text)),
        content: const Text(
            'Êtes-vous sûr de vouloir vouloir supprimer votre compte(cette action entrainera la suppression de toutes vos données.) ?',
            style:
                TextStyle(fontSize: 13, color: AppColors.textMuted)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Annuler',
                style: TextStyle(color: AppColors.textMuted)),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.red600,
              foregroundColor: AppColors.white,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8)),
            ),
            child: const Text('Supprimer'),
          ),
        ],
      ),
    );
  }
}
class _ProfileRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final String? value;
  final Widget? trailing;
  final bool isLast;

  const _ProfileRow({
    required this.icon,
    required this.label,
    this.value,
    this.trailing,
    this.isLast = false,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        border: isLast
            ? null
            : const Border(
                bottom: BorderSide(
                  color: Color(0xFFF0F5EB),
                  width: 0.5,
                ),
              ),
      ),
      child: Row(
        children: [
          Container(
            width: 32,
            height: 32,
            decoration: BoxDecoration(
              color: AppColors.green50,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(icon, color: AppColors.green600, size: 17),
          ),
          const SizedBox(width: 12),

          Expanded(
            child: Text(
              label,
              style: const TextStyle(
                fontSize: 13,
                color: AppColors.text,
              ),
            ),
          ),

          trailing ??
              Text(
                value ?? '',
                style: const TextStyle(
                  fontSize: 12,
                  color: AppColors.textMuted,
                ),
              ),
        ],
      ),
    );
  }
}