import 'package:flutter/material.dart';
import '../../app_colors.dart';

// ─── Modèle image ──────────────────────────────────────────────────────────────
class CaptureImage {
  final String id;
  final String capteurId;
  final String zone;
  final String heure;
  final String date;
  final String statut; // 'normale' | 'alerte' | 'analysee'
  final String imageUrl;
  final String? anomalie;
  final int confiance;

  const CaptureImage({
    required this.id,
    required this.capteurId,
    required this.zone,
    required this.heure,
    required this.date,
    required this.statut,
    required this.imageUrl,
    this.anomalie,
    this.confiance = 0,
  });
}

// ─── Données mock images ───────────────────────────────────────────────────────
const List<CaptureImage> mockImages = [
  CaptureImage(
    id: 'IMG001', capteurId: 'C1', zone: 'Zone A',
    heure: '08h12', date: "Aujourd'hui", statut: 'analysee',
    imageUrl: 'https://www.kaack-terminhandel.de/assets/images/d/Fotolia_188414913_Subscription_Monthly_M-dc3f2f17.jpg',
    confiance: 92,
  ),
  CaptureImage(
    id: 'IMG002', capteurId: 'C3', zone: 'Zone B',
    heure: '16h45', date: 'Hier', statut: 'alerte',
    imageUrl: 'https://static.farmtario.com/wp-content/uploads/2022/03/31182013/db_corn_MB_2021-768x512.jpeg',
    anomalie: 'Jaunissement partiel détecté',
    confiance: 84,
  ),
  CaptureImage(
    id: 'IMG003', capteurId: 'C5', zone: 'Zone C',
    heure: '06h00', date: "Aujourd'hui", statut: 'normale',
    imageUrl: 'https://live.staticflickr.com/65535/54237409785_c10a93996b_b.jpg',
    confiance: 0,
  ),
  CaptureImage(
    id: 'IMG004', capteurId: 'C2', zone: 'Zone A',
    heure: '04h30', date: "Aujourd'hui", statut: 'analysee',
    imageUrl: 'https://www.shutterstock.com/image-photo/field-young-corn-low-angle-600nw-198003116.jpg',
    confiance: 88,
  ),
  CaptureImage(
    id: 'IMG005', capteurId: 'C6', zone: 'Zone C',
    heure: '10h00', date: 'Hier', statut: 'normale',
    imageUrl: 'https://images.unsplash.com/photo-1625246333195-78d9c38ad449?w=600&q=80',
    confiance: 0,
  ),
  CaptureImage(
    id: 'IMG006', capteurId: 'C4', zone: 'Zone B',
    heure: '14h20', date: 'Hier', statut: 'alerte',
    imageUrl: 'https://cdn2.regie-agricole.com/ulf/CMS_Content/1/articles/171138/fiches_Mais_fourrage_24396-1000x562.JPG',
    anomalie: 'Sécheresse foliaire détectée',
    confiance: 79,
  ),
  CaptureImage(
    id: 'IMG007', capteurId: 'C1', zone: 'Zone A',
    heure: '22h00', date: 'Lundi', statut: 'analysee',
    imageUrl: 'https://thumbs.dreamstime.com/b/sweet-corn-fertile-soil-field-subsistence-farming-green-sprouts-against-blue-sky-new-crop-380230708.jpg',
    confiance: 91,
  ),
  CaptureImage(
    id: 'IMG008', capteurId: 'C5', zone: 'Zone C',
    heure: '06h15', date: 'Lundi', statut: 'normale',
    imageUrl: 'https://www.shutterstock.com/shutterstock/videos/1031032592/thumb/1.jpg?ip=x480',
    confiance: 0,
  ),
];

// ─── Infos capteurs ────────────────────────────────────────────────────────────
const Map<String, Map<String, String>> infoCapteurs = {
  'C1': {'zone':'Zone A','batterie':'87%','signal':'Fort', 'surface':'0.8 ha','statut':'actif',   'derniere':'Il y a 2h'},
  'C2': {'zone':'Zone A','batterie':'72%','signal':'Fort', 'surface':'0.7 ha','statut':'actif',   'derniere':'Il y a 4h'},
  'C3': {'zone':'Zone B','batterie':'18%','signal':'Moyen','surface':'1.1 ha','statut':'alerte',  'derniere':'Il y a 1h'},
  'C4': {'zone':'Zone B','batterie':'55%','signal':'Fort', 'surface':'0.9 ha','statut':'actif',   'derniere':'Il y a 3h'},
  'C5': {'zone':'Zone C','batterie':'91%','signal':'Fort', 'surface':'1.2 ha','statut':'actif',   'derniere':'Il y a 2h'},
  'C6': {'zone':'Zone C','batterie':'63%','signal':'Fort', 'surface':'0.8 ha','statut':'actif',   'derniere':'Il y a 5h'},
  'C7': {'zone':'Zone D','batterie':'22%','signal':'Faible','surface':'0.9 ha','statut':'batterie','derniere':'Il y a 6h'},
  'C8': {'zone':'Zone D','batterie':'0%', 'signal':'Aucun','surface':'0.5 ha','statut':'inactif', 'derniere':'Il y a 2j'},
};

// ─── Helpers statut ────────────────────────────────────────────────────────────
Color statutColor(String s) {
  switch (s) {
    case 'actif':    return AppColors.green600;
    case 'alerte':   return AppColors.red600;
    case 'batterie': return AppColors.amber600;
    default:         return const Color(0xFFB4B2A9);
  }
}

Color statutBg(String s) {
  switch (s) {
    case 'actif':    return AppColors.green100;
    case 'alerte':   return AppColors.red100;
    case 'batterie': return AppColors.amber100;
    default:         return AppColors.gray50;
  }
}

String statutLabel(String s) {
  switch (s) {
    case 'actif':    return 'Actif';
    case 'alerte':   return 'Alerte';
    case 'batterie': return 'Batterie';
    default:         return 'Inactif';
  }
}

// ─── Widget ImageCard (réutilisé partout) ──────────────────────────────────────
class ImageCard extends StatelessWidget {
  final CaptureImage image;
  const ImageCard({super.key, required this.image});

  Color get _badgeBg => image.statut == 'alerte'
      ? AppColors.red100
      : image.statut == 'analysee'
          ? AppColors.green100
          : const Color(0xFFF5F7F2);

  Color get _badgeColor => image.statut == 'alerte'
      ? AppColors.red800
      : image.statut == 'analysee'
          ? AppColors.green700
          : AppColors.textMuted;

  String get _badgeLabel => image.statut == 'alerte'
      ? 'Alerte'
      : image.statut == 'analysee'
          ? 'Analysée'
          : 'Normale';

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(12),
      child: Stack(fit: StackFit.expand, children: [
        Image.network(
          image.imageUrl, fit: BoxFit.cover,
          loadingBuilder: (_, child, p) => p == null
              ? child
              : Container(color: AppColors.green100,
                  child: const Center(child: CircularProgressIndicator(
                      color: AppColors.green600, strokeWidth: 2))),
          errorBuilder: (_, __, ___) => Container(
              color: AppColors.green100,
              child: const Center(child: Icon(Icons.grass,
                  color: AppColors.green600, size: 40))),
        ),
        // Gradient bas
        Positioned(bottom:0,left:0,right:0, child: Container(height:60,
          decoration: BoxDecoration(gradient: LinearGradient(
            colors:[Colors.transparent, Colors.black.withOpacity(0.65)],
            begin: Alignment.topCenter, end: Alignment.bottomCenter,
          )),
        )),
        // Badge statut
        Positioned(top:7,right:7, child: _Pill(label:_badgeLabel, bg:_badgeBg, color:_badgeColor)),
        // Icone alerte
        if (image.statut == 'alerte')
          const Positioned(top:7,left:7,
              child: Icon(Icons.warning_amber_rounded, color:AppColors.red600, size:18)),
        // Infos
        Positioned(bottom:7,left:8,right:8, child: Column(
          crossAxisAlignment: CrossAxisAlignment.start, children:[
            Text('${image.capteurId} · ${image.zone}',
                style: const TextStyle(color:Colors.white, fontSize:10, fontWeight:FontWeight.w500)),
            Text('${image.date} ${image.heure}',
                style: const TextStyle(color:Colors.white70, fontSize:9)),
          ],
        )),
      ]),
    );
  }
}

// ─── Widget RecoCard (réutilisé) ───────────────────────────────────────────────
class RecoCard extends StatelessWidget {
  final IconData icon;
  final Color iconBg, iconColor;
  final String titre, description, depuis, priorite;
  final Color prioriteBg, prioriteColor;
  final int confiance;
  final VoidCallback onTap;

  const RecoCard({
    super.key,
    required this.icon, required this.iconBg, required this.iconColor,
    required this.titre, required this.description, required this.depuis,
    required this.confiance, required this.priorite,
    required this.prioriteBg, required this.prioriteColor,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(13),
        decoration: BoxDecoration(
          color: iconBg.withOpacity(0.35),
          borderRadius: BorderRadius.circular(13),
          border: Border.all(color: iconColor.withOpacity(0.2), width: 0.5),
        ),
        child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Container(width:34,height:34,
            decoration:BoxDecoration(color:iconBg, borderRadius:BorderRadius.circular(9)),
            child:Icon(icon,color:iconColor,size:17)),
          const SizedBox(width:10),
          Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children:[
            Row(mainAxisAlignment:MainAxisAlignment.spaceBetween, children:[
              Expanded(child: Text(titre, style:const TextStyle(fontSize:12,fontWeight:FontWeight.w500,color:AppColors.text))),
              _Pill(label:priorite, bg:prioriteBg, color:prioriteColor),
            ]),
            const SizedBox(height:4),
            Text(description, style:const TextStyle(fontSize:11,color:AppColors.textMuted,height:1.45)),
            const SizedBox(height:6),
            Row(children:[
              const Icon(Icons.access_time, size:11, color:AppColors.textMuted),
              const SizedBox(width:3),
              Text(depuis, style:const TextStyle(fontSize:10,color:AppColors.textMuted)),
              if (confiance > 0) ...[
                const SizedBox(width:10),
                const Icon(Icons.psychology_outlined, size:11, color:AppColors.textMuted),
                const SizedBox(width:3),
                Text('Confiance $confiance%', style:const TextStyle(fontSize:10,color:AppColors.textMuted)),
              ],
            ]),
          ])),
          const SizedBox(width:6),
          const Icon(Icons.chevron_right, color:AppColors.textMuted, size:16),
        ]),
      ),
    );
  }
}

// ─── Mini pill interne ─────────────────────────────────────────────────────────
class _Pill extends StatelessWidget {
  final String label; final Color bg, color;
  const _Pill({required this.label, required this.bg, required this.color});
  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(horizontal:8, vertical:3),
    decoration: BoxDecoration(color:bg, borderRadius:BorderRadius.circular(20)),
    child: Text(label, style:TextStyle(fontSize:10,fontWeight:FontWeight.w500,color:color)),
  );
}