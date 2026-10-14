import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:latlong2/latlong.dart';

import '../../../core/api/api_exception.dart';
import '../../../core/constants/app_constants.dart';
import '../../../core/i18n/i18n_controller.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/utils/bidi_text.dart';
import '../../../core/utils/breakpoints.dart';
import '../../../core/utils/formatters.dart';
import '../../../shared/models/geo_location.dart';
import '../../../shared/widgets/app_button.dart';
import '../../../shared/widgets/app_text_field.dart';
import '../data/oman_geo.dart';
import '../data/place_suggestion.dart';
import '../data/places_repository.dart';

class LocationPickerScreen extends ConsumerStatefulWidget {
  const LocationPickerScreen({
    super.key,
    required this.title,
    this.initial,
  });

  final String title;
  final GeoLocation? initial;

  static Future<GeoLocation?> open(
    BuildContext context, {
    required String title,
    GeoLocation? initial,
  }) {
    final size = MediaQuery.sizeOf(context);
    if (size.width >= AppConstants.desktopBreakpoint) {
      final width = math.min(1040.0, size.width - 80);
      final height = math.min(680.0, size.height - 72);
      return showDialog<GeoLocation>(
        context: context,
        barrierColor: const Color(0xB3101A2B),
        builder: (context) {
          return Dialog(
            insetPadding: const EdgeInsets.symmetric(horizontal: 40, vertical: 28),
            backgroundColor: Colors.transparent,
            elevation: 0,
            child: SizedBox(
              width: width,
              height: height,
              child: LocationPickerScreen(title: title, initial: initial),
            ),
          );
        },
      );
    }

    return Navigator.of(context).push<GeoLocation>(
      MaterialPageRoute(
        builder: (_) => LocationPickerScreen(title: title, initial: initial),
      ),
    );
  }

  @override
  ConsumerState<LocationPickerScreen> createState() => _LocationPickerScreenState();
}

class _LocationPickerScreenState extends ConsumerState<LocationPickerScreen> {
  final _search = TextEditingController();
  final _address = TextEditingController();
  final _city = TextEditingController();
  final _governorate = TextEditingController();
  final _wilayat = TextEditingController();
  final _mapController = MapController();
  Timer? _debounce;
  List<PlaceSuggestion> _suggestions = [];
  bool _searching = false;
  bool _resolving = false;
  String? _searchError;
  late LatLng _center;
  GeoLocation? _selected;

  @override
  void initState() {
    super.initState();
    final initial = widget.initial;
    if (initial != null && initial.hasCoordinates) {
      _selected = initial;
      _hydrateFields(initial);
      _center = LatLng(initial.lat, initial.lng);
    } else {
      _center = const LatLng(AppConstants.mapDefaultLat, AppConstants.mapDefaultLng);
    }
  }

  void _hydrateFields(GeoLocation location) {
    _address.text = location.address;
    _city.text = location.city;
    _governorate.text = location.governorate;
    _wilayat.text = location.wilayat;
    if (_governorate.text.isNotEmpty || _wilayat.text.isNotEmpty) {
      return;
    }
    final parts = location.city
        .split(RegExp(r'\s*[،,]\s*'))
        .map((part) => part.trim())
        .where((part) => part.isNotEmpty)
        .toList();
    if (parts.length >= 2) {
      _wilayat.text = parts.first;
      _governorate.text = parts.sublist(1).join(', ');
    } else if (parts.length == 1) {
      _wilayat.text = parts.first;
    }
  }

  @override
  void dispose() {
    _debounce?.cancel();
    _search.dispose();
    _address.dispose();
    _city.dispose();
    _governorate.dispose();
    _wilayat.dispose();
    _mapController.dispose();
    super.dispose();
  }

  void _onSearchChanged(String value) {
    _debounce?.cancel();
    if (value.trim().length < 2) {
      setState(() {
        _suggestions = [];
        _searchError = null;
        _searching = false;
      });
      return;
    }
    _debounce = Timer(const Duration(milliseconds: 350), () => _searchPlaces(value.trim()));
  }

  Future<void> _searchPlaces(String query) async {
    setState(() {
      _searching = true;
      _searchError = null;
    });
    try {
      final results = await ref.read(placesRepositoryProvider).autocomplete(query);
      if (!mounted) return;
      setState(() {
        _suggestions = results;
        _searching = false;
      });
    } catch (error) {
      if (!mounted) return;
      setState(() {
        _suggestions = [];
        _searching = false;
        _searchError = _mapsError(error);
      });
    }
  }

  Future<void> _selectSuggestion(PlaceSuggestion suggestion) async {
    setState(() {
      _resolving = true;
      _suggestions = [];
      _search.text = suggestion.description;
    });
    try {
      final location = await ref.read(placesRepositoryProvider).details(
            suggestion.placeId,
            language: ref.i18n.locale.languageCode,
          );
      if (!mounted) return;
      _applyLocation(location);
    } catch (error) {
      if (!mounted) return;
      setState(() => _searchError = _mapsError(error));
    } finally {
      if (mounted) setState(() => _resolving = false);
    }
  }

  Future<void> _dropPin(LatLng point) async {
    setState(() {
      _center = point;
      _resolving = true;
      _suggestions = [];
    });
    _mapController.move(point, AppConstants.mapPlaceZoom);
    try {
      final location = await ref.read(placesRepositoryProvider).reverse(
            point.latitude,
            point.longitude,
            language: ref.i18n.locale.languageCode,
          );
      if (!mounted) return;
      if (location == null) {
        setState(() => _searchError = ref.i18n.t('location.searchFailed'));
      } else {
        _searchError = null;
      }
      _applyLocation(
        (location ?? const GeoLocation(address: '', city: '', lat: 0, lng: 0)).copyWith(
          address: _address.text.trim(),
          lat: point.latitude,
          lng: point.longitude,
        ),
      );
    } catch (error) {
      if (!mounted) return;
      setState(() => _searchError = _mapsError(error));
      _applyLocation(
        GeoLocation(
          address: _address.text.trim(),
          city: _composedCity(),
          governorate: _governorate.text.trim(),
          wilayat: _wilayat.text.trim(),
          lat: point.latitude,
          lng: point.longitude,
        ),
      );
    } finally {
      if (mounted) setState(() => _resolving = false);
    }
  }

  void _applyLocation(GeoLocation location) {
    final resolved = applyOmanDivisions(location);
    final point = LatLng(resolved.lat, resolved.lng);
    _governorate.text = resolved.governorate.trim();
    _wilayat.text = resolved.wilayat.trim();
    _city.text = resolved.city.trim().isNotEmpty ? resolved.city.trim() : _composedCity();
    _selected = resolved.copyWith(
      address: _address.text.trim(),
      city: _city.text.trim(),
      governorate: _governorate.text.trim(),
      wilayat: _wilayat.text.trim(),
    );
    _center = point;
    _mapController.move(point, AppConstants.mapPlaceZoom);
    setState(() {});
  }

  String _composedCity() {
    final parts = [
      _wilayat.text.trim(),
      _governorate.text.trim(),
    ].where((part) => part.isNotEmpty);
    if (parts.isEmpty) return _city.text.trim();
    return parts.join(', ');
  }

  void _confirm() {
    final location = GeoLocation(
      address: _address.text.trim(),
      city: _composedCity(),
      governorate: _governorate.text.trim(),
      wilayat: _wilayat.text.trim(),
      lat: _selected?.lat ?? _center.latitude,
      lng: _selected?.lng ?? _center.longitude,
      placeId: _selected?.placeId,
    );
    if (location.city.isEmpty || !location.hasCoordinates) {
      return;
    }
    Navigator.of(context).pop(location);
  }

  String _mapsError(Object error) {
    final i18n = ref.i18n;
    if (error is ApiException) {
      if (error.statusCode == 503) return i18n.t('location.mapsUnavailable');
      if (error.message == 'network') return i18n.t('common.networkError');
      return error.message;
    }
    return i18n.t('location.searchFailed');
  }

  bool get _canConfirm {
    return _composedCity().isNotEmpty && _selected != null;
  }

  @override
  Widget build(BuildContext context) {
    final i18n = ref.i18n;
    final wide = context.isDesktop;
    final panel = Material(
      color: AppColors.surface,
      borderRadius: BorderRadius.circular(wide ? 16 : 0),
      clipBehavior: Clip.antiAlias,
      child: Column(
        children: [
          _titleBar(context, wide),
          Expanded(
            child: Padding(
              padding: EdgeInsets.fromLTRB(wide ? 20 : 16, 0, wide ? 20 : 16, wide ? 20 : 12),
              child: wide ? _wideBody(i18n) : _phoneBody(i18n),
            ),
          ),
        ],
      ),
    );

    if (wide) return panel;

    return Scaffold(
      backgroundColor: AppColors.surface,
      resizeToAvoidBottomInset: true,
      body: SafeArea(child: panel),
    );
  }

  Widget _titleBar(BuildContext context, bool wide) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(8, 8, 16, 8),
      child: Row(
        children: [
          IconButton(
            tooltip: MaterialLocalizations.of(context).closeButtonTooltip,
            onPressed: () => Navigator.of(context).pop(),
            icon: Icon(wide ? Icons.close_rounded : Icons.arrow_back),
          ),
          Expanded(
            child: Text(
              widget.title,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    color: AppColors.ink,
                    fontWeight: FontWeight.w700,
                  ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _wideBody(I18nBundle i18n) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        SizedBox(width: 360, child: _details(i18n, scroll: true)),
        const SizedBox(width: 20),
        Expanded(child: _mapFrame(i18n)),
      ],
    );
  }

  Widget _phoneBody(I18nBundle i18n) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final mapHeight = math.max(200.0, constraints.maxHeight * 0.42);
        return Column(
          children: [
            SizedBox(height: mapHeight, child: _mapFrame(i18n)),
            const SizedBox(height: 12),
            Expanded(child: _details(i18n, scroll: true)),
          ],
        );
      },
    );
  }

  Widget _details(I18nBundle i18n, {required bool scroll}) {
    final fields = Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _searchField(i18n),
        if (_searchError != null) ...[
          const SizedBox(height: 8),
          Text(_searchError!, style: const TextStyle(color: AppColors.danger)),
        ],
        if (_suggestions.isNotEmpty) ...[
          const SizedBox(height: 8),
          _suggestionList(),
        ],
        const SizedBox(height: 12),
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: AppTextField(
                label: i18n.t('location.governorate'),
                controller: _governorate,
                readOnly: true,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: AppTextField(
                label: i18n.t('location.wilayat'),
                controller: _wilayat,
                readOnly: true,
              ),
            ),
          ],
        ),
        const SizedBox(height: 6),
        Text(
          i18n.t('location.autoFilledFromMap'),
          style: const TextStyle(color: AppColors.muted, fontSize: 12),
        ),
        const SizedBox(height: 12),
        AppTextField(
          label: '${i18n.t('common.address')} (${i18n.t('common.optional')})',
          hint: i18n.t('location.addressHint'),
          controller: _address,
          onChanged: (_) => setState(() {}),
        ),
        const SizedBox(height: 8),
        Text(
          '${i18n.t('location.coordinates')}: ${formatCoordinates(_selected?.lat ?? _center.latitude, _selected?.lng ?? _center.longitude)}',
          style: const TextStyle(color: AppColors.muted),
        ),
        const SizedBox(height: 16),
        AppButton(
          label: i18n.t('location.confirm'),
          expanded: true,
          onPressed: _canConfirm && !_resolving ? _confirm : null,
        ),
      ],
    );

    if (!scroll) return fields;
    return SingleChildScrollView(child: fields);
  }

  Widget _searchField(I18nBundle i18n) {
    return AppTextField(
      label: i18n.t('location.searchGoogleMaps'),
      hint: i18n.t('location.searchHint'),
      controller: _search,
      onChanged: _onSearchChanged,
      suffix: _searching
          ? const Padding(
              padding: EdgeInsets.all(12),
              child: SizedBox(
                width: 16,
                height: 16,
                child: CircularProgressIndicator(strokeWidth: 2),
              ),
            )
          : const Icon(Icons.search),
    );
  }

  Widget _suggestionList() {
    return ConstrainedBox(
      constraints: const BoxConstraints(maxHeight: 200),
      child: DecoratedBox(
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.border),
      ),
      child: ListView.separated(
        shrinkWrap: true,
        physics: const ClampingScrollPhysics(),
        itemCount: _suggestions.length,
        separatorBuilder: (_, _) => const Divider(height: 1),
        itemBuilder: (context, index) {
          final item = _suggestions[index];
          return ListTile(
            dense: true,
            visualDensity: VisualDensity.compact,
            leading: const Icon(Icons.place_outlined, color: AppColors.orange, size: 20),
            title: Text(
              bidiIsolate(item.mainText ?? item.description),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            subtitle: item.secondaryText == null
                ? null
                : Text(
                    bidiIsolate(item.secondaryText!),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
            onTap: _resolving ? null : () => _selectSuggestion(item),
          );
        },
      ),
      ),
    );
  }

  Widget _mapFrame(I18nBundle i18n) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(12),
      child: Stack(
        children: [
          FlutterMap(
            mapController: _mapController,
            options: MapOptions(
              initialCenter: _center,
              initialZoom: widget.initial == null
                  ? AppConstants.mapCountryZoom
                  : AppConstants.mapPlaceZoom,
              onTap: (_, point) => _dropPin(point),
            ),
            children: [
              TileLayer(
                urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                userAgentPackageName: 'com.example.mz_logistics_customer_app',
              ),
              if (_selected != null)
                MarkerLayer(
                  markers: [
                    Marker(
                      point: LatLng(_selected!.lat, _selected!.lng),
                      width: 40,
                      height: 40,
                      alignment: Alignment.topCenter,
                      child: const Icon(Icons.location_on, color: AppColors.orange, size: 40),
                    ),
                  ],
                ),
            ],
          ),
          if (_resolving)
            const Positioned(
              top: 12,
              right: 12,
              child: Card(
                child: Padding(
                  padding: EdgeInsets.all(8),
                  child: SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  ),
                ),
              ),
            ),
          Positioned(
            left: 12,
            right: 12,
            bottom: 12,
            child: IgnorePointer(
              child: Text(
                i18n.t('location.dropPinHint'),
                textAlign: TextAlign.center,
                style: const TextStyle(
                  color: AppColors.ink,
                  fontWeight: FontWeight.w600,
                  shadows: [Shadow(color: Colors.white, blurRadius: 8)],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
