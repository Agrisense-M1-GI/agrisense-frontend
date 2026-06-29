// lib/models/image.dart
/*class ImageApi {
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
];*/
// ─────────────────────────────────────────────────────────────────────────────
// image_model.dart
// Modèle mappé sur GET /api/images/:capteur_id
// ─────────────────────────────────────────────────────────────────────────────
/*
/// Correspond à un enregistrement retourné par GET /api/images/:capteur_id
class CaptureImage {
  /// UUID de l'image en base
  final String id;

  /// UUID du capteur (noeud_capteur_id)
  final String capteurId;

  /// Nom affiché du capteur (chargé séparément depuis /capteurs)
  final String capteurNom;

  /// Chemin de stockage brut : "data/nodes/{node_id}/images/{fichier}.jpg"
  final String cheminStockage;

  /// Taille en octets
  final int tailleOctets;

  /// Format : "jpg", "png"…
  final String format;

  /// Date de capture ISO 8601 (nullable côté API)
  final DateTime? dateCapture;

  /// true si l'IA a déjà traité cette image
  final bool estTraitee;

  /// Résultat IA — null si pas encore analysée
  final ResultatIA? resultatIA;

  const CaptureImage({
    required this.id,
    required this.capteurId,
    required this.capteurNom,
    required this.cheminStockage,
    required this.tailleOctets,
    required this.format,
    this.dateCapture,
    required this.estTraitee,
    this.resultatIA,
  });

  // ── Helpers ────────────────────────────────────────────────────────────────

  /// Construit l'URL HTTP depuis baseUrl + cheminStockage.
  /// baseUrl = "http://192.168.1.42:8080"
  /// Ex: data/nodes/node_01/images/node_01_20260604.jpg
  ///  →  http://192.168.1.42:8080/fichiers/node_01/images/node_01_20260604.jpg
  String imageUrl(String baseUrl) {
    final relativePath = cheminStockage.replaceFirst('data/nodes/', '');
    return '$baseUrl/fichiers/$relativePath';
  }

  /// Dossier du nœud, utilisé comme dossier_images pour l'API IA
  /// Ex: data/nodes/node_01/images → on extrait "data/nodes/node_01"
  String get dossierImages {
    final parts = cheminStockage.split('/');
    // cheminStockage = data/nodes/{node_id}/images/{fichier}
    if (parts.length >= 3) {
      return parts.take(3).join('/'); // "data/nodes/{node_id}"
    }
    return cheminStockage;
  }

  String get dateFormatee {
    if (dateCapture == null) return '—';
    final d = dateCapture!;
    return '${d.day.toString().padLeft(2, '0')}/${d.month.toString().padLeft(2, '0')}/${d.year}';
  }

  String get heureFormatee {
    if (dateCapture == null) return '—';
    final d = dateCapture!;
    return '${d.hour.toString().padLeft(2, '0')}h${d.minute.toString().padLeft(2, '0')}';
  }

  /// Statut dérivé du résultat IA
  String get statut {
    if (!estTraitee) return 'en_attente';
    if (resultatIA == null) return 'normale';
    if (resultatIA!.statutGeneral.toLowerCase() == 'normal') return 'analysee';
    return 'alerte';
  }

  // ── Désérialisation depuis GET /api/images/:capteur_id ────────────────────
  factory CaptureImage.fromJson(
    Map<String, dynamic> json, {
    required String capteurNom,
    ResultatIA? resultatIA,
  }) {
    return CaptureImage(
      id:             json['id'] as String,
      capteurId:      json['noeud_capteur_id'] as String,
      capteurNom:     capteurNom,
      cheminStockage: json['chemin_stockage'] as String,
      tailleOctets:   json['taille_octets'] as int? ?? 0,
      format:         json['format'] as String? ?? 'jpg',
      dateCapture: json['date_capture'] != null
          ? DateTime.tryParse(json['date_capture'] as String)
          : null,
      estTraitee: json['est_traitee'] as bool? ?? false,
      resultatIA: resultatIA,
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// ResultatIA — résultat de POST /api/ia/analyser
// ─────────────────────────────────────────────────────────────────────────────
class ResultatIA {
  final String diagnosticTitre;
  final String statutGeneral;       // "Normal", "Moyen", "Critique"
  final String diagnosticSante;
  final List<String> actionsSuggerees;
  final bool analyseRequise;
  final String? fichierTraite;

  const ResultatIA({
    required this.diagnosticTitre,
    required this.statutGeneral,
    required this.diagnosticSante,
    required this.actionsSuggerees,
    required this.analyseRequise,
    this.fichierTraite,
  });

  factory ResultatIA.fromJson(Map<String, dynamic> json) {
    final iaOutput = json['ia_output'] as Map<String, dynamic>;
    return ResultatIA(
      diagnosticTitre:  iaOutput['diagnostic_titre'] as String? ?? '',
      statutGeneral:    iaOutput['statut_general'] as String? ?? 'Normal',
      diagnosticSante:  iaOutput['diagnostic_sante'] as String? ?? '',
      actionsSuggerees: List<String>.from(
          iaOutput['actions_suggerees'] as List? ?? []),
      analyseRequise: json['analyse_requise'] as bool? ?? false,
      fichierTraite:  json['fichier_traite'] as String?,
    );
  }

  bool get isAlerte =>
      statutGeneral.toLowerCase() != 'normal';
}

// ─────────────────────────────────────────────────────────────────────────────
// PredictionCulture — résultat de POST /api/ia/predire
// ─────────────────────────────────────────────────────────────────────────────
class PredictionCulture {
  final String culture;
  final String scoreCompatibilite;
  final String justification;

  const PredictionCulture({
    required this.culture,
    required this.scoreCompatibilite,
    required this.justification,
  });

  factory PredictionCulture.fromJson(Map<String, dynamic> json) =>
      PredictionCulture(
        culture:             json['culture'] as String,
        scoreCompatibilite:  json['score_compatibilite'] as String,
        justification:       json['justification'] as String,
      );
}

class ResultatPrediction {
  final String analyseSynthese;
  final List<PredictionCulture> recommandations;
  final String modeEvaluation;

  const ResultatPrediction({
    required this.analyseSynthese,
    required this.recommandations,
    required this.modeEvaluation,
  });

  factory ResultatPrediction.fromJson(Map<String, dynamic> json) {
    final output = json['predictions_output'] as Map<String, dynamic>;
    return ResultatPrediction(
      modeEvaluation: json['mode_evaluation'] as String? ?? '',
      analyseSynthese: output['analyse_environnementale_synthese'] as String? ?? '',
      recommandations: (output['recommandations'] as List? ?? [])
          .map((r) => PredictionCulture.fromJson(r as Map<String, dynamic>))
          .toList(),
    );
  }
}*/
// lib/models/image.dart
// ─────────────────────────────────────────────────────────────────────────────
// CaptureImage — modèle mappé sur GET /api/images/:capteur_id
// Compatible avec : images_page.dart, details_image_page.dart,
//                   historique_image_page.dart, analyse_ia_page.dart
// ─────────────────────────────────────────────────────────────────────────────

/// Correspond à un enregistrement retourné par GET /api/images/:capteur_id
class CaptureImage {
  // ── Champs API bruts ───────────────────────────────────────────────────────

  /// UUID de l'image en base
  final String id;

  /// UUID du capteur (noeud_capteur_id)
  final String capteurId;

  /// Nom affiché du capteur (chargé séparément depuis /capteurs)
  final String capteurNom;

  /// Chemin de stockage brut : "data/nodes/{node_id}/images/{fichier}.jpg"
  final String cheminStockage;

  /// URL HTTP complète construite par ImageService.buildImageUrl()
  /// Ex: "http://192.168.1.42:8080/fichiers/node_01/images/img.jpg"
  /// Renseigné au moment de la construction depuis le service.
  final String imageUrl;

  /// Taille en octets
  final int tailleOctets;

  /// Format : "jpg", "png"…
  final String format;

  /// Date de capture ISO 8601 (nullable côté API)
  final DateTime? dateCapture;

  /// true si l'IA a déjà traité cette image
  final bool estTraitee;

  /// Résultat IA — null si pas encore analysée
  final ResultatIA? resultatIA;

  /// Zone/emplacement affiché — dérivé du nom capteur si non fourni
  final String zone;

  const CaptureImage({
    required this.id,
    required this.capteurId,
    required this.capteurNom,
    required this.cheminStockage,
    required this.imageUrl,
    required this.tailleOctets,
    required this.format,
    this.dateCapture,
    required this.estTraitee,
    this.resultatIA,
    String? zone,
  }) : zone = zone ?? capteurNom;

  // ── Getters UI ─────────────────────────────────────────────────────────────

  /// Dossier du nœud, utilisé comme dossier_images pour l'API IA
  /// Ex: data/nodes/node_01/images/img.jpg → "data/nodes/node_01"
  String get dossierImages {
    final parts = cheminStockage.split('/');
    if (parts.length >= 3) return parts.take(3).join('/');
    return cheminStockage;
  }

  /// Date formatée — libellé relatif ou "dd/MM/yyyy"
  String get dateFormatee {
    if (dateCapture == null) return '—';
    return _formatDate(dateCapture!);
  }

  /// Alias court : image.date (utilisé dans les pages)
  String get date => dateFormatee;

  /// Heure formatée : "HHhMM"
  String get heureFormatee {
    if (dateCapture == null) return '—';
    final d = dateCapture!;
    return '${d.hour.toString().padLeft(2, '0')}h'
        '${d.minute.toString().padLeft(2, '0')}';
  }

  /// Alias court : image.heure (utilisé dans les pages)
  String get heure => heureFormatee;

  /// Statut dérivé de l'état IA
  /// 'en_attente' | 'analysee' | 'alerte' | 'normale'
  String get statut {
    if (!estTraitee) return 'en_attente';
    if (resultatIA == null) return 'normale';
    if (resultatIA!.isAlerte) return 'alerte';
    return 'analysee';
  }

  // ── Getters vers ResultatIA (évite les null-checks dans les pages) ─────────

  /// Titre / description de l'anomalie détectée (pour les pages d'alerte)
  String? get anomalie =>
      (resultatIA != null && resultatIA!.isAlerte)
          ? resultatIA!.diagnosticTitre
          : null;

  /// Première action suggérée (recommandation principale affichée dans les pages)
  String? get recommandation =>
      (resultatIA != null && resultatIA!.actionsSuggerees.isNotEmpty)
          ? resultatIA!.actionsSuggerees.first
          : null;

  /// Score de confiance IA — non fourni par l'API actuelle, toujours 0
  int get confiance => 0;

  /// Alias pour l'UUID backend (utilisé sous image.apiId dans les pages)
  String? get apiId => id;

  // ── Désérialisation depuis GET /api/images/:capteur_id ────────────────────
  /// [capteurNom]  : nom du capteur récupéré depuis /api/capteurs
  /// [baseUrl]     : ex "http://192.168.1.42:8080" — sert à construire imageUrl
  /// [zone]        : optionnel, sinon = capteurNom
  /// [resultatIA]  : résultat IA si déjà disponible
  factory CaptureImage.fromJson(
    Map<String, dynamic> json, {
    required String capteurNom,
    required String baseUrl,
    String? zone,
    ResultatIA? resultatIA,
  }) {
    final chemin = json['chemin_stockage'] as String;
    final relativePath = chemin.replaceFirst('data/nodes/', '');
    final imageUrl = '$baseUrl/fichiers/$relativePath';

    return CaptureImage(
      id:             json['id']              as String,
      capteurId:      json['noeud_capteur_id'] as String,
      capteurNom:     capteurNom,
      zone:           zone ?? capteurNom,
      cheminStockage: chemin,
      imageUrl:       imageUrl,
      tailleOctets:   json['taille_octets']  as int?  ?? 0,
      format:         json['format']          as String? ?? 'jpg',
      dateCapture: json['date_capture'] != null
          ? DateTime.tryParse(json['date_capture'] as String)
          : null,
      estTraitee: json['est_traitee'] as bool? ?? false,
      resultatIA: resultatIA,
    );
  }

  // ── Helpers privés ─────────────────────────────────────────────────────────
  static String _formatDate(DateTime dt) {
    final now   = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final yest  = today.subtract(const Duration(days: 1));
    final day   = DateTime(dt.year, dt.month, dt.day);
    if (day == today) return "Aujourd'hui";
    if (day == yest)  return 'Hier';
    final diff = today.difference(day).inDays;
    if (diff <= 6) {
      const jours = [
        'Lundi', 'Mardi', 'Mercredi', 'Jeudi',
        'Vendredi', 'Samedi', 'Dimanche',
      ];
      return jours[dt.weekday - 1];
    }
    return '${dt.day.toString().padLeft(2, '0')}/'
        '${dt.month.toString().padLeft(2, '0')}/${dt.year}';
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// ResultatIA — résultat de POST /api/ia/analyser
// ─────────────────────────────────────────────────────────────────────────────
class ResultatIA {
  final String       diagnosticTitre;
  final String       statutGeneral;      // "Normal" | "Moyen" | "Critique"
  final String       diagnosticSante;
  final List<String> actionsSuggerees;
  final bool         analyseRequise;
  final String?      fichierTraite;

  const ResultatIA({
    required this.diagnosticTitre,
    required this.statutGeneral,
    required this.diagnosticSante,
    required this.actionsSuggerees,
    required this.analyseRequise,
    this.fichierTraite,
  });

  bool get isAlerte => statutGeneral.toLowerCase() != 'normal';

  factory ResultatIA.fromJson(Map<String, dynamic> json) {
    final iaOutput = json['ia_output'] as Map<String, dynamic>;
    return ResultatIA(
      diagnosticTitre:  iaOutput['diagnostic_titre']  as String? ?? '',
      statutGeneral:    iaOutput['statut_general']     as String? ?? 'Normal',
      diagnosticSante:  iaOutput['diagnostic_sante']   as String? ?? '',
      actionsSuggerees: List<String>.from(
          iaOutput['actions_suggerees'] as List? ?? []),
      analyseRequise: json['analyse_requise'] as bool? ?? false,
      fichierTraite:  json['fichier_traite']  as String?,
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// PredictionCulture + ResultatPrediction — résultat de POST /api/ia/predire
// ─────────────────────────────────────────────────────────────────────────────
class PredictionCulture {
  final String culture;
  final String scoreCompatibilite;
  final String justification;

  const PredictionCulture({
    required this.culture,
    required this.scoreCompatibilite,
    required this.justification,
  });

  factory PredictionCulture.fromJson(Map<String, dynamic> json) =>
      PredictionCulture(
        culture:            json['culture']             as String,
        scoreCompatibilite: json['score_compatibilite'] as String,
        justification:      json['justification']       as String,
      );
}

class ResultatPrediction {
  final String                  analyseSynthese;
  final List<PredictionCulture> recommandations;
  final String                  modeEvaluation;

  const ResultatPrediction({
    required this.analyseSynthese,
    required this.recommandations,
    required this.modeEvaluation,
  });

  factory ResultatPrediction.fromJson(Map<String, dynamic> json) {
    final output = json['predictions_output'] as Map<String, dynamic>;
    return ResultatPrediction(
      modeEvaluation:  json['mode_evaluation']                     as String? ?? '',
      analyseSynthese: output['analyse_environnementale_synthese'] as String? ?? '',
      recommandations: (output['recommandations'] as List? ?? [])
          .map((r) => PredictionCulture.fromJson(r as Map<String, dynamic>))
          .toList(),
    );
  }
}