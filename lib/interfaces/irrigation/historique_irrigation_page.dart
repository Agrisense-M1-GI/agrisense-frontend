import 'package:flutter/material.dart';
import '../../app_colors.dart';
import '../../widget.dart';
import '../../models/irrigation.dart';

class HistoriqueIrrigationScreen extends StatefulWidget {
  const HistoriqueIrrigationScreen({super.key});

  @override
  State<HistoriqueIrrigationScreen> createState() => _HistoriqueIrrigationScreenState();
}

class _HistoriqueIrrigationScreenState extends State<HistoriqueIrrigationScreen> {
  String _filtreZone   = 'Toutes';
  String _filtreMode   = 'Tous';
  String _filtreStatut = 'Tous';

  final List<String> _zones   = ['Toutes', 'Zone A', 'Zone B', 'Zone C', 'Zone D'];
  final List<String> _modes   = ['Tous', 'Manuel', 'Auto'];
  final List<String> _statuts = ['Tous', 'Succès', 'Échec'];

  List<IrrigationSession> get _filtrees {
    var s = List<IrrigationSession>.from(sessionsHistorique);
    if (_filtreZone != 'Toutes')   s = s.where((e) => e.zone == _filtreZone).toList();
    if (_filtreMode == 'Manuel')   s = s.where((e) => e.mode == 'manuel').toList();
    if (_filtreMode == 'Auto')     s = s.where((e) => e.mode == 'auto').toList();
    if (_filtreStatut == 'Succès') s = s.where((e) => e.statut == 'succes').toList();
    if (_filtreStatut == 'Échec')  s = s.where((e) => e.statut == 'echec').toList();
    return s;
  }

  Map<String, List<IrrigationSession>> get _grouped {
    final Map<String, List<IrrigationSession>> m = {};
    for (final s in _filtrees) {
      m.putIfAbsent(s.date, () => []).add(s);
    }
    return m;
  }

  // Stats globales
  int get _totalLitres   => sessionsHistorique.where((s) => s.statut == 'succes').fold(0, (a, s) => a + s.quantiteLitres);
  int get _totalSessions => sessionsHistorique.length;
  int get _echecSessions => sessionsHistorique.where((s) => s.statut == 'echec').length;
  int get _totalMins     => sessionsHistorique.where((s) => s.statut == 'succes').fold(0, (a, s) => a + s.dureeMins);

  @override
  Widget build(BuildContext context) {
    final grouped = _grouped;

    return Scaffold(
      backgroundColor: AppColors.bg,
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: const [
            Text('Historique irrigation'),
            Text('Toutes les sessions', style: TextStyle(fontSize: 11, color: AppColors.textMuted)),
          ],
        ),
        actions: [
          IconButton(
            onPressed: () => _showFiltres(context),
            icon: Container(
              width: 34, height: 34,
              decoration: BoxDecoration(
                  color: AppColors.green100, borderRadius: BorderRadius.circular(9)),
              child: const Icon(Icons.filter_list, color: AppColors.green700, size: 17),
            ),
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: Column(
        children: [

          // ── Stats globales ────────────────────────────────────────────
          Container(
            color: AppColors.white,
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 14),
            child: Row(children: [
              _StatBox(valeur: '$_totalSessions', label: 'Sessions', color: AppColors.green700, bg: AppColors.green100),
              const SizedBox(width: 8),
              _StatBox(valeur: '${_totalLitres}L', label: 'Total eau', color: AppColors.green700, bg: AppColors.green100),
              const SizedBox(width: 8),
              _StatBox(valeur: '${_totalMins}min', label: 'Durée totale', color: AppColors.green700, bg: AppColors.green100),
              const SizedBox(width: 8),
              _StatBox(valeur: '$_echecSessions', label: 'Échecs',
                  color: _echecSessions > 0 ? AppColors.red800 : AppColors.green700,
                  bg: _echecSessions > 0 ? AppColors.red100 : AppColors.green100),
            ]),
          ),

          // ── Filtre zone horizontal ────────────────────────────────────
          Container(
            color: AppColors.white,
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
            child: SizedBox(
              height: 32,
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                itemCount: _zones.length,
                separatorBuilder: (_, __) => const SizedBox(width: 7),
                itemBuilder: (_, i) {
                  final z = _zones[i];
                  final sel = _filtreZone == z;
                  return GestureDetector(
                    onTap: () => setState(() => _filtreZone = z),
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 150),
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(
                        color: sel ? AppColors.green100 : AppColors.bg,
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(
                            color: sel ? AppColors.green600 : AppColors.border,
                            width: sel ? 1.5 : 0.5),
                      ),
                      child: Text(z, style: TextStyle(fontSize: 11,
                          fontWeight: sel ? FontWeight.w500 : FontWeight.normal,
                          color: sel ? AppColors.green700 : AppColors.textMuted)),
                    ),
                  );
                },
              ),
            ),
          ),

          const Divider(height: 0.5, thickness: 0.5, color: AppColors.border),

          // ── Liste groupée ─────────────────────────────────────────────
          Expanded(
            child: _filtrees.isEmpty
                ? _buildEmpty()
                : ListView.builder(
                    padding: const EdgeInsets.all(14),
                    itemCount: grouped.length,
                    itemBuilder: (_, sIdx) {
                      final date = grouped.keys.elementAt(sIdx);
                      final sessions = grouped[date]!;
                      final litresJour = sessions.where((s) => s.statut == 'succes')
                          .fold(0, (a, s) => a + s.quantiteLitres);

                      return Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Padding(
                            padding: EdgeInsets.only(
                                top: sIdx == 0 ? 0 : 14, bottom: 10),
                            child: Row(children: [
                              Text(date.toUpperCase(),
                                  style: const TextStyle(fontSize: 10,
                                      fontWeight: FontWeight.w500,
                                      color: AppColors.textMuted,
                                      letterSpacing: 0.8)),
                              const SizedBox(width: 8),
                              Expanded(child: Container(height: 0.5, color: AppColors.border)),
                              const SizedBox(width: 8),
                              Text('${sessions.length} session(s) · ${litresJour}L',
                                  style: const TextStyle(fontSize: 10, color: AppColors.textMuted)),
                            ]),
                          ),
                          ...sessions.map((s) => _SessionCard(session: s)),
                        ],
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmpty() => Center(
    child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
      Container(width: 64, height: 64,
        decoration: BoxDecoration(color: AppColors.green100, borderRadius: BorderRadius.circular(18)),
        child: const Icon(Icons.water_drop_outlined, color: AppColors.green600, size: 32)),
      const SizedBox(height: 14),
      const Text('Aucune session', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w500, color: AppColors.text)),
      const SizedBox(height: 6),
      const Text('Aucune session ne correspond aux filtres.',
          textAlign: TextAlign.center,
          style: TextStyle(fontSize: 13, color: AppColors.textMuted)),
    ]),
  );

  void _showFiltres(BuildContext context) {
    showModalBottomSheet(
      context: context,
      backgroundColor: AppColors.white,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (_) => StatefulBuilder(
        builder: (ctx, ss) => Padding(
          padding: const EdgeInsets.all(20),
          child: Column(mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
            const Text('Filtres', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w500, color: AppColors.text)),
            const SizedBox(height: 16),
            _FiltreGroupe(titre: 'MODE', options: _modes, valeur: _filtreMode,
                onChanged: (v) { ss(() => _filtreMode = v); setState(() => _filtreMode = v); }),
            const SizedBox(height: 12),
            _FiltreGroupe(titre: 'STATUT', options: _statuts, valeur: _filtreStatut,
                onChanged: (v) { ss(() => _filtreStatut = v); setState(() => _filtreStatut = v); }),
            const SizedBox(height: 20),
            SizedBox(width: double.infinity,
              child: ElevatedButton(
                onPressed: () => Navigator.pop(context),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.green600, foregroundColor: AppColors.white,
                  padding: const EdgeInsets.symmetric(vertical: 13),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
                child: const Text('Appliquer', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w500)),
              ),
            ),
            const SizedBox(height: 8),
          ]),
        ),
      ),
    );
  }
}

// ── Session card ──────────────────────────────────────────────────────────────
class _SessionCard extends StatelessWidget {
  final IrrigationSession session;
  const _SessionCard({required this.session});

  @override
  Widget build(BuildContext context) {
    final color = sessionStatutColor(session.statut);
    final bg    = sessionStatutBg(session.statut);
    final label = sessionStatutLabel(session.statut);
    final isEchec = session.statut == 'echec';

    return Container(
      margin: const EdgeInsets.only(bottom: 9),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(13),
        border: Border.all(
            color: isEchec ? AppColors.red600.withOpacity(0.3) : AppColors.border,
            width: 0.5),
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [
          Container(
            width: 36, height: 36,
            decoration: BoxDecoration(color: bg, borderRadius: BorderRadius.circular(9)),
            child: Icon(isEchec ? Icons.error_outline : Icons.water_drop_outlined,
                color: color, size: 18),
          ),
          const SizedBox(width: 10),
          Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text('${session.zone} · ${session.capteurId}',
                style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w500, color: AppColors.text)),
            Text('${session.heure} · ${session.mode == "auto" ? "Automatique" : "Manuel"}',
                style: const TextStyle(fontSize: 11, color: AppColors.textMuted)),
          ])),
          StatusPill(label: label, bg: bg, textColor: color),
        ]),

        if (!isEchec) ...[
          const SizedBox(height: 10),
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
                color: AppColors.bg, borderRadius: BorderRadius.circular(9)),
            child: Row(mainAxisAlignment: MainAxisAlignment.spaceAround, children: [
              _InfoChip(icon: Icons.water_drop_outlined, label: '${session.quantiteLitres} L'),
              _InfoChip(icon: Icons.timer_outlined,      label: '${session.dureeMins} min'),
              _InfoChip(icon: session.mode == 'auto'
                  ? Icons.auto_mode : Icons.touch_app_outlined,
                  label: session.mode == 'auto' ? 'Auto' : 'Manuel'),
            ]),
          ),
        ],

        if (session.note != null) ...[
          const SizedBox(height: 8),
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: isEchec ? AppColors.red100 : AppColors.green50,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Row(children: [
              Icon(isEchec ? Icons.warning_amber_outlined : Icons.notes_outlined,
                  size: 13, color: isEchec ? AppColors.red600 : AppColors.textMuted),
              const SizedBox(width: 6),
              Expanded(child: Text(session.note!,
                  style: TextStyle(fontSize: 11,
                      color: isEchec ? AppColors.red800 : AppColors.textMuted))),
            ]),
          ),
        ],
      ]),
    );
  }
}

// ── Widgets utilitaires ───────────────────────────────────────────────────────
class _StatBox extends StatelessWidget {
  final String valeur, label;
  final Color color, bg;
  const _StatBox({required this.valeur, required this.label, required this.color, required this.bg});
  @override
  Widget build(BuildContext context) => Expanded(child: Container(
    padding: const EdgeInsets.symmetric(vertical: 9, horizontal: 8),
    decoration: BoxDecoration(color: bg, borderRadius: BorderRadius.circular(12)),
    child: Column(children: [
      Text(valeur, style: TextStyle(fontSize: 14, fontWeight: FontWeight.w500, color: color)),
      Text(label,  style: const TextStyle(fontSize: 9, color: AppColors.textMuted)),
    ]),
  ));
}

class _InfoChip extends StatelessWidget {
  final IconData icon;
  final String label;
  const _InfoChip({required this.icon, required this.label});
  @override
  Widget build(BuildContext context) => Row(children: [
    Icon(icon, size: 13, color: AppColors.textMuted),
    const SizedBox(width: 4),
    Text(label, style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w500, color: AppColors.text)),
  ]);
}

class _FiltreGroupe extends StatelessWidget {
  final String titre;
  final List<String> options;
  final String valeur;
  final ValueChanged<String> onChanged;
  const _FiltreGroupe({required this.titre, required this.options, required this.valeur, required this.onChanged});
  @override
  Widget build(BuildContext context) => Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
    Text(titre, style: const TextStyle(fontSize: 10, fontWeight: FontWeight.w500,
        color: AppColors.textMuted, letterSpacing: 0.8)),
    const SizedBox(height: 8),
    Wrap(spacing: 8, children: options.map((o) {
      final sel = valeur == o;
      return GestureDetector(
        onTap: () => onChanged(o),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 150),
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
          decoration: BoxDecoration(
            color: sel ? AppColors.green100 : AppColors.bg,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: sel ? AppColors.green600 : AppColors.border, width: sel ? 1.5 : 0.5),
          ),
          child: Text(o, style: TextStyle(fontSize: 12,
              fontWeight: sel ? FontWeight.w500 : FontWeight.normal,
              color: sel ? AppColors.green700 : AppColors.textMuted)),
        ),
      );
    }).toList()),
  ]);
}