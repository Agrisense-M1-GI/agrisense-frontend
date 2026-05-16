import 'package:flutter/material.dart';
import '../../app_colors.dart';
import '../../widget.dart';
import 'details_image_page.dart';
import 'historique_image_page.dart';
import 'analyse_ia_page.dart';
import 'image_model.dart';

class ImagesScreen extends StatefulWidget {
  const ImagesScreen({super.key});
  @override
  State<ImagesScreen> createState() => _ImagesScreenState();
}

class _ImagesScreenState extends State<ImagesScreen> {
  String _capteurSel = 'C1';
  String _filtre = 'Toutes';
  final List<String> _capteurs = ['C1','C2','C3','C4','C5','C6','C7','C8'];
  final List<String> _filtres = ['Toutes','Alertes','Analysées','Normales'];

  List<CaptureImage> get _imgsFiltrees {
    if (_filtre == 'Alertes')   return mockImages.where((i) => i.statut == 'alerte').toList();
    if (_filtre == 'Analysées') return mockImages.where((i) => i.statut == 'analysee').toList();
    if (_filtre == 'Normales')  return mockImages.where((i) => i.statut == 'normale').toList();
    return mockImages;
  }

  @override
  Widget build(BuildContext context) {
    final info = infoCapteurs[_capteurSel]!;
    final alertCount = mockImages.where((i) => i.statut == 'alerte').length;
    return Scaffold(
      backgroundColor: AppColors.bg,
      appBar: AppBar(
        title: Column(crossAxisAlignment: CrossAxisAlignment.start, children: const [
          Text('Images & capteurs'),
          Text('Analyse visuelle du champ', style: TextStyle(fontSize: 11, color: AppColors.textMuted)),
        ]),
        actions: [
          if (alertCount > 0)
            Stack(children: [
              IconButton(
                onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const AnalyseIaScreen())),
                icon: const Icon(Icons.auto_awesome_outlined, color: AppColors.green700),
              ),
              Positioned(top:6,right:6,child: Container(
                width:16,height:16,
                decoration: const BoxDecoration(color: AppColors.red600, shape: BoxShape.circle),
                child: Center(child: Text('$alertCount', style: const TextStyle(color: Colors.white, fontSize: 9, fontWeight: FontWeight.w700))),
              )),
            ]),
          IconButton(
            onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const HistoriqueImagesScreen())),
            icon: Container(
              width:34,height:34,
              decoration: BoxDecoration(color: AppColors.green100, borderRadius: BorderRadius.circular(9)),
              child: const Icon(Icons.history, color: AppColors.green700, size:18),
            ),
          ),
          const SizedBox(width:8),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(14),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [

          // Sélecteur capteur
          SizedBox(height:38, child: ListView.separated(
            scrollDirection: Axis.horizontal,
            itemCount: _capteurs.length,
            separatorBuilder: (_,__) => const SizedBox(width:7),
            itemBuilder: (_,i) {
              final c = _capteurs[i];
              final sel = _capteurSel == c;
              final inf = infoCapteurs[c]!;
              return GestureDetector(
                onTap: () => setState(() => _capteurSel = c),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 180),
                  padding: const EdgeInsets.symmetric(horizontal:14, vertical:8),
                  decoration: BoxDecoration(
                    color: sel ? statutBg(inf['statut']!) : AppColors.white,
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: sel ? statutColor(inf['statut']!) : AppColors.border, width: sel?1.5:0.5),
                  ),
                  child: Row(children: [
                    Text(c, style: TextStyle(fontSize:12, fontWeight: sel?FontWeight.w600:FontWeight.normal, color: sel?statutColor(inf['statut']!):AppColors.textMuted)),
                    if (inf['statut']=='alerte') ...[const SizedBox(width:4), Container(width:6,height:6,decoration: const BoxDecoration(color:AppColors.red600,shape:BoxShape.circle))],
                  ]),
                ),
              );
            },
          )),

          const SizedBox(height:14),

          // Carte capteur
          AppCard(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
              Text('$_capteurSel — ${info['zone']}', style: const TextStyle(fontSize:13, fontWeight:FontWeight.w500, color:AppColors.text)),
              StatusPill(label: statutLabel(info['statut']!), bg: statutBg(info['statut']!), textColor: statutColor(info['statut']!)),
            ]),
            const SizedBox(height:11),
            Row(children: [
              _Stat(label:'Batterie', value:info['batterie']!),
              const SizedBox(width:8),
              _Stat(label:'Signal',   value:info['signal']!),
              const SizedBox(width:8),
              _Stat(label:'Surface',  value:info['surface']!),
              const SizedBox(width:8),
              _Stat(label:'Dernière img', value:info['derniere']!),
            ]),
            const SizedBox(height:11),
            SizedBox(width:double.infinity, child: ElevatedButton.icon(
              onPressed: () => _dialogPrise(context),
              icon: const Icon(Icons.camera_alt_outlined, size:15),
              label: const Text('Prendre une image maintenant'),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.green600, foregroundColor: AppColors.white,
                padding: const EdgeInsets.symmetric(vertical:11),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(11)),
                textStyle: const TextStyle(fontSize:13, fontWeight:FontWeight.w500),
              ),
            )),
          ])),

          const SizedBox(height:16),

          // Filtres + titre
          Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
            const SectionLabel('Dernières captures'),
            GestureDetector(
              onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const HistoriqueImagesScreen())),
              child: const Text('Voir tout', style: TextStyle(fontSize:12, color:AppColors.green700)),
            ),
          ]),
          const SizedBox(height:8),
          SizedBox(height:32, child: ListView.separated(
            scrollDirection: Axis.horizontal,
            itemCount: _filtres.length,
            separatorBuilder: (_,__) => const SizedBox(width:7),
            itemBuilder: (_,i) {
              final f = _filtres[i];
              final sel = _filtre == f;
              return GestureDetector(
                onTap: () => setState(() => _filtre = f),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds:150),
                  padding: const EdgeInsets.symmetric(horizontal:13, vertical:6),
                  decoration: BoxDecoration(
                    color: sel ? AppColors.green100 : AppColors.white,
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: sel?AppColors.green600:AppColors.border, width:sel?1.5:0.5),
                  ),
                  child: Text(f, style: TextStyle(fontSize:11, fontWeight:sel?FontWeight.w500:FontWeight.normal, color:sel?AppColors.green700:AppColors.textMuted)),
                ),
              );
            },
          )),

          const SizedBox(height:12),

          // Grille images
          GridView.builder(
            shrinkWrap:true, physics:const NeverScrollableScrollPhysics(),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(crossAxisCount:2, crossAxisSpacing:9, mainAxisSpacing:9, childAspectRatio:0.95),
            itemCount: _imgsFiltrees.length,
            itemBuilder: (ctx,i) {
              final img = _imgsFiltrees[i];
              return GestureDetector(
                onTap: () => Navigator.push(ctx, MaterialPageRoute(builder:(_) => DetailImageScreen(image:img))),
                child: ImageCard(image:img),
              );
            },
          ),

          const SizedBox(height:16),

          // Reco IA
          Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
            const SectionLabel('Recommandations IA'),
            GestureDetector(
              onTap: () => Navigator.push(context, MaterialPageRoute(builder:(_) => const AnalyseIaScreen())),
              child: const Text('Voir tout', style: TextStyle(fontSize:12, color:AppColors.green700)),
            ),
          ]),
          const SizedBox(height:8),

          RecoCard(icon:Icons.warning_amber_rounded, iconBg:AppColors.red100, iconColor:AppColors.red600,
            titre:'Jaunissement — Zone B',
            description:'Jaunissement partiel détecté. Vérifier l\'apport en azote et l\'état racinaire.',
            depuis:'Il y a 2h', confiance:84, priorite:'Élevée', prioriteBg:AppColors.red100, prioriteColor:AppColors.red800,
            onTap: () => Navigator.push(context, MaterialPageRoute(builder:(_) => const AnalyseIaScreen())),
          ),
          const SizedBox(height:8),
          RecoCard(icon:Icons.opacity, iconBg:AppColors.amber100, iconColor:AppColors.amber600,
            titre:'Sécheresse foliaire — Zone B',
            description:'Feuilles desséchées sur C4. Envisager irrigation ciblée sous 24h.',
            depuis:'Il y a 5h', confiance:79, priorite:'Moyenne', prioriteBg:AppColors.amber100, prioriteColor:AppColors.amber800,
            onTap: () => Navigator.push(context, MaterialPageRoute(builder:(_) => const AnalyseIaScreen())),
          ),
          const SizedBox(height:8),
          RecoCard(icon:Icons.shield_outlined, iconBg:AppColors.green100, iconColor:AppColors.green700,
            titre:'Zone A en bonne santé',
            description:'Végétation dense et uniforme. Croissance conforme au stade actuel.',
            depuis:'Il y a 2h', confiance:92, priorite:'OK', prioriteBg:AppColors.green100, prioriteColor:AppColors.green700,
            onTap: () {},
          ),
          const SizedBox(height:8),
        ]),
      ),
    );
  }

  void _dialogPrise(BuildContext context) {
    showDialog(context:context, builder:(_) => AlertDialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      title: Text('Prise d\'image — $_capteurSel', style: const TextStyle(fontSize:15, fontWeight:FontWeight.w500, color:AppColors.text)),
      content: Column(mainAxisSize:MainAxisSize.min, children:[
        Container(width:60,height:60,decoration:BoxDecoration(color:AppColors.green100,shape:BoxShape.circle),
          child:const Icon(Icons.camera_alt, color:AppColors.green700, size:28)),
        const SizedBox(height:12),
        Text('Déclencher la caméra du capteur $_capteurSel (${infoCapteurs[_capteurSel]!['zone']}) ?',
          textAlign:TextAlign.center, style:const TextStyle(fontSize:13, color:AppColors.textMuted)),
      ]),
      actions:[
        TextButton(onPressed:()=>Navigator.pop(context), child:const Text('Annuler',style:TextStyle(color:AppColors.textMuted))),
        ElevatedButton.icon(
          onPressed:(){
            Navigator.pop(context);
            ScaffoldMessenger.of(context).showSnackBar(SnackBar(
              content:Text('Image déclenchée sur $_capteurSel !'),
              backgroundColor:AppColors.green700, behavior:SnackBarBehavior.floating,
              shape:RoundedRectangleBorder(borderRadius:BorderRadius.circular(10)),
            ));
          },
          icon:const Icon(Icons.camera_alt,size:15), label:const Text('Déclencher'),
          style:ElevatedButton.styleFrom(backgroundColor:AppColors.green600,foregroundColor:AppColors.white,
            shape:RoundedRectangleBorder(borderRadius:BorderRadius.circular(8))),
        ),
      ],
    ));
  }
}

class _Stat extends StatelessWidget {
  final String label, value;
  const _Stat({required this.label, required this.value});
  @override
  Widget build(BuildContext context) => Expanded(child: Container(
    padding:const EdgeInsets.all(8),
    decoration:BoxDecoration(color:AppColors.bg, borderRadius:BorderRadius.circular(9)),
    child:Column(crossAxisAlignment:CrossAxisAlignment.start, children:[
      Text(label, style:const TextStyle(fontSize:10,color:AppColors.textMuted)),
      const SizedBox(height:2),
      Text(value, style:const TextStyle(fontSize:12,fontWeight:FontWeight.w500,color:AppColors.text)),
    ]),
  ));
}

/*import 'package:flutter/material.dart';
import '../../app_colors.dart';
import '../../widget.dart';

class ImagesScreen extends StatelessWidget {
  const ImagesScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.bg,
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: const [
            Text('Images & capteurs'),
            Text(
              'Analyse visuelle du champ',
              style: TextStyle(fontSize: 11, color: AppColors.textMuted),
            ),
          ],
        ),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 16),
            child: Container(
              width: 34,
              height: 34,
              decoration: BoxDecoration(
                color: AppColors.green100,
                borderRadius: BorderRadius.circular(9),
              ),
              child: const Icon(Icons.search,
                  color: AppColors.green700, size: 17),
            ),
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ── État du capteur sélectionné ───────────────────────────────
            AppCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: const [
                      Text(
                        'Capteur C1 — Zone A',
                        style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w500,
                            color: AppColors.text),
                      ),
                      StatusPill(
                        label: 'Actif',
                        bg: AppColors.green100,
                        textColor: AppColors.green700,
                      ),
                    ],
                  ),
                  const SizedBox(height: 11),
                  Row(
                    children: const [
                      _SensorStat(label: 'Batterie', value: '87%'),
                      SizedBox(width: 8),
                      _SensorStat(label: 'Signal', value: 'Fort'),
                      SizedBox(width: 8),
                      _SensorStat(label: 'Surface', value: '0.8 ha'),
                      SizedBox(width: 8),
                      _SensorStat(label: 'Dernière img', value: 'Il y a 2h'),
                    ],
                  ),
                  const SizedBox(height: 11),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      onPressed: () {},
                      icon: const Icon(Icons.camera_alt_outlined, size: 15),
                      label: const Text('Prendre une image maintenant'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.green600,
                        foregroundColor: AppColors.white,
                        padding:
                            const EdgeInsets.symmetric(vertical: 11),
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(11)),
                        textStyle: const TextStyle(
                            fontSize: 13, fontWeight: FontWeight.w500),
                      ),
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 14),
            const SectionLabel('Dernières captures'),

            // ── Grille d'images ───────────────────────────────────────────
            GridView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              gridDelegate:
                  const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                crossAxisSpacing: 9,
                mainAxisSpacing: 9,
                childAspectRatio: 1.1,
              ),
              itemCount: 4,
              itemBuilder: (context, i) {
                final isAlert = i == 1;
                final heures = ['Auj 08h12', 'Hier 16h45', 'Auj 06h00', 'Auj 04h30'];
                return Container(
                  decoration: BoxDecoration(
                    color: AppColors.green100,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Stack(
                    children: [
                      const Center(
                        child: Icon(Icons.grass,
                            color: AppColors.green600, size: 48),
                      ),
                      Positioned(
                        top: 7,
                        right: 7,
                        child: StatusPill(
                          label: isAlert ? 'Alerte' : 'Analysée',
                          bg: isAlert
                              ? AppColors.red100
                              : AppColors.green100,
                          textColor: isAlert
                              ? AppColors.red800
                              : AppColors.green700,
                        ),
                      ),
                      Positioned(
                        bottom: 7,
                        left: 7,
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 7, vertical: 2),
                          decoration: BoxDecoration(
                            color: Colors.black45,
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Text(
                            heures[i],
                            style: const TextStyle(
                                fontSize: 9, color: Colors.white),
                          ),
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),

            const SizedBox(height: 14),
            const SectionLabel('Recommandation IA'),

            // ── Recommandation IA ─────────────────────────────────────────
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppColors.green100,
                borderRadius: BorderRadius.circular(13),
                border: Border.all(
                    color: const Color(0xFFB5D48A), width: 0.5),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    width: 32,
                    height: 32,
                    decoration: BoxDecoration(
                      color: AppColors.green200,
                      borderRadius: BorderRadius.circular(9),
                    ),
                    child: const Icon(Icons.shield_outlined,
                        color: AppColors.green800, size: 16),
                  ),
                  const SizedBox(width: 10),
                  const Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Changement détecté — Zone A',
                          style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w500,
                              color: AppColors.green800),
                        ),
                        SizedBox(height: 4),
                        Text(
                          'Jaunissement partiel détecté sur la capture d\'hier. Vérifier l\'apport en azote.',
                          style: TextStyle(
                              fontSize: 11,
                              color: AppColors.green700,
                              height: 1.5),
                        ),
                        SizedBox(height: 5),
                        Text(
                          'Générée il y a 2h · Confiance 84%',
                          style: TextStyle(
                              fontSize: 10, color: AppColors.green600),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ─── Widget statistique capteur ───────────────────────────────────────────────
class _SensorStat extends StatelessWidget {
  final String label, value;
  const _SensorStat({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: AppColors.bg,
          borderRadius: BorderRadius.circular(9),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(label,
                style: const TextStyle(
                    fontSize: 10, color: AppColors.textMuted)),
            const SizedBox(height: 2),
            Text(value,
                style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                    color: AppColors.text)),
          ],
        ),
      ),
    );
  }
}*/