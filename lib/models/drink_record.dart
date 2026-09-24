import 'cocktail.dart';

enum DrinkingScene { home, out }

enum DrinkVerdict { loved, liked, notForMe }

/// A tasting event owns its recipe snapshot: editing a public recipe must not
/// rewrite what someone actually made or tasted in the past.
class DrinkRecord {
  const DrinkRecord({
    required this.id,
    required this.name,
    required this.occurredAt,
    required this.scene,
    required this.verdict,
    this.note = '',
    this.venue = '',
    this.price = '',
    this.adjustments = '',
    this.photoBase64,
    this.photosBase64 = const [],
    this.reference,
    this.actualRecipe = const [],
    this.version,
    this.createdAt,
    this.expiresAt,
    this.sharingStatus = 'private',
    this.sharingReason,
  });

  final String id;
  final int? version;
  final DateTime? createdAt, expiresAt;
  final String sharingStatus;
  final String? sharingReason;
  bool get isExpired =>
      expiresAt != null && !expiresAt!.isAfter(DateTime.now());
  final String name;
  final DateTime occurredAt;
  final DrinkingScene scene;
  final DrinkVerdict verdict;
  final String note;
  final String venue;

  /// Free text intentionally preserves currency, e.g. HK$120.
  final String price;
  final String adjustments;
  final String? photoBase64;
  final List<String> photosBase64;
  List<String> get photos => photosBase64.isNotEmpty
      ? photosBase64
      : [if (photoBase64 != null) photoBase64!];
  final Cocktail? reference;
  final List<RecipeItem> actualRecipe;

  bool matches(String query) => [
        name,
        venue,
        note,
        adjustments,
        reference?.en ?? '',
        reference?.zh ?? ''
      ].join(' ').toLowerCase().contains(query.trim().toLowerCase());

  Cocktail recipeDraft() => Cocktail(
        id: 'record-draft-$id',
        zh: name,
        en: '',
        spirit: reference?.spirit,
        base: reference?.base ?? '',
        abv: reference?.abv ?? 20,
        color: reference?.color ?? '#C99072',
        tags: const [],
        glass: reference?.glass ?? '',
        garnish: '',
        flavor: '',
        story: note,
        recipe: actualRecipe,
        steps: reference?.steps ?? const [],
        isPrivate: true,
        status: CocktailStatus.draft,
      );

  Map<String, dynamic> toJson() => {
        'id': id,
        if (version != null) 'version': version,
        'name': name,
        'occurredAt': occurredAt.toIso8601String(),
        'scene': scene.name,
        'verdict': verdict.name,
        'note': note,
        'venue': venue,
        'price': price,
        'adjustments': adjustments,
        'photoBase64': photosBase64.isEmpty ? photoBase64 : null,
        if (photosBase64.isNotEmpty) 'photosBase64': photosBase64,
        'reference': reference?.toJson(),
        'actualRecipe': actualRecipe.map((item) => item.toJson()).toList(),
      };

  factory DrinkRecord.fromJson(Map<String, dynamic> json) => DrinkRecord(
        id: json['id'] as String,
        version: (json['version'] as num?)?.toInt(),
        createdAt: DateTime.tryParse(json['createdAt'] as String? ?? ''),
        expiresAt: DateTime.tryParse(json['expiresAt'] as String? ?? ''),
        sharingStatus: json['sharingStatus'] as String? ?? 'private',
        sharingReason: json['sharingReason'] as String?,
        name: json['name'] as String,
        occurredAt: DateTime.parse(json['occurredAt'] as String),
        scene: DrinkingScene.values.byName(json['scene'] as String),
        verdict: DrinkVerdict.values.byName(json['verdict'] as String),
        note: json['note'] as String? ?? '',
        venue: json['venue'] as String? ?? '',
        price: json['price'] as String? ?? '',
        adjustments: json['adjustments'] as String? ?? '',
        photoBase64: json['photoBase64'] as String?,
        photosBase64: (json['photosBase64'] as List? ?? []).cast<String>(),
        reference: json['reference'] == null
            ? null
            : Cocktail.fromJson(
                Map<String, dynamic>.from(json['reference'] as Map)),
        actualRecipe: (json['actualRecipe'] as List? ?? [])
            .map((item) =>
                RecipeItem.fromJson(Map<String, dynamic>.from(item as Map)))
            .toList(),
      );
}
