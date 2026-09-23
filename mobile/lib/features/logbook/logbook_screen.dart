import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:share_plus/share_plus.dart';
import '../../core/api/api_client.dart';
import '../../core/theme/app_colors.dart';
import '../../core/widgets/empty_state.dart';
import '../../core/widgets/glass_card.dart';
import '../../core/widgets/gradient_background.dart';
import '../../core/widgets/status_badge.dart';
import '../../l10n/generated/app_localizations.dart';
import 'cost_chart.dart';
import 'logbook_format.dart';
import 'logbook_forms.dart';
import 'logbook_models.dart';
import 'logbook_repository.dart';

const _tabKeys = ['costs', 'records', 'fuel', 'reminders'];

/// A vehicle's owner logbook. [initialTab] is one of costs/records/fuel/reminders
/// so Home's attention list can deep-link straight to Reminders.
class LogbookScreen extends StatefulWidget {
  const LogbookScreen({super.key, required this.vehicleId, this.initialTab});

  final String vehicleId;
  final String? initialTab;

  @override
  State<LogbookScreen> createState() => _LogbookScreenState();
}

class _LogbookScreenState extends State<LogbookScreen> with SingleTickerProviderStateMixin {
  late final TabController _tabs = TabController(
    length: _tabKeys.length,
    vsync: this,
    initialIndex: _tabKeys.contains(widget.initialTab) ? _tabKeys.indexOf(widget.initialTab!) : 0,
  );

  /// Summary feeds the Costs tab and the current odometer used to prefill forms.
  late Future<LogbookSummary> _summary;

  /// Bumped after any change so every tab refetches.
  int _generation = 0;

  @override
  void initState() {
    super.initState();
    _summary = _fetchSummary();
    _tabs.addListener(() {
      if (!_tabs.indexIsChanging) setState(() {});
    });
  }

  @override
  void dispose() {
    _tabs.dispose();
    super.dispose();
  }

  Future<LogbookSummary> _fetchSummary() => context.read<LogbookRepository>().fetchSummary(widget.vehicleId);

  void _refresh() => setState(() {
        _summary = _fetchSummary();
        _generation++;
      });

  Future<int> _odometer() async {
    try {
      return (await _summary).currentOdometerKm;
    } catch (_) {
      return 0;
    }
  }

  Future<void> _add() async {
    final odometer = await _odometer();
    if (!mounted) return;
    final Future<bool> sheet = switch (_tabs.index) {
      1 => showRecordSheet(context, vehicleId: widget.vehicleId, currentOdometerKm: odometer),
      2 => showFuelSheet(context, vehicleId: widget.vehicleId, currentOdometerKm: odometer),
      3 => showReminderSheet(context, vehicleId: widget.vehicleId),
      _ => Future.value(false),
    };
    final changed = await sheet;
    // Records refresh unconditionally: a new record's photos are added in the
    // same sheet after it's created.
    if (changed || _tabs.index == 1) _refresh();
  }

  Future<void> _export(String kind) async {
    final l10n = AppLocalizations.of(context)!;
    try {
      final csv = await context.read<LogbookRepository>().exportCsv(widget.vehicleId, kind);
      await Share.shareXFiles([XFile.fromData(csv.bytes, name: csv.filename, mimeType: 'text/csv')]);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(e is DioException ? ApiClient.messageFrom(e) : l10n.logbookExportFailed)),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final addLabel = switch (_tabs.index) {
      1 => l10n.recordsAdd,
      2 => l10n.fuelAdd,
      3 => l10n.remindersAdd,
      _ => null,
    };
    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.logbookTitle),
        actions: [
          PopupMenuButton<String>(
            icon: const Icon(Icons.ios_share),
            color: AppColors.navyMid,
            onSelected: _export,
            itemBuilder: (_) => [
              PopupMenuItem(value: 'records', child: Text(l10n.logbookExportRecords)),
              PopupMenuItem(value: 'fuel', child: Text(l10n.logbookExportFuel)),
            ],
          ),
        ],
        bottom: TabBar(
          controller: _tabs,
          isScrollable: true,
          tabAlignment: TabAlignment.start,
          indicatorColor: AppColors.goldMid,
          labelColor: AppColors.textPrimary,
          unselectedLabelColor: AppColors.textSecondary,
          tabs: [
            Tab(text: l10n.logbookTabCosts),
            Tab(text: l10n.logbookTabRecords),
            Tab(text: l10n.logbookTabFuel),
            Tab(text: l10n.logbookTabReminders),
          ],
        ),
      ),
      floatingActionButton: addLabel == null
          ? null
          : FloatingActionButton.extended(
              onPressed: _add,
              backgroundColor: AppColors.goldMid,
              foregroundColor: AppColors.navyDeep,
              icon: const Icon(Icons.add),
              label: Text(addLabel),
            ),
      body: GradientBackground(
        child: TabBarView(
          controller: _tabs,
          children: [
            _CostsTab(summary: _summary, onRetry: _refresh),
            _RecordsTab(key: ValueKey('records$_generation'), vehicleId: widget.vehicleId, odometer: _odometer, onChanged: _refresh),
            _FuelTab(key: ValueKey('fuel$_generation'), vehicleId: widget.vehicleId, odometer: _odometer, onChanged: _refresh),
            _RemindersTab(key: ValueKey('reminders$_generation'), vehicleId: widget.vehicleId, onChanged: _refresh),
          ],
        ),
      ),
    );
  }
}

/// Loads a future and renders loading / error / data states the same way on every tab.
class _Loader<T> extends StatefulWidget {
  const _Loader({super.key, required this.load, required this.builder, this.onRetry});

  final Future<T> Function() load;
  final Widget Function(BuildContext context, T data) builder;
  final VoidCallback? onRetry;

  @override
  State<_Loader<T>> createState() => _LoaderState<T>();
}

class _LoaderState<T> extends State<_Loader<T>> {
  late Future<T> _future = widget.load();

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return FutureBuilder<T>(
      future: _future,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }
        if (snapshot.hasError) {
          return EmptyState(
            icon: Icons.wifi_off,
            title: l10n.logbookCouldNotLoad,
            message: l10n.homeCheckConnection,
            actionLabel: l10n.commonRetry,
            onAction: widget.onRetry ?? () => setState(() => _future = widget.load()),
          );
        }
        return widget.builder(context, snapshot.data as T);
      },
    );
  }
}

// ---------- Costs ----------

class _CostsTab extends StatelessWidget {
  const _CostsTab({required this.summary, required this.onRetry});

  final Future<LogbookSummary> summary;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return _Loader<LogbookSummary>(
      key: ValueKey(summary),
      load: () => summary,
      onRetry: onRetry,
      builder: (context, s) {
        final l10n = AppLocalizations.of(context)!;
        if (s.total == 0 && s.fillUps == 0) {
          return EmptyState(icon: Icons.insights_outlined, title: l10n.logbookTabCosts, message: l10n.costsNothingYet);
        }
        final economy = s.averageKmPerLiter == null
            ? '—'
            : l10n.unitKmPerLiter(formatOneDecimal(s.averageKmPerLiter!));
        return ListView(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 100),
          children: [
            GridView.count(
              crossAxisCount: 2,
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              mainAxisSpacing: 12,
              crossAxisSpacing: 12,
              childAspectRatio: 1.7,
              children: [
                _StatTile(label: l10n.costsTotalSpent, value: formatAed(s.total)),
                _StatTile(label: l10n.costsPerKm, value: s.costPerKm == null ? '—' : formatAed(s.costPerKm!, cents: true)),
                _StatTile(label: l10n.costsDistanceTracked, value: formatKm(l10n, s.distanceTrackedKm)),
                _StatTile(
                  label: l10n.costsAvgEconomy,
                  value: economy,
                  sub: s.averageLitersPer100Km == null ? null : l10n.unitLitersPer100Km(formatOneDecimal(s.averageLitersPer100Km!)),
                ),
              ],
            ),
            const SizedBox(height: 16),
            GlassCard(child: CostChart(months: s.monthly)),
            const SizedBox(height: 16),
            GlassCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Text(l10n.costsBreakdown, style: Theme.of(context).textTheme.titleLarge),
                  const SizedBox(height: 10),
                  for (final c in costCategories)
                    Padding(
                      padding: const EdgeInsets.symmetric(vertical: 7),
                      child: Row(
                        children: [
                          CategorySwatch(category: c),
                          const SizedBox(width: 10),
                          Expanded(child: Text(categoryLabel(l10n, c), style: Theme.of(context).textTheme.bodyMedium)),
                          Text(
                            formatAed(s.totals[c] ?? 0),
                            style: const TextStyle(color: AppColors.textPrimary, fontFeatures: [FontFeature.tabularFigures()]),
                          ),
                          SizedBox(
                            width: 48,
                            child: Text(
                              s.total > 0 ? '${((s.totals[c] ?? 0) / s.total * 100).round()}%' : '',
                              textAlign: TextAlign.end,
                              style: Theme.of(context).textTheme.bodySmall,
                            ),
                          ),
                        ],
                      ),
                    ),
                  const Divider(color: AppColors.glassBorder),
                  Row(
                    children: [
                      Expanded(child: Text(l10n.costsMonthTotal, style: const TextStyle(color: AppColors.textPrimary, fontWeight: FontWeight.w700))),
                      Text(formatAed(s.total), style: const TextStyle(color: AppColors.goldLight, fontWeight: FontWeight.w700)),
                      const SizedBox(width: 48),
                    ],
                  ),
                ],
              ),
            ),
          ],
        );
      },
    );
  }
}

class _StatTile extends StatelessWidget {
  const _StatTile({required this.label, required this.value, this.sub});

  final String label;
  final String value;
  final String? sub;

  @override
  Widget build(BuildContext context) {
    return GlassCard(
      padding: const EdgeInsets.all(14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(label, style: Theme.of(context).textTheme.bodySmall, maxLines: 1, overflow: TextOverflow.ellipsis),
          const SizedBox(height: 4),
          FittedBox(
            fit: BoxFit.scaleDown,
            alignment: AlignmentDirectional.centerStart,
            child: Text(value, style: const TextStyle(color: AppColors.textPrimary, fontSize: 20, fontWeight: FontWeight.w800)),
          ),
          if (sub != null) Text(sub!, style: Theme.of(context).textTheme.bodySmall),
        ],
      ),
    );
  }
}

// ---------- Records ----------

class _RecordsTab extends StatelessWidget {
  const _RecordsTab({super.key, required this.vehicleId, required this.odometer, required this.onChanged});

  final String vehicleId;
  final Future<int> Function() odometer;
  final VoidCallback onChanged;

  @override
  Widget build(BuildContext context) {
    return _Loader<List<LogRecord>>(
      load: () => context.read<LogbookRepository>().fetchRecords(vehicleId),
      builder: (context, records) {
        final l10n = AppLocalizations.of(context)!;
        if (records.isEmpty) {
          return EmptyState(icon: Icons.menu_book_outlined, title: l10n.logbookTabRecords, message: l10n.recordsNoneYet);
        }
        return ListView.separated(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 100),
          itemCount: records.length,
          separatorBuilder: (_, __) => const SizedBox(height: 10),
          itemBuilder: (context, i) {
            final r = records[i];
            final subtitle = [
              formatDay(context, r.date),
              if (r.odometerKm != null) formatKm(l10n, r.odometerKm!),
              if (r.isBooking) r.partnerName ?? l10n.recordFromCarNanny,
            ].join(' · ');
            return GlassCard(
              padding: const EdgeInsets.all(14),
              onTap: r.isBooking
                  ? null
                  : () async {
                      final km = await odometer();
                      if (!context.mounted) return;
                      await showRecordSheet(context, vehicleId: vehicleId, currentOdometerKm: km, record: r);
                      onChanged();
                    },
              child: Row(
                children: [
                  Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(color: AppColors.glassFillStrong, borderRadius: BorderRadius.circular(12)),
                    child: Icon(r.isBooking ? categoryIcon('car_nanny') : categoryIcon(r.type), color: AppColors.goldLight, size: 20),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(r.title, style: Theme.of(context).textTheme.bodyLarge, maxLines: 2, overflow: TextOverflow.ellipsis),
                        Text(subtitle, style: Theme.of(context).textTheme.bodySmall),
                        if (r.isBooking)
                          Padding(
                            padding: const EdgeInsets.only(top: 4),
                            child: StatusBadge(status: 'green', label: l10n.recordFromCarNanny),
                          ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 8),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text(formatAed(r.cost), style: const TextStyle(color: AppColors.goldLight, fontWeight: FontWeight.w700)),
                      if (r.photos.isNotEmpty)
                        Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(Icons.receipt_long_outlined, size: 14, color: AppColors.textSecondary),
                            Text(' ${r.photos.length}', style: Theme.of(context).textTheme.bodySmall),
                          ],
                        ),
                    ],
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }
}

// ---------- Fuel ----------

class _FuelTab extends StatelessWidget {
  const _FuelTab({super.key, required this.vehicleId, required this.odometer, required this.onChanged});

  final String vehicleId;
  final Future<int> Function() odometer;
  final VoidCallback onChanged;

  @override
  Widget build(BuildContext context) {
    return _Loader<FuelLog>(
      load: () => context.read<LogbookRepository>().fetchFuel(vehicleId),
      builder: (context, log) {
        final l10n = AppLocalizations.of(context)!;
        if (log.entries.isEmpty) {
          return EmptyState(icon: Icons.local_gas_station_outlined, title: l10n.logbookTabFuel, message: l10n.fuelNoneYet);
        }
        return ListView(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 100),
          children: [
            Row(
              children: [
                Expanded(
                  child: _StatTile(
                    label: l10n.costsAvgEconomy,
                    value: log.averageKmPerLiter == null ? '—' : l10n.unitKmPerLiter(formatOneDecimal(log.averageKmPerLiter!)),
                    sub: log.averageLitersPer100Km == null ? null : l10n.unitLitersPer100Km(formatOneDecimal(log.averageLitersPer100Km!)),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _StatTile(
                    label: l10n.fuelTotalLiters,
                    value: l10n.unitLiters(formatInt(log.totalLiters)),
                    sub: '${l10n.fuelFillUps}: ${log.entries.length}',
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            for (final e in log.entries) ...[
              GlassCard(
                padding: const EdgeInsets.all(14),
                onTap: () async {
                  final km = await odometer();
                  if (!context.mounted) return;
                  final changed = await showFuelSheet(context, vehicleId: vehicleId, currentOdometerKm: km, entry: e);
                  if (changed) onChanged();
                },
                child: Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            '${formatDay(context, e.date)} · ${formatKm(l10n, e.odometerKm)}',
                            style: Theme.of(context).textTheme.bodyLarge,
                          ),
                          Text(
                            [
                              l10n.unitLiters(formatOneDecimal(e.liters)),
                              if (e.pricePerLiter != null) '${formatAed(e.pricePerLiter!, cents: true)}/L',
                              if (e.distanceKm != null) '+${formatKm(l10n, e.distanceKm!)}',
                            ].join(' · '),
                            style: Theme.of(context).textTheme.bodySmall,
                          ),
                        ],
                      ),
                    ),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Text(formatAed(e.cost), style: const TextStyle(color: AppColors.goldLight, fontWeight: FontWeight.w700)),
                        Text(
                          e.kmPerLiter != null
                              ? l10n.unitKmPerLiter(formatOneDecimal(e.kmPerLiter!))
                              : e.missedPrevious
                                  ? l10n.fuelMissed
                                  : !e.fullTank
                                      ? l10n.fuelPartial
                                      : '—',
                          style: Theme.of(context).textTheme.bodySmall,
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 10),
            ],
          ],
        );
      },
    );
  }
}

// ---------- Reminders ----------

class _RemindersTab extends StatelessWidget {
  const _RemindersTab({super.key, required this.vehicleId, required this.onChanged});

  final String vehicleId;
  final VoidCallback onChanged;

  Future<void> _complete(BuildContext context, Reminder r) async {
    final l10n = AppLocalizations.of(context)!;
    final messenger = ScaffoldMessenger.of(context);
    try {
      final scheduledNext = await context.read<LogbookRepository>().completeReminder(vehicleId, r.id);
      messenger.showSnackBar(SnackBar(content: Text(scheduledNext ? l10n.reminderNextScheduled : l10n.reminderMarkedDone)));
      onChanged();
    } catch (e) {
      messenger.showSnackBar(
        SnackBar(content: Text(e is DioException ? ApiClient.messageFrom(e) : l10n.commonSomethingWentWrong)),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return _Loader<List<Reminder>>(
      load: () => context.read<LogbookRepository>().fetchReminders(vehicleId),
      builder: (context, reminders) {
        final l10n = AppLocalizations.of(context)!;
        if (reminders.isEmpty) {
          return EmptyState(icon: Icons.notifications_none, title: l10n.logbookTabReminders, message: l10n.remindersNoneYet);
        }
        return ListView.separated(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 100),
          itemCount: reminders.length,
          separatorBuilder: (_, __) => const SizedBox(height: 10),
          itemBuilder: (context, i) {
            final r = reminders[i];
            final due = reminderDueText(
              context,
              l10n,
              dueDate: r.dueDate,
              daysLeft: r.isDone ? null : r.daysLeft,
              dueOdometerKm: r.dueOdometerKm,
              kmLeft: r.isDone ? null : r.kmLeft,
            );
            return Opacity(
              opacity: r.isDone ? 0.55 : 1,
              child: GlassCard(
                padding: const EdgeInsets.all(14),
                onTap: r.isDone
                    ? null
                    : () async {
                        final changed = await showReminderSheet(context, vehicleId: vehicleId, reminder: r);
                        if (changed) onChanged();
                      },
                child: Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          StatusBadge(status: r.isDone ? 'green' : urgencyStatus(r.urgency), label: urgencyLabel(l10n, r.urgency)),
                          const SizedBox(height: 6),
                          Text(r.title, style: Theme.of(context).textTheme.bodyLarge),
                          if (due.isNotEmpty) Text(due, style: Theme.of(context).textTheme.bodySmall),
                          if (r.repeatMonths != null || r.repeatKm != null)
                            Padding(
                              padding: const EdgeInsets.only(top: 2),
                              child: Row(
                                children: [
                                  const Icon(Icons.repeat, size: 14, color: AppColors.textSecondary),
                                  const SizedBox(width: 4),
                                  Text(
                                    [
                                      if (r.repeatMonths != null) l10n.reminderEveryMonths(r.repeatMonths!),
                                      if (r.repeatKm != null) l10n.reminderEveryKm(formatInt(r.repeatKm!)),
                                    ].join(' / '),
                                    style: Theme.of(context).textTheme.bodySmall,
                                  ),
                                ],
                              ),
                            ),
                        ],
                      ),
                    ),
                    if (!r.isDone)
                      TextButton.icon(
                        onPressed: () => _complete(context, r),
                        icon: const Icon(Icons.check, size: 18, color: AppColors.goldLight),
                        label: Text(l10n.reminderMarkDone, style: const TextStyle(color: AppColors.goldLight)),
                      ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }
}
