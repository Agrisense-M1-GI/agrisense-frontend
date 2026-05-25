import 'package:flutter/material.dart';
import '../../app_colors.dart';
import '../../models/irrigation.dart';

class LancerIrrigationScreen extends StatefulWidget {
  final String? zonePreselect;
  const LancerIrrigationScreen({super.key, this.zonePreselect});

  @override
  State<LancerIrrigationScreen> createState() => _LancerIrrigationScreenState();
}

class _LancerIrrigationScreenState extends State<LancerIrrigationScreen> {
  late String _zoneSelectionnee;
  double _quantite = 50;
  double _duree    = 20;
  final _noteCtrl  = TextEditingController();
  bool _isLaunching = false;
  bool _lancee = false;

  @override
  void initState() {
    super.initState();
    _zoneSelectionnee = widget.zonePreselect ?? zonesIrrigation.first.nom;
  }

  @override
  void dispose() {
    _noteCtrl.dispose();
    super.dispose();
  }

  ZoneIrrigation get _zoneActuelle =>
      zonesIrrigation.firstWhere((z) => z.nom == _zoneSelectionnee);

  Future<void> _lancer() async {
    setState(() => _isLaunching = true);
    await Future.delayed(const Duration(milliseconds: 1400));
    setState(() { _isLaunching = false; _lancee = true; });
  }

  @override
  Widget build(BuildContext context) {
    if (_lancee) return _buildSucces(context);

    return Scaffold(
      backgroundColor: AppColors.bg,
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: const [
            Text('Lancer l\'irrigation'),
            Text('Configuration manuelle',
                style: TextStyle(fontSize: 11, color: AppColors.textMuted)),
          ],
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [

            // ── Sélection zone ────────────────────────────────────────
            _SectionH('Sélection de la zone'),
            Wrap(
              spacing: 8, runSpacing: 8,
              children: zonesIrrigation.map((z) {
                final sel = _zoneSelectionnee == z.nom;
                final isAlerte = z.statut == 'alerte';
                return GestureDetector(
                  onTap: () => setState(() => _zoneSelectionnee = z.nom),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 180),
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 9),
                    decoration: BoxDecoration(
                      color: sel ? zoneStatutBg(z.statut) : AppColors.white,
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(
                        color: sel ? zoneStatutColor(z.statut) : AppColors.border,
                        width: sel ? 1.5 : 0.5,
                      ),
                    ),
                    child: Row(mainAxisSize: MainAxisSize.min, children: [
                      Text(z.nom,
                          style: TextStyle(
                              fontSize: 12,
                              fontWeight: sel ? FontWeight.w500 : FontWeight.normal,
                              color: sel ? zoneStatutColor(z.statut) : AppColors.textMuted)),
                      if (isAlerte) ...[
                        const SizedBox(width: 5),
                        const Icon(Icons.warning_amber_rounded,
                            color: AppColors.red600, size: 13),
                      ],
                    ]),
                  ),
                );
              }).toList(),
            ),

            const SizedBox(height: 16),

            // ── Info zone sélectionnée ────────────────────────────────
            _InfoZoneCard(zone: _zoneActuelle),

            const SizedBox(height: 16),

            // ── Paramètres arrosage ───────────────────────────────────
            _SectionH('Paramètres d\'arrosage'),
            _FormCard(children: [
              // Quantité
              Padding(
                padding: const EdgeInsets.all(14),
                child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
                    const Text('Quantité d\'eau',
                        style: TextStyle(fontSize: 13, fontWeight: FontWeight.w500, color: AppColors.text)),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                      decoration: BoxDecoration(
                          color: AppColors.green100, borderRadius: BorderRadius.circular(20)),
                      child: Text('${_quantite.round()} L',
                          style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500,
                              color: AppColors.green700)),
                    ),
                  ]),
                  const SizedBox(height: 10),
                  SliderTheme(
                    data: SliderTheme.of(context).copyWith(
                      trackHeight: 5,
                      thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 10),
                      overlayShape: const RoundSliderOverlayShape(overlayRadius: 20),
                      activeTrackColor: AppColors.green600,
                      inactiveTrackColor: const Color(0xFFE8EDE4),
                      thumbColor: AppColors.green600,
                      overlayColor: AppColors.green600.withOpacity(0.15),
                    ),
                    child: Slider(
                      value: _quantite, min: 10, max: 150, divisions: 28,
                      onChanged: (v) => setState(() {
                        _quantite = v;
                        _duree = (_quantite / 2.5).roundToDouble();
                      }),
                    ),
                  ),
                  Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: const [
                    Text('10 L', style: TextStyle(fontSize: 10, color: AppColors.textMuted)),
                    Text('150 L', style: TextStyle(fontSize: 10, color: AppColors.textMuted)),
                  ]),
                ]),
              ),

              const Divider(height: 0.5, thickness: 0.5, color: Color(0xFFF0F5EB)),

              // Durée estimée
              Padding(
                padding: const EdgeInsets.all(14),
                child: Row(children: [
                  const Icon(Icons.timer_outlined, color: AppColors.green600, size: 18),
                  const SizedBox(width: 12),
                  const Expanded(child: Text('Durée estimée',
                      style: TextStyle(fontSize: 13, color: AppColors.text))),
                  Text('~${_duree.round()} min',
                      style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w500,
                          color: AppColors.text)),
                ]),
              ),

              const Divider(height: 0.5, thickness: 0.5, color: Color(0xFFF0F5EB)),

              // Note
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
                child: Row(children: [
                  const Icon(Icons.notes_outlined, color: AppColors.green600, size: 18),
                  const SizedBox(width: 12),
                  Expanded(
                    child: TextField(
                      controller: _noteCtrl,
                      style: const TextStyle(fontSize: 13, color: AppColors.text),
                      decoration: const InputDecoration(
                        hintText: 'Note (optionnel)...',
                        hintStyle: TextStyle(fontSize: 13, color: AppColors.textMuted),
                        border: InputBorder.none,
                        isDense: true,
                        contentPadding: EdgeInsets.symmetric(vertical: 12),
                      ),
                    ),
                  ),
                ]),
              ),
            ]),

            const SizedBox(height: 16),

            // ── Résumé ────────────────────────────────────────────────
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: AppColors.green100,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: AppColors.green600.withOpacity(0.3)),
              ),
              child: Column(children: [
                const Text('Résumé de la commande',
                    style: TextStyle(fontSize: 11, fontWeight: FontWeight.w500,
                        color: AppColors.green700)),
                const SizedBox(height: 10),
                _ResumeLigne(label: 'Zone cible',       value: _zoneSelectionnee),
                _ResumeLigne(label: 'Capteur associé',  value: _zoneActuelle.capteurId),
                _ResumeLigne(label: 'Quantité',         value: '${_quantite.round()} L'),
                _ResumeLigne(label: 'Durée estimée',    value: '~${_duree.round()} min'),
                _ResumeLigne(label: 'Mode',             value: 'Manuel', isLast: true),
              ]),
            ),

            const SizedBox(height: 16),

            // ── Avertissement si alerte ───────────────────────────────
            if (_zoneActuelle.statut == 'alerte')
              Container(
                margin: const EdgeInsets.only(bottom: 12),
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: AppColors.red100,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: AppColors.red600.withOpacity(0.3)),
                ),
                child: Row(children: [
                  const Icon(Icons.warning_amber_rounded,
                      color: AppColors.red600, size: 18),
                  const SizedBox(width: 8),
                  const Expanded(child: Text(
                    'Cette zone est en alerte humidité. Une irrigation immédiate est recommandée.',
                    style: TextStyle(fontSize: 11, color: AppColors.red800, height: 1.4),
                  )),
                ]),
              ),

            // ── Boutons ───────────────────────────────────────────────
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: _isLaunching ? null : _lancer,
                icon: _isLaunching
                    ? const SizedBox(width: 16, height: 16,
                        child: CircularProgressIndicator(
                            strokeWidth: 2, color: AppColors.white))
                    : const Icon(Icons.play_arrow_rounded, size: 18),
                label: Text(_isLaunching ? 'Lancement...' : 'Confirmer et lancer'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.green600,
                  foregroundColor: AppColors.white,
                  disabledBackgroundColor: AppColors.green200,
                  padding: const EdgeInsets.symmetric(vertical: 15),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  textStyle: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500),
                ),
              ),
            ),
            const SizedBox(height: 8),
            SizedBox(
              width: double.infinity,
              child: TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Annuler',
                    style: TextStyle(color: AppColors.textMuted, fontSize: 13)),
              ),
            ),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
  }

  Widget _buildSucces(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.bg,
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                width: 90, height: 90,
                decoration: const BoxDecoration(
                    color: AppColors.green100, shape: BoxShape.circle),
                child: const Icon(Icons.check_circle_outline,
                    color: AppColors.green600, size: 48),
              ),
              const SizedBox(height: 20),
              const Text('Irrigation lancée !',
                  style: TextStyle(fontSize: 22, fontWeight: FontWeight.w500,
                      color: AppColors.text)),
              const SizedBox(height: 8),
              Text(
                'L\'irrigation sur $_zoneSelectionnee a démarré avec succès.\n'
                '${_quantite.round()} L · ~${_duree.round()} min · Mode manuel',
                textAlign: TextAlign.center,
                style: const TextStyle(fontSize: 13, color: AppColors.textMuted, height: 1.5),
              ),
              const SizedBox(height: 30),
              // Indicateur en cours
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: AppColors.green100,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: AppColors.green600.withOpacity(0.3)),
                ),
                child: Column(children: [
                  Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
                    const Text('Progression',
                        style: TextStyle(fontSize: 13, fontWeight: FontWeight.w500,
                            color: AppColors.text)),
                    Text('~${_duree.round()} min restantes',
                        style: const TextStyle(fontSize: 11, color: AppColors.textMuted)),
                  ]),
                  const SizedBox(height: 10),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(4),
                    child: const LinearProgressIndicator(
                      value: 0.08,
                      minHeight: 8,
                      backgroundColor: Color(0xFFE8EDE4),
                      valueColor: AlwaysStoppedAnimation<Color>(AppColors.green600),
                    ),
                  ),
                  const SizedBox(height: 8),
                  Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
                    Text(_zoneSelectionnee,
                        style: const TextStyle(fontSize: 11, color: AppColors.green700,
                            fontWeight: FontWeight.w500)),
                    const Text('En cours...',
                        style: TextStyle(fontSize: 11, color: AppColors.green700)),
                  ]),
                ]),
              ),
              const SizedBox(height: 28),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () => Navigator.popUntil(context, (r) => r.isFirst),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.green600,
                    foregroundColor: AppColors.white,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  child: const Text('Retour au tableau de bord',
                      style: TextStyle(fontSize: 13, fontWeight: FontWeight.w500)),
                ),
              ),
              const SizedBox(height: 10),
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Arrêter l\'irrigation',
                    style: TextStyle(color: AppColors.red800, fontSize: 13)),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ── Widgets internes ──────────────────────────────────────────────────────────
class _SectionH extends StatelessWidget {
  final String text;
  const _SectionH(this.text);
  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(bottom: 10),
    child: Text(text.toUpperCase(),
        style: const TextStyle(fontSize: 10, fontWeight: FontWeight.w500,
            color: AppColors.textMuted, letterSpacing: 0.8)),
  );
}

class _FormCard extends StatelessWidget {
  final List<Widget> children;
  const _FormCard({required this.children});
  @override
  Widget build(BuildContext context) => Container(
    decoration: BoxDecoration(
      color: AppColors.white,
      borderRadius: BorderRadius.circular(15),
      border: Border.all(color: AppColors.border, width: 0.5),
    ),
    child: Column(children: children),
  );
}

class _InfoZoneCard extends StatelessWidget {
  final ZoneIrrigation zone;
  const _InfoZoneCard({required this.zone});

  @override
  Widget build(BuildContext context) {
    final color = zoneStatutColor(zone.statut);
    final bg    = zoneStatutBg(zone.statut);

    return Container(
      padding: const EdgeInsets.all(13),
      decoration: BoxDecoration(
        color: bg.withOpacity(0.5),
        borderRadius: BorderRadius.circular(13),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Row(children: [
        Container(
          width: 42, height: 42,
          decoration: BoxDecoration(color: bg, borderRadius: BorderRadius.circular(11)),
          child: Icon(zoneStatutIcon(zone.statut), color: color, size: 20),
        ),
        const SizedBox(width: 12),
        Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(zone.nom,
              style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w500,
                  color: AppColors.text)),
          Text('Humidité : ${zone.humidite.toInt()}% · ${zone.surface} ha · ${zone.capteurId}',
              style: const TextStyle(fontSize: 11, color: AppColors.textMuted)),
          const SizedBox(height: 4),
          // Barre humidité
          ClipRRect(
            borderRadius: BorderRadius.circular(3),
            child: LinearProgressIndicator(
              value: zone.humidite / 100,
              minHeight: 4,
              backgroundColor: const Color(0xFFE8EDE4),
              valueColor: AlwaysStoppedAnimation<Color>(
                zone.humidite < 50 ? AppColors.red600
                    : zone.humidite < 65 ? AppColors.amber600
                    : AppColors.green600,
              ),
            ),
          ),
        ])),
      ]),
    );
  }
}

class _ResumeLigne extends StatelessWidget {
  final String label, value;
  final bool isLast;
  const _ResumeLigne({required this.label, required this.value, this.isLast = false});

  @override
  Widget build(BuildContext context) => Padding(
    padding: EdgeInsets.only(bottom: isLast ? 0 : 6),
    child: Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
      Text(label, style: const TextStyle(fontSize: 12, color: AppColors.green700)),
      Text(value,  style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w500,
          color: AppColors.green800)),
    ]),
  );
}