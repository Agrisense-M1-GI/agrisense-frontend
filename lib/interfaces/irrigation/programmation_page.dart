import 'package:flutter/material.dart';
import '../../app_colors.dart';
import 'irrigation_models.dart';

class ProgrammationScreen extends StatefulWidget {
  const ProgrammationScreen({super.key});

  @override
  State<ProgrammationScreen> createState() => _ProgrammationScreenState();
}

class _ProgrammationScreenState extends State<ProgrammationScreen> {
  final List<_Programme> _programmes = [
    _Programme(id:'P1', zone:'Zone A', heure:'06h30', jours:['Lun','Mer','Ven'], quantite:50, actif:true),
    _Programme(id:'P2', zone:'Zone B', heure:'05h00', jours:['Tous les jours'],  quantite:65, actif:true),
    _Programme(id:'P3', zone:'Zone C', heure:'07h00', jours:['Mar','Jeu','Sam'], quantite:40, actif:false),
    _Programme(id:'P4', zone:'Zone D', heure:'06h00', jours:['Lun','Ven'],       quantite:45, actif:true),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.bg,
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: const [
            Text('Programmation'),
            Text('Planification des irrigations', style: TextStyle(fontSize: 11, color: AppColors.textMuted)),
          ],
        ),
        actions: [
          IconButton(
            onPressed: () => _showAjoutProgramme(context),
            icon: Container(
              width: 34, height: 34,
              decoration: BoxDecoration(
                  color: AppColors.green100, borderRadius: BorderRadius.circular(9)),
              child: const Icon(Icons.add, color: AppColors.green700, size: 20),
            ),
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [

          // ── Bandeau info ─────────────────────────────────────────────
          Container(
            padding: const EdgeInsets.all(13),
            decoration: BoxDecoration(
              color: AppColors.green100,
              borderRadius: BorderRadius.circular(13),
              border: Border.all(color: AppColors.green600.withOpacity(0.3)),
            ),
            child: Row(children: [
              const Icon(Icons.schedule, color: AppColors.green700, size: 20),
              const SizedBox(width: 10),
              Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text('${_programmes.where((p) => p.actif).length} programmes actifs',
                    style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w500, color: AppColors.green800)),
                const Text('Les irrigations se déclenchent automatiquement selon le planning.',
                    style: TextStyle(fontSize: 11, color: AppColors.green700, height: 1.4)),
              ])),
            ]),
          ),

          const SizedBox(height: 16),
          const _SectionH('PROGRAMMES DÉFINIS'),
          const SizedBox(height: 10),

          // ── Liste programmes ─────────────────────────────────────────
          ..._programmes.asMap().entries.map((entry) {
            final i = entry.key;
            final p = entry.value;
            return _ProgrammeCard(
              programme: p,
              onToggle: (v) => setState(() => _programmes[i] = p.copyWith(actif: v)),
              onDelete: () => setState(() => _programmes.removeAt(i)),
              onEdit: () => _showEditProgramme(context, p, i),
            );
          }),

          const SizedBox(height: 14),

          // ── Bouton ajouter ───────────────────────────────────────────
          SizedBox(
            width: double.infinity,
            child: OutlinedButton.icon(
              onPressed: () => _showAjoutProgramme(context),
              icon: const Icon(Icons.add, size: 16),
              label: const Text('Ajouter un programme'),
              style: OutlinedButton.styleFrom(
                foregroundColor: AppColors.green700,
                side: const BorderSide(color: AppColors.green600, width: 1.5),
                padding: const EdgeInsets.symmetric(vertical: 13),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                textStyle: const TextStyle(fontSize: 13, fontWeight: FontWeight.w500),
              ),
            ),
          ),

          const SizedBox(height: 16),
          const _SectionH('PROCHAINES IRRIGATIONS PLANIFIÉES'),
          const SizedBox(height: 10),

          _ProchainCard(zone:'Zone A', heure:'Demain 06h30', quantite:50, jours:'Lun · Mer · Ven'),
          const SizedBox(height: 8),
          _ProchainCard(zone:'Zone B', heure:'Demain 05h00', quantite:65, jours:'Tous les jours'),
          const SizedBox(height: 8),
          _ProchainCard(zone:'Zone D', heure:'Lundi 06h00',  quantite:45, jours:'Lun · Ven'),

          const SizedBox(height: 8),
        ],
      ),
    );
  }

  void _showAjoutProgramme(BuildContext context) {
    _showProgrammeSheet(context, null, null);
  }

  void _showEditProgramme(BuildContext context, _Programme p, int idx) {
    _showProgrammeSheet(context, p, idx);
  }

  void _showProgrammeSheet(BuildContext context, _Programme? prog, int? idx) {
    String zoneSelect = prog?.zone ?? zonesIrrigation.first.nom;
    double quantite   = prog?.quantite.toDouble() ?? 50;
    TimeOfDay heure   = TimeOfDay(
        hour:   int.tryParse(prog?.heure.split('h').first ?? '6') ?? 6,
        minute: int.tryParse(prog?.heure.split('h').last ?? '0') ?? 0);
    final joursDispos = ['Lun','Mar','Mer','Jeu','Ven','Sam','Dim'];
    List<String> joursSelect = List.from(prog?.jours ?? ['Lun','Mer','Ven']);

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppColors.white,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (_) => StatefulBuilder(
        builder: (ctx, ss) => Padding(
          padding: EdgeInsets.only(
              left: 20, right: 20, top: 20,
              bottom: MediaQuery.of(ctx).viewInsets.bottom + 20),
          child: SingleChildScrollView(child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(prog == null ? 'Nouveau programme' : 'Modifier le programme',
                  style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w500, color: AppColors.text)),
              const SizedBox(height: 16),

              // Zone
              const _SheetLabel('Zone cible'),
              Wrap(spacing: 8, runSpacing: 8, children: zonesIrrigation.map((z) {
                final sel = zoneSelect == z.nom;
                return GestureDetector(
                  onTap: () => ss(() => zoneSelect = z.nom),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 150),
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                    decoration: BoxDecoration(
                      color: sel ? AppColors.green100 : AppColors.bg,
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: sel ? AppColors.green600 : AppColors.border, width: sel?1.5:0.5),
                    ),
                    child: Text(z.nom, style: TextStyle(fontSize: 12,
                        fontWeight: sel ? FontWeight.w500 : FontWeight.normal,
                        color: sel ? AppColors.green700 : AppColors.textMuted)),
                  ),
                );
              }).toList()),
              const SizedBox(height: 16),

              // Heure
              const _SheetLabel('Heure de déclenchement'),
              GestureDetector(
                onTap: () async {
                  final picked = await showTimePicker(context: ctx, initialTime: heure);
                  if (picked != null) ss(() => heure = picked);
                },
                child: Container(
                  padding: const EdgeInsets.all(13),
                  decoration: BoxDecoration(
                    color: AppColors.green100,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: AppColors.green600.withOpacity(0.3)),
                  ),
                  child: Row(children: [
                    const Icon(Icons.access_time, color: AppColors.green700, size: 20),
                    const SizedBox(width: 10),
                    Text('${heure.hour.toString().padLeft(2,'0')}h${heure.minute.toString().padLeft(2,'0')}',
                        style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w500,
                            color: AppColors.green800)),
                    const Spacer(),
                    const Text('Appuyer pour modifier',
                        style: TextStyle(fontSize: 11, color: AppColors.textMuted)),
                  ]),
                ),
              ),
              const SizedBox(height: 16),

              // Jours
              const _SheetLabel('Jours de la semaine'),
              Row(children: joursDispos.map((j) {
                final sel = joursSelect.contains(j);
                return Expanded(child: GestureDetector(
                  onTap: () => ss(() {
                    if (sel) joursSelect.remove(j); else joursSelect.add(j);
                  }),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 150),
                    margin: const EdgeInsets.only(right: 4),
                    padding: const EdgeInsets.symmetric(vertical: 8),
                    decoration: BoxDecoration(
                      color: sel ? AppColors.green100 : AppColors.bg,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: sel ? AppColors.green600 : AppColors.border, width: sel?1.5:0.5),
                    ),
                    child: Text(j, textAlign: TextAlign.center,
                        style: TextStyle(fontSize: 9,
                            fontWeight: sel ? FontWeight.w600 : FontWeight.normal,
                            color: sel ? AppColors.green700 : AppColors.textMuted)),
                  ),
                ));
              }).toList()),
              const SizedBox(height: 16),

              // Quantité
              const _SheetLabel('Quantité (litres)'),
              Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
                Text('${quantite.round()} L',
                    style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w500, color: AppColors.green700)),
                Text('~${(quantite / 2.5).round()} min',
                    style: const TextStyle(fontSize: 12, color: AppColors.textMuted)),
              ]),
              SliderTheme(
                data: SliderTheme.of(context).copyWith(
                  trackHeight: 5, thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 10),
                  activeTrackColor: AppColors.green600, inactiveTrackColor: const Color(0xFFE8EDE4),
                  thumbColor: AppColors.green600,
                ),
                child: Slider(
                  value: quantite, min: 10, max: 150, divisions: 28,
                  onChanged: (v) => ss(() => quantite = v),
                ),
              ),
              const SizedBox(height: 16),

              // Bouton sauvegarder
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () {
                    final heureStr = '${heure.hour.toString().padLeft(2,'0')}h${heure.minute.toString().padLeft(2,'0')}';
                    final nouveau = _Programme(
                      id: prog?.id ?? 'P${_programmes.length + 1}',
                      zone: zoneSelect, heure: heureStr,
                      jours: joursSelect, quantite: quantite.round(), actif: true,
                    );
                    setState(() {
                      if (idx != null) _programmes[idx] = nouveau;
                      else _programmes.add(nouveau);
                    });
                    Navigator.pop(context);
                    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                      content: Text(prog == null ? 'Programme créé !' : 'Programme mis à jour !'),
                      backgroundColor: AppColors.green700,
                      behavior: SnackBarBehavior.floating,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                    ));
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.green600, foregroundColor: AppColors.white,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  child: Text(prog == null ? 'Créer le programme' : 'Enregistrer',
                      style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w500)),
                ),
              ),
            ],
          )),
        ),
      ),
    );
  }
}

// ── Carte programme ───────────────────────────────────────────────────────────
class _ProgrammeCard extends StatelessWidget {
  final _Programme programme;
  final ValueChanged<bool> onToggle;
  final VoidCallback onDelete, onEdit;
  const _ProgrammeCard({required this.programme, required this.onToggle, required this.onDelete, required this.onEdit});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 9),
      padding: const EdgeInsets.all(13),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(13),
        border: Border.all(
            color: programme.actif ? AppColors.green600.withOpacity(0.3) : AppColors.border,
            width: programme.actif ? 1 : 0.5),
      ),
      child: Column(children: [
        Row(children: [
          Container(
            width: 38, height: 38,
            decoration: BoxDecoration(
              color: programme.actif ? AppColors.green100 : AppColors.gray50,
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(Icons.water_drop_outlined,
                color: programme.actif ? AppColors.green700 : AppColors.textMuted, size: 18),
          ),
          const SizedBox(width: 10),
          Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(programme.zone,
                style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w500, color: AppColors.text)),
            Text('${programme.heure} · ${programme.quantite}L · ~${(programme.quantite / 2.5).round()} min',
                style: const TextStyle(fontSize: 11, color: AppColors.textMuted)),
          ])),
          Switch(
            value: programme.actif,
            onChanged: onToggle,
            activeColor: AppColors.green600,
            materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
          ),
        ]),
        const SizedBox(height: 10),
        // Jours
        Row(children: programme.jours.map((j) => Container(
          margin: const EdgeInsets.only(right: 5),
          padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
          decoration: BoxDecoration(
            color: programme.actif ? AppColors.green100 : AppColors.gray50,
            borderRadius: BorderRadius.circular(20),
          ),
          child: Text(j, style: TextStyle(fontSize: 10, fontWeight: FontWeight.w500,
              color: programme.actif ? AppColors.green700 : AppColors.textMuted)),
        )).toList()),
        const SizedBox(height: 10),
        Row(mainAxisAlignment: MainAxisAlignment.end, children: [
          GestureDetector(
            onTap: onEdit,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                  color: AppColors.green50, borderRadius: BorderRadius.circular(8)),
              child: const Row(children: [
                Icon(Icons.edit_outlined, size: 13, color: AppColors.green700),
                SizedBox(width: 4),
                Text('Modifier', style: TextStyle(fontSize: 11, color: AppColors.green700)),
              ]),
            ),
          ),
          const SizedBox(width: 8),
          GestureDetector(
            onTap: onDelete,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                  color: AppColors.red100, borderRadius: BorderRadius.circular(8)),
              child: const Row(children: [
                Icon(Icons.delete_outline, size: 13, color: AppColors.red600),
                SizedBox(width: 4),
                Text('Supprimer', style: TextStyle(fontSize: 11, color: AppColors.red600)),
              ]),
            ),
          ),
        ]),
      ]),
    );
  }
}

// ── Prochain card ─────────────────────────────────────────────────────────────
class _ProchainCard extends StatelessWidget {
  final String zone, heure, jours;
  final int quantite;
  const _ProchainCard({required this.zone, required this.heure, required this.quantite, required this.jours});

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.all(12),
    decoration: BoxDecoration(
      color: AppColors.white,
      borderRadius: BorderRadius.circular(12),
      border: Border.all(color: AppColors.border, width: 0.5),
    ),
    child: Row(children: [
      Container(
        width: 40, height: 40,
        decoration: BoxDecoration(color: AppColors.green100, borderRadius: BorderRadius.circular(10)),
        child: const Icon(Icons.schedule, color: AppColors.green700, size: 20),
      ),
      const SizedBox(width: 11),
      Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text(zone, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w500, color: AppColors.text)),
        Text('$heure · $jours', style: const TextStyle(fontSize: 11, color: AppColors.textMuted)),
      ])),
      Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        decoration: BoxDecoration(color: AppColors.green100, borderRadius: BorderRadius.circular(20)),
        child: Text('$quantite L', style: const TextStyle(fontSize: 11,
            fontWeight: FontWeight.w500, color: AppColors.green700)),
      ),
    ]),
  );
}

// ── Widgets utilitaires ───────────────────────────────────────────────────────
class _SectionH extends StatelessWidget {
  final String text;
  const _SectionH(this.text);
  @override
  Widget build(BuildContext context) => Text(text,
      style: const TextStyle(fontSize: 10, fontWeight: FontWeight.w500,
          color: AppColors.textMuted, letterSpacing: 0.8));
}

class _SheetLabel extends StatelessWidget {
  final String text;
  const _SheetLabel(this.text);
  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(bottom: 10),
    child: Text(text.toUpperCase(),
        style: const TextStyle(fontSize: 10, fontWeight: FontWeight.w500,
            color: AppColors.textMuted, letterSpacing: 0.8)),
  );
}

// ── Modèle programme ──────────────────────────────────────────────────────────
class _Programme {
  final String id, zone, heure;
  final List<String> jours;
  final int quantite;
  final bool actif;

  const _Programme({
    required this.id, required this.zone, required this.heure,
    required this.jours, required this.quantite, required this.actif,
  });

  _Programme copyWith({bool? actif}) => _Programme(
      id: id, zone: zone, heure: heure,
      jours: jours, quantite: quantite,
      actif: actif ?? this.actif);
}