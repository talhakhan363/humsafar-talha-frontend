import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:geolocator/geolocator.dart';
import 'package:go_router/go_router.dart';
import 'package:humsafar_frontend/l10n/app_localizations.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../core/formatting/format_helpers.dart';
import '../../../core/network/api_exception.dart';
import '../../../core/network/providers.dart';
import '../../../shared/widgets/accessibility_toggle_button.dart';
import '../../../shared/widgets/language_switch_button.dart';

/// Task 6.8 — mockups 18/18b "Directory"/"Home care providers",
/// grounded in `directory_contract.md`. Two tabs over the same screen
/// (organizations, home-care providers) rather than two separate
/// routes — both are read-only lists sharing the same search/near-me/
/// Call shape, and splitting them would mean two nearly-identical
/// screens for no behavioural difference. "Near me" sends the
/// device's one-shot position (`Geolocator.getCurrentPosition`, not a
/// continuous stream like Task 2.7's background service — this screen
/// only ever needs one fix to sort by) only after the person opts in.
///
/// Calling an organization first logs the contact
/// (`POST .../directory/contacts`, `booking_contract.md`) and then
/// opens the device dialer (`tel:`, same `url_launcher` pattern Task
/// 3.14 established) — a `is_sample` entry's Call button is disabled
/// instead, per the contract's own "do not let the demo dial a sample
/// number as if real."
///
/// Activity log (18d) and requesting a visit (18c) are reached from
/// here; `ActivityLogScreen` itself also renders a booking's detail
/// (18e) in a bottom sheet rather than as a fifth separate route —
/// same data and actions mockup 18e shows, named scope decision to
/// keep this already-large batch's route/test count down.
class DirectoryScreen extends ConsumerStatefulWidget {
  const DirectoryScreen({super.key, required this.dependentId});

  final String dependentId;

  @override
  ConsumerState<DirectoryScreen> createState() => _DirectoryScreenState();
}

class _DirectoryScreenState extends ConsumerState<DirectoryScreen> {
  bool _showOrganizations = true;
  List<Map<String, dynamic>> _organizations = [];
  List<Map<String, dynamic>> _providers = [];
  bool _isLoading = true;
  String? _loadError;
  String _query = '';
  double? _lat;
  double? _lng;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() {
      _isLoading = true;
      _loadError = null;
    });
    try {
      final apiClient = ref.read(apiClientProvider);
      if (_showOrganizations) {
        final response = await apiClient.get<Map<String, dynamic>>(
          '/directory/organizations',
          queryParameters: {if (_query.isNotEmpty) 'q': _query, if (_lat != null) 'lat': _lat, if (_lng != null) 'lng': _lng},
        );
        if (!mounted) return;
        setState(() => _organizations = (response.data?['items'] as List<dynamic>? ?? []).cast<Map<String, dynamic>>());
      } else {
        final response = await apiClient.get<Map<String, dynamic>>(
          '/directory/providers',
          queryParameters: {if (_query.isNotEmpty) 'q': _query},
        );
        if (!mounted) return;
        setState(() => _providers = (response.data?['items'] as List<dynamic>? ?? []).cast<Map<String, dynamic>>());
      }
    } on ApiException catch (e) {
      if (!mounted) return;
      setState(() => _loadError = e.message);
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _useNearMe() async {
    try {
      final permission = await Geolocator.checkPermission();
      var granted = permission == LocationPermission.always || permission == LocationPermission.whileInUse;
      if (!granted) {
        final requested = await Geolocator.requestPermission();
        granted = requested == LocationPermission.always || requested == LocationPermission.whileInUse;
      }
      if (!granted) return;
      final position = await Geolocator.getCurrentPosition();
      if (!mounted) return;
      setState(() {
        _lat = position.latitude;
        _lng = position.longitude;
      });
      _load();
    } catch (_) {
      // Best-effort — a location failure just means the list stays
      // sorted by name, same fallback the contract itself describes.
    }
  }

  Future<void> _call(Map<String, dynamic> organization) async {
    final phone = organization['phone'] as String?;
    if (phone == null) return;
    try {
      await ref.read(apiClientProvider).post('/dependents/${widget.dependentId}/directory/contacts', data: {'org_id': organization['org_id']});
    } on ApiException {
      // Best-effort — logging the contact should never block actually
      // placing the call; booking_contract.md doesn't treat this log
      // as required for the call to work.
    }
    final uri = Uri(scheme: 'tel', path: phone);
    if (await canLaunchUrl(uri)) await launchUrl(uri);
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.directoryScreenTitle),
        actions: [
          const LanguageSwitchButton(),
          const AccessibilityToggleButton(),
          IconButton(
            icon: const Icon(Icons.receipt_long_outlined),
            tooltip: l10n.activityLogMenuItem,
            onPressed: () => context.push('/directory/activity', extra: widget.dependentId),
          ),
        ],
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
            child: Row(
              children: [
                Expanded(
                  child: ChoiceChip(
                    label: Text(l10n.directoryOrganizationsTabLabel),
                    selected: _showOrganizations,
                    onSelected: (_) {
                      setState(() => _showOrganizations = true);
                      _load();
                    },
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: ChoiceChip(
                    label: Text(l10n.directoryProvidersTabLabel),
                    selected: !_showOrganizations,
                    onSelected: (_) {
                      setState(() => _showOrganizations = false);
                      _load();
                    },
                  ),
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    decoration: InputDecoration(hintText: l10n.searchDirectoryHint, prefixIcon: const Icon(Icons.search)),
                    onSubmitted: (value) {
                      _query = value;
                      _load();
                    },
                  ),
                ),
                if (_showOrganizations)
                  IconButton(icon: const Icon(Icons.my_location), tooltip: l10n.nearMeButtonLabel, onPressed: _useNearMe),
              ],
            ),
          ),
          // Bug fix (2026-10-30): bottom-nav-bar overlap, see vitals_screen.dart.
          Expanded(child: SafeArea(bottom: true, top: false, child: RefreshIndicator(onRefresh: _load, child: _buildBody(l10n)))),
        ],
      ),
    );
  }

  Widget _buildBody(AppLocalizations l10n) {
    if (_isLoading) return const Center(child: CircularProgressIndicator());
    if (_loadError != null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(_loadError!, textAlign: TextAlign.center),
              const SizedBox(height: 12),
              ElevatedButton(onPressed: _load, child: Text(l10n.retryButton)),
            ],
          ),
        ),
      );
    }
    return _showOrganizations ? _buildOrganizations(l10n) : _buildProviders(l10n);
  }

  Widget _buildOrganizations(AppLocalizations l10n) {
    if (_organizations.isEmpty) return Center(child: Text(l10n.noDirectoryResultsMessage, textAlign: TextAlign.center));
    // Bug fix (G-03, QA 6.12 Directory Results v1.0, D-01): the national
    // emergency numbers (Rescue 1122, Edhi 115, ...) were sorted
    // alphabetically among ~20 demo entries instead of grouped at the
    // top, as in mockup screen 18. `directory_contract.md` says they're
    // the only entries with no position ("lat, lng (null for national
    // numbers)") — that's the one field that tells them apart from a
    // regular demo organization, so it's the grouping key, not name or
    // `is_sample` (every national number already has `is_sample: false`,
    // same as a hypothetical future real entry would).
    final national = _organizations.where((org) => org['lat'] == null).toList();
    final others = _organizations.where((org) => org['lat'] != null).toList();
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        if (national.isNotEmpty) ...[
          Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: Text(l10n.emergencyNumbersSectionHeader, style: Theme.of(context).textTheme.titleMedium),
          ),
          ...national.map((org) => _buildOrganizationCard(l10n, org)),
          const SizedBox(height: 12),
        ],
        ...others.map((org) => _buildOrganizationCard(l10n, org)),
      ],
    );
  }

  Widget _buildOrganizationCard(AppLocalizations l10n, Map<String, dynamic> org) {
    final isSample = org['is_sample'] as bool? ?? false;
    final distance = formatDistanceKm(org['distance_km'] as double?);
    final phone = org['phone'] as String?;
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: ListTile(
        title: Text(org['name'] as String? ?? ''),
        subtitle: Text(
          '${org['city'] as String? ?? ''}${distance == null ? '' : ' · $distance'}'
          '${isSample ? ' · ${l10n.sampleEntryLabel}' : ''}',
        ),
        trailing: phone == null || isSample
            ? null
            // Bug fix (N-08, QA 3.16 Accessibility Results v1.0, C-02): no tooltip.
            : IconButton(icon: const Icon(Icons.call), tooltip: l10n.callButtonTooltip, onPressed: () => _call(org)),
      ),
    );
  }

  Widget _buildProviders(AppLocalizations l10n) {
    if (_providers.isEmpty) return Center(child: Text(l10n.noDirectoryResultsMessage, textAlign: TextAlign.center));
    return ListView(
      padding: const EdgeInsets.all(16),
      children: _providers.map((provider) {
        final isSample = provider['is_sample'] as bool? ?? false;
        return Card(
          margin: const EdgeInsets.only(bottom: 12),
          child: ListTile(
            title: Text(provider['name'] as String? ?? ''),
            subtitle: Text(
              '${provider['specialization'] as String? ?? ''} · ${formatPkrOrAsk(provider['service_charge'] as num?, l10n.askForPriceLabel)}'
              '${isSample ? ' · ${l10n.sampleEntryLabel}' : ''}',
            ),
            trailing: TextButton(
              onPressed: () => context.push('/directory/request-visit', extra: {'dependentId': widget.dependentId, 'provider': provider}),
              child: Text(l10n.requestVisitButtonLabel),
            ),
          ),
        );
      }).toList(),
    );
  }
}
