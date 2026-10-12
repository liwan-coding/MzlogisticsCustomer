import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/api/api_exception.dart';
import '../../../core/i18n/i18n_controller.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/utils/breakpoints.dart';
import '../../../core/utils/formatters.dart';
import '../../../shared/models/geo_location.dart';
import '../../../shared/widgets/app_button.dart';
import '../../../shared/widgets/app_text_field.dart';
import '../../../shared/widgets/location_picker_field.dart';
import '../../../shared/widgets/page_scaffold.dart';
import '../../payments/presentation/payment_contract_providers.dart';
import '../../payments/presentation/widgets/payment_terms_fields.dart';
import '../data/quantity_units.dart';
import '../data/shipment_model.dart';
import '../data/truck_type.dart';
import 'widgets/shipment_create_stepper.dart';
import '../data/shipment_repository.dart';
import 'shipment_providers.dart';

class CreateShipmentScreen extends ConsumerStatefulWidget {
  const CreateShipmentScreen({super.key});

  @override
  ConsumerState<CreateShipmentScreen> createState() =>
      _CreateShipmentScreenState();
}

class _CreateShipmentScreenState extends ConsumerState<CreateShipmentScreen> {
  static const _otherTruckType = '__other__';

  final _formKey = GlobalKey<FormState>();
  final _cargoType = TextEditingController();
  final _cargoDescription = TextEditingController();
  final _weight = TextEditingController();
  final _volume = TextEditingController();
  final _quantity = TextEditingController();
  final _notes = TextEditingController();
  final _customTruckType = TextEditingController();
  GeoLocation? _pickup;
  GeoLocation? _delivery;
  String _quantityUnit = QuantityUnits.tons;
  String? _truckType;
  DateTime? _requiredDate;
  bool _publish = true;
  bool _submitting = false;
  int _step = 0;
  int _stepDirection = 1;
  String? _error;
  String _billingTrigger = 'on_delivery';
  String _billingUnit = 'job';
  int _dueDays = 0;
  bool _paymentPrefillDone = false;
  final List<GlobalKey> _stageKeys = List.generate(3, (_) => GlobalKey());

  @override
  void initState() {
    super.initState();
    _cargoType.addListener(_refreshDraft);
    _weight.addListener(_refreshDraft);
    _quantity.addListener(_refreshDraft);
    _customTruckType.addListener(_refreshDraft);
  }

  void _refreshDraft() {
    if (mounted) setState(() {});
  }

  bool get _cargoReady {
    if (_cargoType.text.trim().isEmpty) return false;
    if (_resolvedTruckType() == null) return false;
    if ((double.tryParse(_weight.text) ?? 0) <= 0) return false;
    if (!QuantityUnits.isTons(_quantityUnit) &&
        (double.tryParse(_quantity.text) ?? 0) <= 0) {
      return false;
    }
    return true;
  }

  bool get _routeReady {
    final pickup = _pickup;
    final delivery = _delivery;
    if (pickup == null || pickup.city.isEmpty || !pickup.hasCoordinates) {
      return false;
    }
    if (delivery == null || delivery.city.isEmpty || !delivery.hasCoordinates) {
      return false;
    }
    return true;
  }

  int get _desktopStage {
    if (!_cargoReady) return 0;
    if (!_routeReady) return 1;
    if (_requiredDate == null) return 2;
    return 3;
  }

  @override
  void dispose() {
    _cargoType.removeListener(_refreshDraft);
    _weight.removeListener(_refreshDraft);
    _quantity.removeListener(_refreshDraft);
    _customTruckType.removeListener(_refreshDraft);
    _cargoType.dispose();
    _cargoDescription.dispose();
    _weight.dispose();
    _volume.dispose();
    _quantity.dispose();
    _notes.dispose();
    _customTruckType.dispose();
    super.dispose();
  }

  bool _validateStep(I18nBundle i18n) {
    if (_step == 0) {
      if (_cargoType.text.trim().isEmpty) {
        _error = i18n.t('shipment.cargoTypeRequired');
        return false;
      }
      if (ref.read(truckTypesProvider).isLoading) {
        return false;
      }
      if (_resolvedTruckType() == null) {
        _error = _writeInTruckType()
            ? i18n.t('shipment.customTruckTypeRequired')
            : i18n.t('shipment.truckTypeRequired');
        return false;
      }
      if ((double.tryParse(_weight.text) ?? 0) <= 0) {
        _error = i18n.t('shipment.weightRequired');
        return false;
      }
      if (!QuantityUnits.isTons(_quantityUnit) &&
          (double.tryParse(_quantity.text) ?? 0) <= 0) {
        _error = i18n.t('shipment.quantityRequired');
        return false;
      }
    }
    if (_step == 1) {
      if (_pickup == null || _pickup!.city.isEmpty) {
        _error = i18n.t('shipment.pickupRequired');
        return false;
      }
      if (!_pickup!.hasCoordinates) {
        _error = i18n.t('location.pickupMapRequired');
        return false;
      }
      if (_delivery == null || _delivery!.city.isEmpty) {
        _error = i18n.t('shipment.deliveryRequired');
        return false;
      }
      if (!_delivery!.hasCoordinates) {
        _error = i18n.t('location.deliveryMapRequired');
        return false;
      }
    }
    _error = null;
    return true;
  }

  Future<void> _pickDate() async {
    final i18n = ref.i18n;
    final now = DateTime.now();
    final selected = await showDatePicker(
      context: context,
      locale: i18n.locale,
      initialDate: _requiredDate ?? now,
      firstDate: DateTime(now.year, now.month, now.day),
      lastDate: DateTime(now.year + 2),
    );
    if (selected == null) return;
    setState(() {
      _requiredDate = selected;
      if (_error == i18n.t('shipment.dateRequired')) _error = null;
    });
  }

  Future<void> _submit({required bool publish}) async {
    final i18n = ref.i18n;
    if (_submitting) return;
    if (_requiredDate == null) {
      setState(() => _error = i18n.t('shipment.dateRequired'));
      return;
    }
    if (!(_formKey.currentState?.validate() ?? false) || !_validateStep(i18n)) {
      setState(() {});
      return;
    }
    setState(() {
      _submitting = true;
      _error = null;
      _publish = publish;
    });
    try {
      final created = await ref
          .read(shipmentRepositoryProvider)
          .create(
            CreateShipmentPayload(
              cargoType: _cargoType.text.trim(),
              truckType: _resolvedTruckType()!,
              cargoDescription: _cargoDescription.text.trim(),
              weightTons: double.parse(_weight.text),
              volumeCbm: double.tryParse(_volume.text),
              quantity: QuantityUnits.isTons(_quantityUnit)
                  ? double.parse(_weight.text)
                  : double.parse(_quantity.text),
              quantityUnit: _quantityUnit,
              pickupAddress: _pickup!.address.trim(),
              pickupCity: _pickup!.city.trim(),
              pickupLat: _pickup!.lat,
              pickupLng: _pickup!.lng,
              deliveryAddress: _delivery!.address.trim(),
              deliveryCity: _delivery!.city.trim(),
              deliveryLat: _delivery!.lat,
              deliveryLng: _delivery!.lng,
              requiredDate: _requiredDate!,
              notes: _notes.text.trim(),
              publish: publish,
              billingTrigger: _billingTrigger,
              dueDays: _dueDays,
              billingUnit: _billingUnit,
            ),
          );
      ref.invalidate(shipmentsProvider);
      if (!mounted) return;
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text(i18n.t('shipment.created'))));
      context.go('/shipments/${created.id}');
    } catch (error) {
      if (!mounted) return;
      setState(() {
        _error = error is ApiException
            ? (error.message == 'network'
                  ? i18n.t('common.networkError')
                  : error.message)
            : error.toString();
      });
    } finally {
      if (mounted) setState(() => _submitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final i18n = ref.i18n;
    final desktop = context.isDesktop;
    final contractAsync = ref.watch(paymentContractProvider);
    contractAsync.whenData((contract) {
      if (_paymentPrefillDone) return;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted || _paymentPrefillDone) return;
        setState(() {
          _paymentPrefillDone = true;
          _billingTrigger = contract.billingTrigger == 'on_award'
              ? 'on_delivery'
              : contract.billingTrigger;
          _billingUnit = contract.billingUnit;
          _dueDays = contract.dueDays;
        });
      });
    });
    final steps = [
      ShipmentCreateStep(
        label: i18n.t('shipment.stepCargo'),
        icon: Icons.inventory_2_outlined,
      ),
      ShipmentCreateStep(
        label: i18n.t('shipment.stepRoute'),
        icon: Icons.route_rounded,
      ),
      ShipmentCreateStep(
        label: i18n.t('shipment.stepSchedule'),
        icon: Icons.event_outlined,
      ),
    ];
    final hints = [
      i18n.t('shipment.stepCargoHint'),
      i18n.t('shipment.stepRouteHint'),
      i18n.t('shipment.stepScheduleHint'),
    ];
    final stage = desktop ? _desktopStage : _step;

    return PageScaffold(
      title: i18n.t('shipment.create'),
      showBack: true,
      body: ContentWidth(
        maxWidth: 880,
        child: Form(
          key: _formKey,
          child: ListView(
            children: [
              ShipmentCreateStepper(
                steps: steps,
                current: stage,
                progressLabel: i18n.t('shipment.stepProgress', {
                  'current': '${(stage.clamp(0, steps.length - 1)) + 1}',
                  'total': '${steps.length}',
                }),
                canSelect: desktop ? null : (index) => index <= _step,
                onSelect: (index) =>
                    desktop ? _revealStage(index) : _selectStep(index),
              ),
              if (!desktop) ...[
                const SizedBox(height: 18),
                AnimatedSwitcher(
                  duration: MediaQuery.disableAnimationsOf(context)
                      ? Duration.zero
                      : const Duration(milliseconds: 380),
                  switchInCurve: Curves.easeOutCubic,
                  switchOutCurve: Curves.easeInCubic,
                  layoutBuilder: (currentChild, previousChildren) {
                    return Stack(
                      alignment: Alignment.topCenter,
                      children: [...previousChildren, ?currentChild],
                    );
                  },
                  transitionBuilder: (child, animation) {
                    final rtl = Directionality.of(context) == TextDirection.rtl;
                    final forward = rtl ? -_stepDirection : _stepDirection;
                    final incoming =
                        animation.status == AnimationStatus.forward ||
                        animation.status == AnimationStatus.completed;
                    final travel = (incoming ? forward : -forward) * 0.16;
                    return FadeTransition(
                      opacity: animation,
                      child: SlideTransition(
                        position: Tween<Offset>(
                          begin: Offset(travel, 0),
                          end: Offset.zero,
                        ).animate(animation),
                        child: child,
                      ),
                    );
                  },
                  child: KeyedSubtree(
                    key: ValueKey(_step),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Text(
                          steps[_step].label,
                          style: Theme.of(context).textTheme.titleMedium
                              ?.copyWith(fontWeight: FontWeight.w700),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          hints[_step],
                          style: Theme.of(context).textTheme.bodyMedium
                              ?.copyWith(color: AppColors.muted, height: 1.4),
                        ),
                        const SizedBox(height: 16),
                        _stageCard(
                          index: _step,
                          title: steps[_step].label,
                          hint: hints[_step],
                          icon: steps[_step].icon,
                          showHeading: false,
                          child: _step == 0
                              ? _cargoFields(i18n)
                              : _step == 1
                              ? _routeFields(i18n)
                              : _scheduleFields(i18n),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
              if (desktop) ...[
                const SizedBox(height: 16),
                _stageCard(
                  index: 0,
                  title: steps[0].label,
                  hint: hints[0],
                  icon: steps[0].icon,
                  child: _cargoFields(i18n),
                ),
                const SizedBox(height: 16),
                _stageCard(
                  index: 1,
                  title: steps[1].label,
                  hint: hints[1],
                  icon: steps[1].icon,
                  child: _routeFields(i18n),
                ),
                const SizedBox(height: 16),
                _stageCard(
                  index: 2,
                  title: steps[2].label,
                  hint: hints[2],
                  icon: steps[2].icon,
                  child: _scheduleFields(i18n),
                ),
              ],
              if (_error != null) ...[
                const SizedBox(height: 12),
                Text(_error!, style: const TextStyle(color: AppColors.danger)),
              ],
              const SizedBox(height: 20),
              if (desktop)
                Row(
                  children: [
                    Expanded(
                      child: AppButton(
                        label: i18n.t('shipment.saveDraft'),
                        variant: AppButtonVariant.secondary,
                        loading: _submitting && !_publish,
                        onPressed: _submitting
                            ? null
                            : () => _submit(publish: false),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: AppButton(
                        label: i18n.t('shipment.publish'),
                        loading: _submitting && _publish,
                        onPressed: _submitting
                            ? null
                            : () => _submit(publish: true),
                      ),
                    ),
                  ],
                )
              else
                Row(
                  children: [
                    if (_step > 0)
                      Expanded(
                        child: AppButton(
                          label: i18n.t('common.back'),
                          variant: AppButtonVariant.secondary,
                          onPressed: _submitting
                              ? null
                              : () => _moveStep(_step - 1),
                        ),
                      ),
                    if (_step > 0) const SizedBox(width: 12),
                    Expanded(
                      child: AppButton(
                        label: _step < 2
                            ? i18n.t('common.next')
                            : i18n.t('shipment.publish'),
                        loading: _submitting && _step == 2,
                        onPressed: _submitting
                            ? null
                            : () {
                                if (!_validateStep(i18n)) {
                                  setState(() {});
                                  return;
                                }
                                if (_step < 2) {
                                  _moveStep(_step + 1);
                                } else {
                                  _submit(publish: _publish);
                                }
                              },
                      ),
                    ),
                  ],
                ),
              if (!desktop && _step == 2) ...[
                const SizedBox(height: 8),
                AppButton(
                  label: i18n.t('shipment.saveDraft'),
                  variant: AppButtonVariant.ghost,
                  onPressed: _submitting ? null : () => _submit(publish: false),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  void _selectStep(int index) {
    if (index >= _step) return;
    _moveStep(index);
  }

  void _moveStep(int next) {
    if (next == _step || next < 0 || next > 2) return;
    setState(() {
      _stepDirection = next > _step ? 1 : -1;
      _step = next;
      _error = null;
    });
  }

  void _revealStage(int index) {
    final target = _stageKeys[index].currentContext;
    if (target == null) return;
    Scrollable.ensureVisible(
      target,
      duration: MediaQuery.disableAnimationsOf(context)
          ? Duration.zero
          : const Duration(milliseconds: 280),
      curve: Curves.easeOutCubic,
      alignment: 0.02,
    );
  }

  Widget _stageCard({
    required int index,
    required String title,
    required String hint,
    required IconData icon,
    required Widget child,
    bool showHeading = true,
  }) {
    return Card(
      key: _stageKeys[index],
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            if (showHeading)
              ShipmentStageHeading(icon: icon, title: title, hint: hint),
            child,
          ],
        ),
      ),
    );
  }

  Widget _cargoFields(I18nBundle i18n) {
    final byWeight = QuantityUnits.isTons(_quantityUnit);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        AppTextField(
          label: i18n.t('shipment.cargoType'),
          controller: _cargoType,
        ),
        const SizedBox(height: 12),
        _truckTypeField(i18n),
        const SizedBox(height: 12),
        AppTextField(
          label: i18n.t('shipment.cargoDescription'),
          controller: _cargoDescription,
          maxLines: 3,
        ),
        const SizedBox(height: 16),
        Text(
          i18n.t('shipment.measureBy'),
          style: Theme.of(context).textTheme.titleSmall
              ?.copyWith(fontWeight: FontWeight.w700),
        ),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            _measureChip(i18n.t('shipment.measureTons'), QuantityUnits.tons),
            _measureChip(
              i18n.t('shipment.measurePallets'),
              QuantityUnits.pallets,
            ),
            _measureChip(i18n.t('shipment.measureUnits'), QuantityUnits.units),
          ],
        ),
        const SizedBox(height: 8),
        Text(
          QuantityUnits.measureHint(i18n, _quantityUnit),
          style: Theme.of(context).textTheme.bodySmall
              ?.copyWith(color: AppColors.muted, height: 1.4),
        ),
        const SizedBox(height: 16),
        if (!byWeight) ...[
          AppTextField(
            label: QuantityUnits.countFieldLabel(i18n, _quantityUnit),
            controller: _quantity,
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
          ),
          const SizedBox(height: 12),
        ],
        AppTextField(
          label: i18n.t('shipment.weight'),
          controller: _weight,
          keyboardType: const TextInputType.numberWithOptions(decimal: true),
        ),
        const SizedBox(height: 12),
        AppTextField(
          label: i18n.t('shipment.volume'),
          hint: i18n.t('shipment.volumeHint'),
          controller: _volume,
          keyboardType: const TextInputType.numberWithOptions(decimal: true),
        ),
      ],
    );
  }

  bool _writeInTruckType() {
    final types = ref.read(truckTypesProvider);
    if (types.isLoading) return false;
    if (types.hasError) return true;
    final items = types.asData?.value ?? const <TruckTypeOption>[];
    if (items.isEmpty) return true;
    return _truckType == _otherTruckType;
  }

  String? _resolvedTruckType() {
    if (_writeInTruckType()) {
      final custom = _customTruckType.text.trim();
      return custom.isEmpty ? null : custom;
    }
    if (_truckType == null ||
        _truckType!.isEmpty ||
        _truckType == _otherTruckType) {
      return null;
    }
    return _truckType;
  }

  Widget _truckTypeField(I18nBundle i18n) {
    final types = ref.watch(truckTypesProvider);
    final missingChoice = _error == i18n.t('shipment.truckTypeRequired');
    final missingCustom = _error == i18n.t('shipment.customTruckTypeRequired');
    return types.when(
      loading: () => InputDecorator(
        decoration: InputDecoration(labelText: i18n.t('shipment.truckType')),
        child: Text(
          i18n.t('common.loading'),
          style: const TextStyle(color: AppColors.muted),
        ),
      ),
      error: (error, _) => Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            i18n.t('shipment.truckTypesFailed'),
            style: const TextStyle(color: AppColors.danger),
          ),
          const SizedBox(height: 8),
          Align(
            alignment: AlignmentDirectional.centerStart,
            child: AppButton(
              label: i18n.t('common.retry'),
              variant: AppButtonVariant.secondary,
              onPressed: () => ref.invalidate(truckTypesProvider),
            ),
          ),
          const SizedBox(height: 12),
          _customTruckTypeField(
            i18n,
            showError: missingCustom,
            label: i18n.t('shipment.truckType'),
          ),
        ],
      ),
      data: (items) {
        if (items.isEmpty) {
          return _customTruckTypeField(
            i18n,
            showError: missingCustom,
            label: i18n.t('shipment.truckType'),
          );
        }
        final writingCustom = _truckType == _otherTruckType;
        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            DropdownButtonFormField<String>(
              key: ValueKey(_truckType ?? 'unset'),
              initialValue: _truckType,
              isExpanded: true,
              hint: Text(i18n.t('shipment.chooseTruckType')),
              decoration: InputDecoration(
                labelText: i18n.t('shipment.truckType'),
                errorText: missingChoice ? _error : null,
              ),
              items: [
                for (final type in items)
                  DropdownMenuItem(
                    value: type.code,
                    child: Text(
                      type.displayName(i18n.locale.languageCode),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                DropdownMenuItem(
                  value: _otherTruckType,
                  child: Text(i18n.t('shipment.otherTruckType')),
                ),
              ],
              onChanged: _submitting
                  ? null
                  : (value) => setState(() {
                      _truckType = value;
                      if (_error == i18n.t('shipment.truckTypeRequired') ||
                          _error == i18n.t('shipment.customTruckTypeRequired')) {
                        _error = null;
                      }
                    }),
            ),
            if (writingCustom) ...[
              const SizedBox(height: 12),
              _customTruckTypeField(i18n, showError: missingCustom),
            ],
          ],
        );
      },
    );
  }

  Widget _customTruckTypeField(
    I18nBundle i18n, {
    required bool showError,
    String? label,
  }) {
    return AppTextField(
      label: label ?? i18n.t('shipment.customTruckType'),
      hint: i18n.t('shipment.customTruckTypeHint'),
      controller: _customTruckType,
      enabled: !_submitting,
      errorText: showError ? _error : null,
      onChanged: (_) {
        if (_error == i18n.t('shipment.customTruckTypeRequired') ||
            _error == i18n.t('shipment.truckTypeRequired')) {
          setState(() => _error = null);
        }
      },
    );
  }

  Widget _measureChip(String label, String value) {
    final selected = _quantityUnit == value;
    return Material(
      color: selected ? AppColors.navy : AppColors.white,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(10),
        side: BorderSide(color: selected ? AppColors.navy : AppColors.border),
      ),
      child: InkWell(
        onTap: () => setState(() => _quantityUnit = value),
        borderRadius: BorderRadius.circular(10),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
          child: Text(
            label,
            style: TextStyle(
              color: selected ? AppColors.white : AppColors.ink,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      ),
    );
  }

  Widget _routeFields(I18nBundle i18n) {
    return Column(
      children: [
        LocationPickerField(
          label: i18n.t('shipment.pickupAddress'),
          value: _pickup,
          i18n: i18n,
          onChanged: (value) => setState(() => _pickup = value),
        ),
        const SizedBox(height: 12),
        LocationPickerField(
          label: i18n.t('shipment.deliveryAddress'),
          value: _delivery,
          i18n: i18n,
          onChanged: (value) => setState(() => _delivery = value),
        ),
      ],
    );
  }

  Widget _scheduleFields(I18nBundle i18n) {
    final dateMissing = _requiredDate == null && _error != null;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _requiredDateField(i18n, showError: dateMissing),
        const SizedBox(height: 12),
        AppTextField(
          label: i18n.t('common.notes'),
          hint: i18n.t('shipment.notesHint'),
          controller: _notes,
          maxLines: 2,
        ),
        const SizedBox(height: 20),
        Row(
          children: [
            const Icon(
              Icons.account_balance_wallet_outlined,
              size: 20,
              color: AppColors.navy,
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                i18n.t('paymentContract.title'),
                style: Theme.of(context).textTheme.titleSmall
                    ?.copyWith(fontWeight: FontWeight.w700),
              ),
            ),
          ],
        ),
        const SizedBox(height: 4),
        Text(
          i18n.t('paymentContract.wizardHint'),
          style: Theme.of(context).textTheme.bodySmall
              ?.copyWith(color: AppColors.muted, height: 1.4),
        ),
        const SizedBox(height: 14),
        PaymentTermsFields(
          i18n: i18n,
          trigger: _billingTrigger,
          unit: _billingUnit,
          dueDays: _dueDays,
          referenceDate: _requiredDate,
          enabled: !_submitting,
          onTriggerChanged: (value) => setState(() => _billingTrigger = value),
          onUnitChanged: (value) => setState(() => _billingUnit = value),
          onDueDaysChanged: (value) => setState(() => _dueDays = value),
        ),
        const SizedBox(height: 16),
        Material(
          color: AppColors.surface,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
            side: const BorderSide(color: AppColors.border),
          ),
          clipBehavior: Clip.antiAlias,
          child: SwitchListTile(
            contentPadding: const EdgeInsetsDirectional.only(start: 14, end: 8),
            title: Text(
              i18n.t('shipment.publishNow'),
              style: const TextStyle(fontWeight: FontWeight.w600),
            ),
            subtitle: Text(
              i18n.t('shipment.publishHint'),
              style: const TextStyle(color: AppColors.muted, height: 1.35),
            ),
            value: _publish,
            onChanged: _submitting
                ? null
                : (value) => setState(() => _publish = value),
          ),
        ),
      ],
    );
  }

  Widget _requiredDateField(I18nBundle i18n, {required bool showError}) {
    final missing = _requiredDate == null;
    final value = missing
        ? i18n.t('shipment.chooseDate')
        : formatDate(_requiredDate, locale: i18n.locale.languageCode);
    return Semantics(
      button: true,
      enabled: !_submitting,
      label: '${i18n.t('shipment.requiredDate')}. $value',
      child: InkWell(
        onTap: _submitting ? null : _pickDate,
        excludeFromSemantics: true,
        borderRadius: BorderRadius.circular(12),
        child: ExcludeSemantics(
          child: InputDecorator(
            decoration: InputDecoration(
              labelText: i18n.t('shipment.requiredDate'),
              suffixIcon: Icon(
                Icons.calendar_today_outlined,
                color: missing ? AppColors.muted : AppColors.navy,
              ),
              errorText: showError ? _error : null,
            ),
            child: Text(
              value,
              style: TextStyle(
                color: missing ? AppColors.muted : AppColors.ink,
                fontWeight: missing ? FontWeight.w500 : FontWeight.w600,
              ),
            ),
          ),
        ),
      ),
    );
  }
}
