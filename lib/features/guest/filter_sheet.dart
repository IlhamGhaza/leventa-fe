// ignore: deprecated_member_use, shortcut: GetX/plugins still use flutter/material types; migrate to material_ui when they do.
import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../app/theme.dart';
import '../../core/widgets/async_views.dart';
import '../../core/widgets/common.dart';
import '../master_data/master_data_repository.dart';
import '../properties/data/property_models.dart';
import '../properties/data/property_query.dart';

const sortLabels = {
  'newest': 'Terbaru',
  'oldest': 'Terlama',
  'price_asc': 'Harga terendah',
  'price_desc': 'Harga tertinggi',
  'name_asc': 'Nama A–Z',
  'name_desc': 'Nama Z–A',
};

/// Returns a new query (page 1) or null when dismissed.
Future<PropertyQuery?> showFilterSheet(BuildContext context, PropertyQuery q) =>
    showModalBottomSheet<PropertyQuery>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      builder: (_) => _FilterSheet(q),
    );

class _FilterSheet extends StatefulWidget {
  const _FilterSheet(this.initial);
  final PropertyQuery initial;

  @override
  State<_FilterSheet> createState() => _FilterSheetState();
}

class _FilterSheetState extends State<_FilterSheet> {
  final master = Get.find<MasterDataRepository>();
  late String? _tx = widget.initial.transactionType;
  late String? _type = widget.initial.type;
  late String? _province = widget.initial.provinceId;
  late String? _city = widget.initial.cityId;
  late String? _district = widget.initial.districtId;
  late final Set<String> _facilities = {...widget.initial.facilityIds};
  late String? _sort = widget.initial.sort;
  late int? _beds = widget.initial.bedrooms;
  late int? _baths = widget.initial.bathrooms;
  late final _minPrice = _ctrl(widget.initial.minPrice);
  late final _maxPrice = _ctrl(widget.initial.maxPrice);
  late final _minLand = _ctrl(widget.initial.minLandArea);
  late final _maxLand = _ctrl(widget.initial.maxLandArea);
  late final _minBuild = _ctrl(widget.initial.minBuildingArea);
  late final _maxBuild = _ctrl(widget.initial.maxBuildingArea);
  String? _error;

  static TextEditingController _ctrl(num? v) =>
      TextEditingController(text: v?.toString() ?? '');
  static num? _num(TextEditingController c) =>
      num.tryParse(c.text.replaceAll('.', '').trim());

  @override
  void dispose() {
    for (final c in [
      _minPrice,
      _maxPrice,
      _minLand,
      _maxLand,
      _minBuild,
      _maxBuild,
    ]) {
      c.dispose();
    }
    super.dispose();
  }

  void _apply() {
    final q = PropertyQuery(
      search: widget.initial.search,
      history: widget.initial.history,
      includeHistory: widget.initial.includeHistory,
      scope: widget.initial.scope,
      status: widget.initial.status,
      transactionType: _tx,
      type: _type,
      provinceId: _province,
      cityId: _city,
      districtId: _district,
      facilityIds: _facilities.toList(),
      minPrice: _num(_minPrice),
      maxPrice: _num(_maxPrice),
      minLandArea: _num(_minLand),
      maxLandArea: _num(_maxLand),
      minBuildingArea: _num(_minBuild),
      maxBuildingArea: _num(_maxBuild),
      bedrooms: _beds,
      bathrooms: _baths,
      sort: _sort,
    );
    final err = q.validate();
    if (err != null) return setState(() => _error = err);
    Navigator.pop(context, q);
  }

  Widget _choice<T>(
    String label,
    T? value,
    Map<T, String> options,
    ValueChanged<T?> onChanged,
  ) => Padding(
    padding: const EdgeInsets.only(bottom: Gap.m),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: context.t.labelLarge),
        const SizedBox(height: Gap.xs),
        Wrap(
          spacing: Gap.s,
          runSpacing: Gap.s,
          children: [
            ChoiceChip(
              label: const Text('Semua'),
              selected: value == null,
              onSelected: (_) => onChanged(null),
            ),
            for (final e in options.entries)
              ChoiceChip(
                label: Text(e.value),
                selected: value == e.key,
                onSelected: (_) => onChanged(e.key),
              ),
          ],
        ),
      ],
    ),
  );

  Widget _range(
    String label,
    TextEditingController min,
    TextEditingController max,
  ) => Padding(
    padding: const EdgeInsets.only(bottom: Gap.m),
    child: Row(
      children: [
        Expanded(
          child: TextField(
            controller: min,
            keyboardType: TextInputType.number,
            decoration: InputDecoration(labelText: '$label min'),
          ),
        ),
        const SizedBox(width: Gap.s),
        Expanded(
          child: TextField(
            controller: max,
            keyboardType: TextInputType.number,
            decoration: InputDecoration(labelText: '$label maks'),
          ),
        ),
      ],
    ),
  );

  Widget _dropdown(
    String label,
    String? value,
    Future<List<NamedRef>> Function(bool) load,
    ValueChanged<String?> onChanged, {
    Key? key,
  }) => Padding(
    padding: const EdgeInsets.only(bottom: Gap.m),
    child: AsyncLoader<List<NamedRef>>(
      key: key,
      load: load,
      builder: (context, items, _) => DropdownButtonFormField<String?>(
        initialValue: items.any((i) => i.id == value) ? value : null,
        isExpanded: true,
        decoration: InputDecoration(labelText: label),
        items: [
          const DropdownMenuItem(value: null, child: Text('Semua')),
          for (final i in items)
            DropdownMenuItem(
              value: i.id,
              child: Text(i.name, overflow: TextOverflow.ellipsis),
            ),
        ],
        onChanged: onChanged,
      ),
    ),
  );

  @override
  Widget build(BuildContext context) => Padding(
    padding: EdgeInsets.only(bottom: MediaQuery.viewInsetsOf(context).bottom),
    child: Readable(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(Gap.m, Gap.m, Gap.s, 0),
            child: Row(
              children: [
                Expanded(child: Text('Filter', style: context.t.titleLarge)),
                TextButton(
                  onPressed: () => Navigator.pop(
                    context,
                    PropertyQuery(
                      search: widget.initial.search,
                      history: widget.initial.history,
                      scope: widget.initial.scope,
                      status: widget.initial.status,
                    ),
                  ),
                  child: const Text('Reset'),
                ),
              ],
            ),
          ),
          Flexible(
            child: ListView(
              shrinkWrap: true,
              padding: const EdgeInsets.all(Gap.m),
              children: [
                _choice('Transaksi', _tx, const {
                  TransactionType.sale: 'Jual',
                  TransactionType.rent: 'Sewa',
                }, (v) => setState(() => _tx = v)),
                _choice('Tipe properti', _type, {
                  for (final t in PropertyType.all) t: PropertyType.label(t),
                }, (v) => setState(() => _type = v)),
                _range('Harga (Rp)', _minPrice, _maxPrice),
                _range('Luas tanah (m²)', _minLand, _maxLand),
                _range('Luas bangunan (m²)', _minBuild, _maxBuild),
                _dropdown(
                  'Provinsi',
                  _province,
                  (f) => master.provinces(force: f),
                  (v) => setState(() {
                    _province = v;
                    _city = null;
                    _district = null;
                  }),
                ),
                if (_province != null)
                  _dropdown(
                    'Kota/Kabupaten',
                    _city,
                    (f) => master.cities(_province, force: f),
                    (v) => setState(() {
                      _city = v;
                      _district = null;
                    }),
                    key: ValueKey('city-$_province'),
                  ),
                if (_city != null)
                  _dropdown(
                    'Kecamatan',
                    _district,
                    (f) => master.districts(_city, force: f),
                    (v) => setState(() => _district = v),
                    key: ValueKey('district-$_city'),
                  ),
                _choice('Kamar tidur (min)', _beds, const {
                  1: '1+',
                  2: '2+',
                  3: '3+',
                  4: '4+',
                }, (v) => setState(() => _beds = v)),
                _choice('Kamar mandi (min)', _baths, const {
                  1: '1+',
                  2: '2+',
                  3: '3+',
                }, (v) => setState(() => _baths = v)),
                Text('Fasilitas', style: context.t.labelLarge),
                const SizedBox(height: Gap.xs),
                AsyncLoader<List<NamedRef>>(
                  load: (f) => master.facilities(force: f),
                  builder: (context, items, _) => Wrap(
                    spacing: Gap.s,
                    runSpacing: Gap.s,
                    children: [
                      for (final f in items)
                        FilterChip(
                          label: Text(f.name),
                          selected: _facilities.contains(f.id),
                          onSelected: (on) => setState(() {
                            if (!on) {
                              _facilities.remove(f.id);
                            } else if (_facilities.length <
                                PropertyQuery.maxFacilities) {
                              _facilities.add(f.id);
                            }
                          }),
                        ),
                    ],
                  ),
                ),
                const SizedBox(height: Gap.m),
                _choice(
                  'Urutkan',
                  _sort,
                  sortLabels,
                  (v) => setState(() => _sort = v),
                ),
                if (_error != null)
                  Text(_error!, style: TextStyle(color: context.c.danger)),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(Gap.m),
            child: SizedBox(
              width: double.infinity,
              child: FilledButton(
                onPressed: _apply,
                child: const Text('Terapkan filter'),
              ),
            ),
          ),
        ],
      ),
    ),
  );
}
