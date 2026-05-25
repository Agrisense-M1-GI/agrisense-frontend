/*import 'package:flutter/material.dart';
import '../../app_colors.dart';

class NotificationsScreen extends StatelessWidget {
  const NotificationsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.bg,
      appBar: AppBar(
        title: const Text('Notifications'),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: const [
          NotificationItem(
            title: 'Humidité critique — Zone B (48%)',
            time: 'Il y a 12 min',
            isRead: false,
            color: AppColors.red600,
          ),
          NotificationItem(
            title: 'Capteur C3 — batterie faible (18%)',
            time: 'Il y a 1h',
            isRead: false,
            color: AppColors.amber600,
          ),
          NotificationItem(
            title: 'Irrigation Zone A terminée',
            time: 'Il y a 3h',
            isRead: true,
            color: AppColors.green600,
          ),
        ],
      ),
    );
  }
}
class NotificationItem extends StatelessWidget {
  final String title;
  final String time;
  final bool isRead;
  final Color color;

  const NotificationItem({
    super.key,
    required this.title,
    required this.time,
    required this.isRead,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: isRead ? AppColors.white : AppColors.green50,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(
          color: isRead ? Colors.transparent : AppColors.green200,
        ),
      ),
      child: Row(
        children: [
          Container(
            width: 10,
            height: 10,
            decoration:
                BoxDecoration(color: color, shape: BoxShape.circle),
          ),
          const SizedBox(width: 10),

          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight:
                        isRead ? FontWeight.normal : FontWeight.w500,
                    color: AppColors.text,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  time,
                  style: const TextStyle(
                    fontSize: 11,
                    color: AppColors.textMuted,
                  ),
                ),
              ],
            ),
          ),

          if (!isRead)
            Container(
              width: 8,
              height: 8,
              decoration: const BoxDecoration(
                color: AppColors.green600,
                shape: BoxShape.circle,
              ),
            ),
        ],
      ),
    );
  }
}*/

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../app_colors.dart';
import '../../services/capteur_service.dart';
import '../../services/seuil_service.dart';
import '../../models/seuil.dart';

// ─────────────────────────────────────────────────────────────────────────────
// Modèle interne d'une notification générée
// ─────────────────────────────────────────────────────────────────────────────
class _Notif {
  final String titre;
  final String sousTitre; // détail supplémentaire
  final String temps;
  final Color couleur;
  final IconData icone;
  final bool isRead;
  final _NotifType type;

  const _Notif({
    required this.titre,
    required this.sousTitre,
    required this.temps,
    required this.couleur,
    required this.icone,
    this.isRead = false,
    required this.type,
  });
}

enum _NotifType { alerteHumidite, batterieFaible, capteurInactif, irrigationOk }

// ─────────────────────────────────────────────────────────────────────────────
// Notifications statiques de fallback
// (affichées si le backend est inaccessible)
// ─────────────────────────────────────────────────────────────────────────────
final List<_Notif> _notifsStatiques = [
  const _Notif(
    titre: 'Humidité critique — Zone B (48%)',
    sousTitre: 'En dessous du seuil de 60%',
    temps: 'Il y a 12 min',
    couleur: AppColors.red600,
    icone: Icons.water_drop_outlined,
    type: _NotifType.alerteHumidite,
  ),
  const _Notif(
    titre: 'Capteur C3 — batterie faible (18%)',
    sousTitre: 'Planifiez un rechargement sous 48h',
    temps: 'Il y a 1h',
    couleur: AppColors.amber600,
    icone: Icons.battery_alert,
    type: _NotifType.batterieFaible,
  ),
  const _Notif(
    titre: 'Irrigation Zone A terminée',
    sousTitre: '45L · 18 min · Manuel',
    temps: 'Il y a 3h',
    couleur: AppColors.green600,
    icone: Icons.check_circle_outline,
    isRead: true,
    type: _NotifType.irrigationOk,
  ),
];

// ─────────────────────────────────────────────────────────────────────────────
// NotificationsScreen
// ─────────────────────────────────────────────────────────────────────────────
class NotificationsScreen extends StatefulWidget {
  const NotificationsScreen({super.key});

  @override
  State<NotificationsScreen> createState() => _NotificationsScreenState();
}

class _NotificationsScreenState extends State<NotificationsScreen> {
  List<_Notif> _notifs = [];
  bool _isLoading = true;
  bool _depuisBackend = false;

  // Suivi des notifications lues localement
  final Set<int> _readIndexes = {};

  @override
  void initState() {
    super.initState();
    _genererNotifications();
  }

  // ── Génération dynamique des notifications ────────────────────────────────
  Future<void> _genererNotifications() async {
    setState(() => _isLoading = true);

    try {
      final capteurService = context.read<CapteurService>();
      final seuilService   = context.read<SeuilService>();

      final results = await Future.wait([
        capteurService.getCapteurs(),
        seuilService.getSeuil(),
      ]);

      final capteurs = results[0] as List;
      final seuil    = results[1] as SeuilModel?;

      // Seuil critique = valeur_min de l'API, ou 60 par défaut
      final double seuilMin = seuil?.valeurMin ?? 60.0;

      final List<_Notif> notifs = [];

      for (final capteur in capteurs) {
        final String nom      = capteur.nom as String;
        final int    batterie = capteur.batterie as int? ?? 100;
        final String etat     = capteur.etat as String? ?? 'actif';

        // ── Capteur inactif ──
        if (etat == 'inactif') {
          notifs.add(_Notif(
            titre:     'Capteur hors ligne — $nom',
            sousTitre: 'Aucune donnée reçue récemment',
            temps:     'Récent',
            couleur:   const Color(0xFFB4B2A9),
            icone:     Icons.sensors_off_outlined,
            type:      _NotifType.capteurInactif,
          ));
          continue;
        }

        // ── Batterie faible ≤ 20% ──
        if (batterie <= 20) {
          notifs.add(_Notif(
            titre:     'Batterie faible — $nom ($batterie%)',
            sousTitre: 'Planifiez un rechargement sous 48h',
            temps:     'Récent',
            couleur:   AppColors.amber600,
            icone:     Icons.battery_alert,
            type:      _NotifType.batterieFaible,
          ));
        }

        // ── Batterie faible entre 21% et 30% (avertissement) ──
        else if (batterie <= 30) {
          notifs.add(_Notif(
            titre:     'Batterie basse — $nom ($batterie%)',
            sousTitre: 'Rechargement recommandé prochainement',
            temps:     'Récent',
            couleur:   AppColors.amber600,
            icone:     Icons.battery_3_bar,
            isRead:    true,
            type:      _NotifType.batterieFaible,
          ));
        }
      }

      // ── Alertes humidité depuis les zones statiques enrichies par le seuil ──
      // (l'API capteur ne retourne pas l'humidité → on utilise les données
      //  statiques de irrigation_models recalculées avec le seuil réel)
      final zonesEnAlerte = _zonesStatiquesEnAlerte(seuilMin);
      for (final zone in zonesEnAlerte) {
        notifs.insert(0, _Notif(
          titre:     'Humidité critique — ${zone['nom']} (${zone['humidite']}%)',
          sousTitre: 'En dessous du seuil de ${seuilMin.toInt()}%',
          temps:     'Récent',
          couleur:   AppColors.red600,
          icone:     Icons.water_drop_outlined,
          type:      _NotifType.alerteHumidite,
        ));
      }

      // ── Notification de succès irrigation (toujours statique) ──
      notifs.add(const _Notif(
        titre:     'Irrigation Zone A terminée',
        sousTitre: '45L · 18 min · Manuel',
        temps:     'Il y a 3h',
        couleur:   AppColors.green600,
        icone:     Icons.check_circle_outline,
        isRead:    true,
        type:      _NotifType.irrigationOk,
      ));

      setState(() {
        _notifs        = notifs.isEmpty ? _notifsStatiques : notifs;
        _depuisBackend = true;
        _isLoading     = false;
      });
    } catch (_) {
      // Backend inaccessible → fallback statique
      setState(() {
        _notifs        = List.from(_notifsStatiques);
        _depuisBackend = false;
        _isLoading     = false;
      });
    }
  }

  // Zones statiques dont l'humidité est sous le seuil donné
  List<Map<String, dynamic>> _zonesStatiquesEnAlerte(double seuil) {
    final statiques = [
      {'nom': 'Zone A', 'humidite': 74},
      {'nom': 'Zone B', 'humidite': 48},
      {'nom': 'Zone C', 'humidite': 81},
      {'nom': 'Zone D', 'humidite': 65},
    ];
    return statiques.where((z) => (z['humidite'] as int) < seuil).toList();
  }

  // ── Marquer une notif comme lue ───────────────────────────────────────────
  void _marquerLue(int index) {
    setState(() => _readIndexes.add(index));
  }

  void _marquerToutesLues() {
    setState(() {
      for (int i = 0; i < _notifs.length; i++) {
        _readIndexes.add(i);
      }
    });
  }

  bool _estLue(int index) => _readIndexes.contains(index) || _notifs[index].isRead;

  int get _nonLues => List.generate(_notifs.length, (i) => i)
      .where((i) => !_estLue(i))
      .length;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.bg,
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Notifications'),
            if (!_isLoading)
              Text(
                _nonLues > 0 ? '$_nonLues non lue${_nonLues > 1 ? 's' : ''}' : 'Tout est à jour',
                style: TextStyle(
                  fontSize: 11,
                  color: _nonLues > 0 ? AppColors.red600 : AppColors.textMuted,
                ),
              ),
          ],
        ),
        actions: [
          // Indicateur source
          if (!_isLoading)
            Padding(
              padding: const EdgeInsets.only(right: 4),
              child: Tooltip(
                message: _depuisBackend ? 'Alertes en ligne' : 'Alertes locales (démo)',
                child: Icon(
                  _depuisBackend ? Icons.cloud_done_outlined : Icons.cloud_off_outlined,
                  color: _depuisBackend ? AppColors.green600 : AppColors.textMuted,
                  size: 18,
                ),
              ),
            ),
          // Bouton "tout lire"
          if (!_isLoading && _nonLues > 0)
            TextButton(
              onPressed: _marquerToutesLues,
              child: const Text(
                'Tout lire',
                style: TextStyle(
                  fontSize: 12,
                  color: AppColors.green700,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
          // Bouton rafraîchir
          IconButton(
            onPressed: _isLoading ? null : _genererNotifications,
            icon: Container(
              width: 34, height: 34,
              decoration: BoxDecoration(
                color: AppColors.green100,
                borderRadius: BorderRadius.circular(9),
              ),
              child: _isLoading
                  ? const Padding(
                      padding: EdgeInsets.all(8),
                      child: CircularProgressIndicator(strokeWidth: 2, color: AppColors.green700),
                    )
                  : const Icon(Icons.refresh, color: AppColors.green700, size: 17),
            ),
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _notifs.isEmpty
              ? _buildVide()
              : Column(
                  children: [
                    // Résumé par type
                    if (_nonLues > 0) _buildResume(),
                    Expanded(
                      child: ListView.builder(
                        padding: const EdgeInsets.all(16),
                        itemCount: _notifs.length,
                        itemBuilder: (context, i) {
                          final n = _notifs[i];
                          return _NotifItem(
                            notif:   n,
                            isRead:  _estLue(i),
                            onTap:   () => _marquerLue(i),
                          );
                        },
                      ),
                    ),
                  ],
                ),
    );
  }

  // ── Résumé des alertes critiques ──────────────────────────────────────────
  Widget _buildResume() {
    final alertes  = _notifs.where((n) => n.type == _NotifType.alerteHumidite).length;
    final batterie = _notifs.where((n) => n.type == _NotifType.batterieFaible).length;
    final inactifs = _notifs.where((n) => n.type == _NotifType.capteurInactif).length;

    return Container(
      margin: const EdgeInsets.fromLTRB(16, 12, 16, 0),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.red100,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.red600.withOpacity(0.25)),
      ),
      child: Row(
        children: [
          const Icon(Icons.warning_amber_rounded, color: AppColors.red600, size: 20),
          const SizedBox(width: 10),
          Expanded(
            child: Wrap(
              spacing: 12,
              children: [
                if (alertes > 0)
                  _ResumePill(label: '$alertes humidité critique', color: AppColors.red600),
                if (batterie > 0)
                  _ResumePill(label: '$batterie batterie faible', color: AppColors.amber600),
                if (inactifs > 0)
                  _ResumePill(label: '$inactifs capteur inactif', color: const Color(0xFFB4B2A9)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildVide() => const Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.notifications_none, size: 48, color: AppColors.textMuted),
            SizedBox(height: 12),
            Text('Aucune notification',
                style: TextStyle(fontSize: 14, color: AppColors.textMuted)),
          ],
        ),
      );
}

// ─────────────────────────────────────────────────────────────────────────────
// _NotifItem
// ─────────────────────────────────────────────────────────────────────────────
class _NotifItem extends StatelessWidget {
  final _Notif notif;
  final bool isRead;
  final VoidCallback onTap;

  const _NotifItem({
    required this.notif,
    required this.isRead,
    required this.onTap,
  });

  Color get _bgColor {
    if (isRead) return AppColors.white;
    switch (notif.type) {
      case _NotifType.alerteHumidite: return AppColors.red100;
      case _NotifType.batterieFaible: return AppColors.amber100;
      case _NotifType.capteurInactif: return AppColors.gray50;
      case _NotifType.irrigationOk:   return AppColors.green50;
    }
  }

  Color get _borderColor {
    if (isRead) return Colors.transparent;
    switch (notif.type) {
      case _NotifType.alerteHumidite: return AppColors.red600.withOpacity(0.25);
      case _NotifType.batterieFaible: return AppColors.amber600.withOpacity(0.25);
      case _NotifType.capteurInactif: return const Color(0xFFB4B2A9).withOpacity(0.25);
      case _NotifType.irrigationOk:   return AppColors.green200;
    }
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        margin: const EdgeInsets.only(bottom: 10),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: _bgColor,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: _borderColor),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Icône
            Container(
              width: 36, height: 36,
              decoration: BoxDecoration(
                color: notif.couleur.withOpacity(0.12),
                borderRadius: BorderRadius.circular(9),
              ),
              child: Icon(notif.icone, color: notif.couleur, size: 18),
            ),
            const SizedBox(width: 10),
            // Texte
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    notif.titre,
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: isRead ? FontWeight.normal : FontWeight.w500,
                      color: AppColors.text,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    notif.sousTitre,
                    style: const TextStyle(fontSize: 11, color: AppColors.textMuted),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    notif.temps,
                    style: const TextStyle(fontSize: 10, color: AppColors.textMuted),
                  ),
                ],
              ),
            ),
            // Point non-lu
            if (!isRead)
              Padding(
                padding: const EdgeInsets.only(top: 4),
                child: Container(
                  width: 8, height: 8,
                  decoration: BoxDecoration(color: notif.couleur, shape: BoxShape.circle),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// _ResumePill — badge dans le bandeau de résumé
// ─────────────────────────────────────────────────────────────────────────────
class _ResumePill extends StatelessWidget {
  final String label;
  final Color color;
  const _ResumePill({required this.label, required this.color});

  @override
  Widget build(BuildContext context) => Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 7, height: 7,
            decoration: BoxDecoration(color: color, shape: BoxShape.circle),
          ),
          const SizedBox(width: 4),
          Text(label, style: TextStyle(fontSize: 11, color: color, fontWeight: FontWeight.w500)),
        ],
      );
}

// ─────────────────────────────────────────────────────────────────────────────
// NotificationItem — widget public conservé pour compatibilité
// avec les autres écrans qui l'utilisent directement
// ─────────────────────────────────────────────────────────────────────────────
class NotificationItem extends StatelessWidget {
  final String title;
  final String time;
  final bool isRead;
  final Color color;

  const NotificationItem({
    super.key,
    required this.title,
    required this.time,
    required this.isRead,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: isRead ? AppColors.white : AppColors.green50,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: isRead ? Colors.transparent : AppColors.green200),
      ),
      child: Row(
        children: [
          Container(
            width: 10, height: 10,
            decoration: BoxDecoration(color: color, shape: BoxShape.circle),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title,
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: isRead ? FontWeight.normal : FontWeight.w500,
                      color: AppColors.text,
                    )),
                const SizedBox(height: 4),
                Text(time, style: const TextStyle(fontSize: 11, color: AppColors.textMuted)),
              ],
            ),
          ),
          if (!isRead)
            Container(
              width: 8, height: 8,
              decoration: const BoxDecoration(color: AppColors.green600, shape: BoxShape.circle),
            ),
        ],
      ),
    );
  }
}