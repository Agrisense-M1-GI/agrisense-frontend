// lib/models/image.dart
class ImageApi {
  final String id;
  final String noeudCapteurId;
  final String code;
  final int longueur;
  final int largeur;
  final String cheminStockage;
  final int tailleOctets;
  final String format;
  final DateTime dateCapture;
  final bool estTraitee;
  final DateTime createdAt;

  const ImageApi({
    required this.id,
    required this.noeudCapteurId,
    required this.code,
    required this.longueur,
    required this.largeur,
    required this.cheminStockage,
    required this.tailleOctets,
    required this.format,
    required this.dateCapture,
    required this.estTraitee,
    required this.createdAt,
  });

  factory ImageApi.fromJson(Map<String, dynamic> json) => ImageApi(
    id:             json['id']               as String,
    noeudCapteurId: json['noeud_capteur_id'] as String,
    code:           json['code']             as String,
    longueur:       json['longueur']         as int,
    largeur:        json['largeur']          as int,
    cheminStockage: json['chemin_stockage']  as String,
    tailleOctets:   json['taille_octets']    as int,
    format:         json['format']           as String,
    dateCapture:    DateTime.parse(json['date_capture'] as String),
    estTraitee:     json['est_traitee']      as bool,
    createdAt:      DateTime.parse(json['created_at']   as String),
  );

  // Convertit en CaptureImage pour le frontend
  CaptureImage toCaptureImage({String nomCapteur = '', String zone = ''}) {
    final heure = '${dateCapture.hour.toString().padLeft(2, '0')}h'
                  '${dateCapture.minute.toString().padLeft(2, '0')}';

    // chemin_stockage : URL complète ou chemin local
    // Si chemin local → à préfixer avec l'URL du serveur de fichiers quand disponible
    final imageUrl = cheminStockage.startsWith('http')
        ? cheminStockage
        : cheminStockage;

    return CaptureImage(
      id:           id,
      capteurId:    noeudCapteurId,
      capteurNom:   nomCapteur.isNotEmpty ? nomCapteur : noeudCapteurId.substring(0, 8),
      zone:         zone,
      heure:        heure,
      date:         _formatDate(dateCapture),
      // est_traitee=false → en attente IA | est_traitee=true → analysée
      statut:       estTraitee ? 'analysee' : 'normale',
      imageUrl:     imageUrl,
      // anomalie et confiance seront remplis quand le backend IA sera prêt
      anomalie:     null,
      recommandation: null,
      confiance:    0,
      apiId:        id,
    );
  }

  static String _formatDate(DateTime dt) {
    final now   = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final yest  = today.subtract(const Duration(days: 1));
    final day   = DateTime(dt.year, dt.month, dt.day);
    if (day == today) return "Aujourd'hui";
    if (day == yest)  return 'Hier';
    final diff = today.difference(day).inDays;
    if (diff <= 6) {
      const jours = ['Lundi','Mardi','Mercredi','Jeudi','Vendredi','Samedi','Dimanche'];
      return jours[dt.weekday - 1];
    }
    return '${dt.day.toString().padLeft(2,'0')}/${dt.month.toString().padLeft(2,'0')}/${dt.year}';
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// CaptureImage — modèle UI utilisé dans toutes les pages
// ─────────────────────────────────────────────────────────────────────────────
class CaptureImage {
  final String id;
  final String capteurId;
  final String capteurNom;
  final String zone;
  final String heure;
  final String date;
  final String statut;         // 'normale' | 'alerte' | 'analysee' | 'en_attente'
  final String imageUrl;
  final String? anomalie;
  final String? recommandation;
  final int confiance;
  final String? apiId;         // UUID backend

  const CaptureImage({
    required this.id,
    required this.capteurId,
    required this.capteurNom,
    required this.zone,
    required this.heure,
    required this.date,
    required this.statut,
    required this.imageUrl,
    this.anomalie,
    this.recommandation,
    this.confiance = 0,
    this.apiId,
  });
}

// ─────────────────────────────────────────────────────────────────────────────
// Données mock — fallback si backend inaccessible
// ─────────────────────────────────────────────────────────────────────────────
const List<CaptureImage> mockImages = [
  CaptureImage(
    id: 'IMG001', capteurId: 'mock-c1', capteurNom: 'Capteur Demo 1', zone: 'Zone A',
    heure: '08h12', date: "Aujourd'hui", statut: 'analysee',
    imageUrl: 'https://www.kaack-terminhandel.de/assets/images/d/Fotolia_188414913_Subscription_Monthly_M-dc3f2f17.jpg',
    confiance: 92,
  ),
  CaptureImage(
    id: 'IMG002', capteurId: 'mock-c1', capteurNom: 'Capteur Demo 1', zone: 'Zone A',
    heure: '16h45', date: 'Hier', statut: 'alerte',
    imageUrl: 'https://static.farmtario.com/wp-content/uploads/2022/03/31182013/db_corn_MB_2021-768x512.jpeg',
    anomalie: 'Jaunissement partiel détecté sur 20-30% de la surface',
    recommandation: 'Vérifier l\'apport en azote. Irrigation ciblée recommandée sous 24h.',
    confiance: 84,
  ),
  CaptureImage(
    id: 'IMG003', capteurId: 'mock-c2', capteurNom: 'Capteur Demo 2', zone: 'Zone B',
    heure: '06h00', date: "Aujourd'hui", statut: 'normale',
    imageUrl: 'https://live.staticflickr.com/65535/54237409785_c10a93996b_b.jpg',
    confiance: 0,
  ),
  CaptureImage(
    id: 'IMG004', capteurId: 'mock-c2', capteurNom: 'Capteur Demo 2', zone: 'Zone B',
    heure: '14h20', date: 'Hier', statut: 'alerte',
    imageUrl: 'https://cdn2.regie-agricole.com/ulf/CMS_Content/1/articles/171138/fiches_Mais_fourrage_24396-1000x562.JPG',
    anomalie: 'Sécheresse foliaire sévère',
    recommandation: 'Lancer une irrigation immédiate. Réduire l\'exposition solaire si possible.',
    confiance: 79,
  ),
];