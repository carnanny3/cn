/// Models for the owner logbook (records, fuel, reminders, costs, co-owners).
///
/// Dates the API stores as calendar dates arrive as UTC midnight
/// ("2026-09-01T00:00:00.000Z"). [parseDay] keeps them as that calendar day —
/// converting to local time would shift them a day back west of UTC.
library;

DateTime parseDay(String iso) {
  final d = DateTime.parse(iso).toUtc();
  return DateTime(d.year, d.month, d.day);
}

DateTime? parseDayOrNull(Object? iso) => iso is String ? parseDay(iso) : null;

/// The YYYY-MM-DD form the API expects for date fields.
String formatApiDay(DateTime d) =>
    '${d.year.toString().padLeft(4, '0')}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';

double _toDouble(Object? v) => v is num ? v.toDouble() : 0;
double? _toDoubleOrNull(Object? v) => v is num ? v.toDouble() : null;

class RecordPhoto {
  RecordPhoto({required this.id, required this.viewUrl});

  final String id;
  final String viewUrl;

  factory RecordPhoto.fromJson(Map<String, dynamic> json) =>
      RecordPhoto(id: json['id'] as String, viewUrl: json['viewUrl'] as String);
}

class LogRecord {
  LogRecord({
    required this.id,
    required this.source,
    required this.type,
    required this.date,
    required this.title,
    required this.cost,
    this.odometerKm,
    this.notes,
    this.partnerName,
    this.photos = const [],
  });

  final String id;

  /// 'logbook' (the owner's own entry) or 'booking' (a completed Car Nanny booking, read-only).
  final String source;
  final String type; // service | repair | upgrade | fee
  final DateTime date;
  final String title;
  final double cost;
  final int? odometerKm;
  final String? notes;
  final String? partnerName;
  final List<RecordPhoto> photos;

  bool get isBooking => source == 'booking';

  factory LogRecord.fromJson(Map<String, dynamic> json) => LogRecord(
        id: json['id'] as String,
        source: json['source'] as String? ?? 'logbook',
        type: json['type'] as String,
        date: parseDay(json['date'] as String),
        title: json['title'] as String? ?? '',
        cost: _toDouble(json['cost']),
        odometerKm: json['odometerKm'] as int?,
        notes: json['notes'] as String?,
        partnerName: json['partnerName'] as String?,
        photos: ((json['photos'] as List?) ?? const [])
            .map((p) => RecordPhoto.fromJson(p as Map<String, dynamic>))
            .toList(),
      );
}

class FuelEntry {
  FuelEntry({
    required this.id,
    required this.date,
    required this.odometerKm,
    required this.liters,
    required this.cost,
    required this.fullTank,
    required this.missedPrevious,
    this.notes,
    this.distanceKm,
    this.kmPerLiter,
    this.litersPer100Km,
    this.pricePerLiter,
  });

  final String id;
  final DateTime date;
  final int odometerKm;
  final double liters;
  final double cost;
  final bool fullTank;
  final bool missedPrevious;
  final String? notes;
  final int? distanceKm;
  final double? kmPerLiter;
  final double? litersPer100Km;
  final double? pricePerLiter;

  factory FuelEntry.fromJson(Map<String, dynamic> json) => FuelEntry(
        id: json['id'] as String,
        date: parseDay(json['date'] as String),
        odometerKm: json['odometerKm'] as int,
        liters: _toDouble(json['liters']),
        cost: _toDouble(json['cost']),
        fullTank: json['fullTank'] as bool? ?? true,
        missedPrevious: json['missedPrevious'] as bool? ?? false,
        notes: json['notes'] as String?,
        distanceKm: json['distanceKm'] as int?,
        kmPerLiter: _toDoubleOrNull(json['kmPerLiter']),
        litersPer100Km: _toDoubleOrNull(json['litersPer100Km']),
        pricePerLiter: _toDoubleOrNull(json['pricePerLiter']),
      );
}

class FuelLog {
  FuelLog({
    required this.entries,
    required this.totalLiters,
    required this.totalCost,
    this.averageKmPerLiter,
    this.averageLitersPer100Km,
  });

  final List<FuelEntry> entries;
  final double totalLiters;
  final double totalCost;
  final double? averageKmPerLiter;
  final double? averageLitersPer100Km;

  factory FuelLog.fromJson(Map<String, dynamic> json) => FuelLog(
        entries: (json['entries'] as List).map((e) => FuelEntry.fromJson(e as Map<String, dynamic>)).toList(),
        totalLiters: _toDouble(json['totalLiters']),
        totalCost: _toDouble(json['totalCost']),
        averageKmPerLiter: _toDoubleOrNull(json['averageKmPerLiter']),
        averageLitersPer100Km: _toDoubleOrNull(json['averageLitersPer100Km']),
      );
}

class Reminder {
  Reminder({
    required this.id,
    required this.title,
    required this.urgency,
    this.dueDate,
    this.dueOdometerKm,
    this.repeatMonths,
    this.repeatKm,
    this.notes,
    this.daysLeft,
    this.kmLeft,
    this.vehicleId,
    this.vehicleLabel,
  });

  final String id;
  final String title;

  /// overdue | due_soon | upcoming | later | done
  final String urgency;
  final DateTime? dueDate;
  final int? dueOdometerKm;
  final int? repeatMonths;
  final int? repeatKm;
  final String? notes;
  final int? daysLeft;
  final int? kmLeft;

  /// Set only on items from the cross-vehicle attention list.
  final String? vehicleId;
  final String? vehicleLabel;

  bool get isDone => urgency == 'done';

  factory Reminder.fromJson(Map<String, dynamic> json) {
    final vehicle = json['vehicle'] as Map<String, dynamic>?;
    return Reminder(
      id: json['id'] as String,
      title: json['title'] as String,
      urgency: json['urgency'] as String? ?? 'later',
      dueDate: parseDayOrNull(json['dueDate']),
      dueOdometerKm: json['dueOdometerKm'] as int?,
      repeatMonths: json['repeatMonths'] as int?,
      repeatKm: json['repeatKm'] as int?,
      notes: json['notes'] as String?,
      daysLeft: json['daysLeft'] as int?,
      kmLeft: json['kmLeft'] as int?,
      vehicleId: vehicle?['id'] as String? ?? json['vehicleId'] as String?,
      vehicleLabel: vehicle == null ? null : '${vehicle['year']} ${vehicle['make']} ${vehicle['model']}',
    );
  }
}

/// Category keys in their fixed display order. The order is also the chart's
/// colour order, so a category keeps its colour on every screen.
const costCategories = ['service', 'repair', 'upgrade', 'fee', 'fuel', 'car_nanny'];

class MonthlyCosts {
  MonthlyCosts({required this.month, required this.byCategory});

  /// YYYY-MM
  final String month;
  final Map<String, double> byCategory;

  double get total => byCategory.values.fold(0, (a, b) => a + b);

  factory MonthlyCosts.fromJson(Map<String, dynamic> json) => MonthlyCosts(
        month: json['month'] as String,
        byCategory: {for (final c in costCategories) c: _toDouble(json[c])},
      );
}

class LogbookSummary {
  LogbookSummary({
    required this.total,
    required this.totals,
    required this.monthly,
    required this.currentOdometerKm,
    required this.distanceTrackedKm,
    required this.fillUps,
    required this.totalLiters,
    this.costPerKm,
    this.averageKmPerLiter,
    this.averageLitersPer100Km,
  });

  final double total;
  final Map<String, double> totals;
  final List<MonthlyCosts> monthly;
  final int currentOdometerKm;
  final int distanceTrackedKm;
  final int fillUps;
  final double totalLiters;
  final double? costPerKm;
  final double? averageKmPerLiter;
  final double? averageLitersPer100Km;

  factory LogbookSummary.fromJson(Map<String, dynamic> json) {
    final totals = json['totals'] as Map<String, dynamic>;
    final fuel = json['fuel'] as Map<String, dynamic>;
    return LogbookSummary(
      total: _toDouble(json['total']),
      totals: {for (final c in costCategories) c: _toDouble(totals[c])},
      monthly: (json['monthly'] as List).map((m) => MonthlyCosts.fromJson(m as Map<String, dynamic>)).toList(),
      currentOdometerKm: (json['currentOdometerKm'] as num).toInt(),
      distanceTrackedKm: (json['distanceTrackedKm'] as num).toInt(),
      costPerKm: _toDoubleOrNull(json['costPerKm']),
      fillUps: (fuel['fillUps'] as num).toInt(),
      totalLiters: _toDouble(fuel['totalLiters']),
      averageKmPerLiter: _toDoubleOrNull(fuel['averageKmPerLiter']),
      averageLitersPer100Km: _toDoubleOrNull(fuel['averageLitersPer100Km']),
    );
  }
}

class CoOwner {
  CoOwner({
    required this.userId,
    required this.fullName,
    required this.email,
    required this.isPrimary,
    required this.isYou,
  });

  final String userId;
  final String fullName;
  final String email;
  final bool isPrimary;
  final bool isYou;

  factory CoOwner.fromJson(Map<String, dynamic> json) => CoOwner(
        userId: json['userId'] as String,
        fullName: json['fullName'] as String,
        email: json['email'] as String,
        isPrimary: json['isPrimary'] as bool,
        isYou: json['isYou'] as bool? ?? false,
      );
}
