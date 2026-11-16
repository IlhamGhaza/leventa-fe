// ignore: deprecated_member_use, shortcut: GetX/plugins still use flutter/material types; migrate to material_ui when they do.
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../app/theme.dart';
import '../../core/network/api_exception.dart';
import '../../core/utils/format.dart';
import '../../core/widgets/async_views.dart';
import '../../core/widgets/common.dart';
import '../../core/widgets/state_views.dart';
import '../documents/document_rules.dart';
import '../master_data/master_data_repository.dart';
import '../properties/data/property_models.dart';
import '../properties/data/property_repository.dart';
import '../properties/property_detail_screen.dart';

/// Create (Marketing → becomes Primary) or edit (Primary only) a listing.
/// Owner details are part of create only; edit them on the owner screen.
class ListingForm extends StatefulWidget {
  const ListingForm({super.key, this.existing});
  final PrimaryProperty? existing;

  @override
  State<ListingForm> createState() => _ListingFormState();
}

class _ListingFormState extends State<ListingForm> {
  final _form = GlobalKey<FormState>();
  final master = Get.find<MasterDataRepository>();
  final repo = Get.find<PropertyRepository>();
  final _c = <String, TextEditingController>{};
  late final PropertyDetails _d;
  late String _type;
  late String _tx;
  String _status = PropertyStatus.available;
  String? _province, _city, _district;
  late final Set<String> _facilities;
  Map<String, String> _serverErrors = {};
  bool _busy = false;

  bool get _isEdit => widget.existing != null;

  TextEditingController _ctl(String key) =>
      _c.putIfAbsent(key, TextEditingController.new);

  @override
  void initState() {
    super.initState();
    final p = widget.existing;
    _type = p?.type ?? PropertyType.house;
    _tx = p?.transactionType ?? TransactionType.sale;
    _province = p?.province?.id;
    _city = p?.city?.id;
    _district = p?.district?.id;
    _facilities = {...?p?.facilities.map((f) => f.id)};
    // Copy so cancelling the form never mutates the cached projection.
    _d = p == null
        ? PropertyDetails()
        : PropertyDetails.fromJson(p.details.toJson());
    String? s(num? v) => v?.toString();
    final values = <String, String?>{
      'name': p?.name,
      'code': p?.code,
      'price': s(p?.price),
      'rental_price': s(p?.rentalPrice),
      'description': p?.description,
      'general_location': p?.generalLocation,
      'land_area': s(p?.landArea),
      'building_area': s(p?.buildingArea),
      'floor': s(p?.floor),
      'bedrooms': p == null ? null : '${p.bedrooms}',
      'bathrooms': p == null ? null : '${p.bathrooms}',
      'year_built': s(p?.yearBuilt),
      'block_number': p?.address.blockNumber,
      'cluster_name': p?.address.clusterName,
      'street_name': p?.address.streetName,
      'house_number': p?.address.houseNumber,
      'floor_number': p?.address.floorNumber,
      'room_number': p?.address.roomNumber,
      'latitude': s(p?.latitude),
      'longitude': s(p?.longitude),
      'short_description': _d.shortDescription,
      'area_label': _d.areaLabel,
      'sub_district': _d.subDistrict,
      'postal_code': _d.postalCode,
      'orientation': _d.orientation,
      'maintenance_fee': s(_d.maintenanceFee),
      'electricity_capacity': _d.electricityCapacity,
      'air_conditioners': '${_d.airConditioners}',
      'tv_provider': _d.tvProvider,
      'water_source': _d.waterSource,
      for (final k in PropertyDetails.roomKeys) k: '${_d.rooms[k] ?? 0}',
      for (final k in PropertyDetails.distanceKeys) k: s(_d.distances[k]),
    };
    values.forEach((k, v) => _ctl(k).text = v ?? '');
  }

  @override
  void dispose() {
    for (final c in _c.values) {
      c.dispose();
    }
    super.dispose();
  }

  String? _str(String k) {
    final v = _ctl(k).text.trim();
    return v.isEmpty ? null : v;
  }

  num? _num(String k) => num.tryParse((_str(k) ?? '').replaceAll(',', '.'));
  int? _int(String k) => int.tryParse(_str(k) ?? '');

  Map<String, dynamic> _body() {
    _d
      ..shortDescription = _str('short_description')
      ..areaLabel = _str('area_label')
      ..subDistrict = _str('sub_district')
      ..postalCode = _str('postal_code')
      ..orientation = _str('orientation')
      ..maintenanceFee = _num('maintenance_fee')?.toDouble()
      ..electricityCapacity = _str('electricity_capacity')
      ..airConditioners = _int('air_conditioners') ?? 0
      ..tvProvider = _str('tv_provider')
      ..waterSource = _str('water_source');
    for (final k in PropertyDetails.roomKeys) {
      _d.rooms[k] = _int(k) ?? 0;
    }
    for (final k in PropertyDetails.distanceKeys) {
      _d.distances[k] = _int(k);
    }
    // A cert flag may be true only for types that apply to this property type.
    for (final k in PropertyDetails.certKeys) {
      if (!DocumentRules.applies(_type, k)) _d.certs[k] = false;
    }
    final body = <String, dynamic>{
      'name': _str('name'),
      'type': _type,
      'transaction_type': _tx,
      if (_tx == TransactionType.sale)
        'price': _num('price')
      else
        'rental_price': _num('rental_price'),
      'description': _str('description') ?? '',
      'general_location': _str('general_location') ?? '',
      'province_id': _province,
      'city_id': _city,
      'district_id': _district,
      'facility_ids': _facilities.toList(),
      'land_area': _num('land_area'),
      'building_area': _num('building_area'),
      'floor': _int('floor'),
      'bedrooms': _int('bedrooms') ?? 0,
      'bathrooms': _int('bathrooms') ?? 0,
      'year_built': _int('year_built'),
      for (final k in const [
        'block_number',
        'cluster_name',
        'street_name',
        'house_number',
        'floor_number',
        'room_number',
      ])
        k: _str(k) ?? '',
      'latitude': _num('latitude'),
      'longitude': _num('longitude'),
      ..._d.toJson(),
    };
    if (!_isEdit) {
      body['code'] = _str('code');
      body['status'] = _status;
      body['owner'] = {
        'name': _str('owner_name'),
        'email': ?_str('owner_email'),
        'phone': ?_str('owner_phone'),
        'private_address': ?_str('owner_address'),
      };
      body.removeWhere((_, v) => v == null);
    } else {
      // Unset location ids must not be sent as null on PATCH.
      for (final k in const ['province_id', 'city_id', 'district_id']) {
        if (body[k] == null) body.remove(k);
      }
    }
    return body;
  }

  Future<void> _submit() async {
    setState(() => _serverErrors = {});
    if (!_form.currentState!.validate()) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Periksa kembali isian yang ditandai.')),
      );
      return;
    }
    setState(() => _busy = true);
    try {
      if (_isEdit) {
        await repo.update(widget.existing!.id, _body());
        if (!mounted) return;
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('Listing disimpan')));
        Get.back(result: true);
      } else {
        final created = await repo.create(_body());
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Listing dibuat. Tambahkan foto dan dokumen.'),
          ),
        );
        Get.off(() => PropertyDetailScreen(id: created.id));
      }
    } on ApiException catch (e) {
      if (!mounted) return;
      setState(() => _serverErrors = e.fieldErrors);
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(errorText(e))));
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  // ---- field helpers -----------------------------------------------------

  Widget _text(
    String key,
    String label, {
    bool required = false,
    bool number = false,
    bool decimal = false,
    int maxLines = 1,
    int? maxLength,
    String? helper,
    String? Function(String)? validate,
  }) => TextFormField(
    controller: _ctl(key),
    maxLines: maxLines,
    maxLength: maxLength,
    keyboardType: number
        ? TextInputType.numberWithOptions(decimal: decimal, signed: decimal)
        : (maxLines > 1 ? TextInputType.multiline : TextInputType.text),
    decoration: InputDecoration(
      labelText: required ? '$label *' : label,
      helperText: helper,
      errorText: _serverErrors[key],
    ),
    validator: (v) {
      final s = (v ?? '').trim();
      if (required && s.isEmpty) return '$label wajib diisi.';
      if (s.isNotEmpty &&
          number &&
          num.tryParse(s.replaceAll(',', '.')) == null) {
        return 'Harus berupa angka.';
      }
      if (s.isNotEmpty && number && !decimal && (num.tryParse(s) ?? 0) < 0) {
        return 'Tidak boleh negatif.';
      }
      return validate?.call(s);
    },
  );

  Widget _extraTile(String name, String? value, VoidCallback onRemove) =>
      ListTile(
        contentPadding: EdgeInsets.zero,
        title: Text(name),
        subtitle: value == null ? null : Text(value),
        trailing: IconButton(
          tooltip: 'Hapus $name',
          icon: const Icon(LucideIcons.x),
          onPressed: onRemove,
        ),
      );

  Widget _addExtraButton(String label, int count, VoidCallback onTap) {
    final full = count >= PropertyDetails.maxExtras;
    return Align(
      alignment: Alignment.centerLeft,
      child: TextButton.icon(
        onPressed: full ? null : onTap,
        icon: const Icon(LucideIcons.plus),
        label: Text(
          full ? 'Maksimal ${PropertyDetails.maxExtras} item' : label,
        ),
      ),
    );
  }

  Future<void> _addExtra({required bool withMeters}) async {
    final taken = withMeters
        ? _d.extraDistances.map((p) => p.name)
        : _d.extraOutdoor;
    final res = await showDialog<NearbyPlace>(
      context: context,
      builder: (_) => _ExtraDialog(
        withMeters: withMeters,
        taken: {for (final n in taken) n.toLowerCase()},
      ),
    );
    if (res == null || !mounted) return;
    setState(
      () => withMeters
          ? _d.extraDistances.add(res)
          : _d.extraOutdoor.add(res.name),
    );
  }

  Widget _section(String title, List<Widget> fields, {String? note}) => Padding(
    padding: const EdgeInsets.only(bottom: Gap.l),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Semantics(
          header: true,
          child: Text(title, style: context.t.titleMedium),
        ),
        if (note != null)
          Padding(
            padding: const EdgeInsets.only(top: Gap.xs),
            child: Text(note, style: context.t.bodySmall),
          ),
        const SizedBox(height: Gap.m),
        LayoutBuilder(
          builder: (context, box) {
            final cols = box.maxWidth >= 640 ? 2 : 1;
            final w = (box.maxWidth - Gap.m * (cols - 1)) / cols;
            return Wrap(
              spacing: Gap.m,
              runSpacing: Gap.m,
              children: [for (final f in fields) SizedBox(width: w, child: f)],
            );
          },
        ),
      ],
    ),
  );

  Widget _locationDropdown(
    String label,
    String? value,
    Future<List<NamedRef>> Function(bool) load,
    ValueChanged<String?> onChanged, {
    Key? key,
  }) => AsyncLoader<List<NamedRef>>(
    key: key,
    load: load,
    builder: (context, items, _) => DropdownButtonFormField<String?>(
      initialValue: items.any((i) => i.id == value) ? value : null,
      isExpanded: true,
      decoration: InputDecoration(
        labelText: label,
        errorText: _serverErrors['${label.toLowerCase()}_id'],
      ),
      items: [
        const DropdownMenuItem(value: null, child: Text('Pilih')),
        for (final i in items)
          DropdownMenuItem(
            value: i.id,
            child: Text(i.name, overflow: TextOverflow.ellipsis),
          ),
      ],
      onChanged: onChanged,
    ),
  );

  @override
  Widget build(BuildContext context) {
    final certTypes = DocumentRules.typesFor(_type);
    return Scaffold(
      appBar: AppBar(title: Text(_isEdit ? 'Edit listing' : 'Listing baru')),
      // Sticky so saving never needs a scroll to the end of a long form.
      bottomNavigationBar: DecoratedBox(
        decoration: BoxDecoration(
          color: context.c.surface,
          border: Border(top: BorderSide(color: context.c.border)),
        ),
        child: SafeArea(
          minimum: const EdgeInsets.all(Gap.m),
          child: Center(
            heightFactor: 1,
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 900),
              child: SizedBox(
                width: double.infinity,
                child: FilledButton(
                  onPressed: _busy ? null : _submit,
                  child: Text(
                    _busy
                        ? 'Menyimpan…'
                        : (_isEdit ? 'Simpan perubahan' : 'Buat listing'),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
      body: Form(
        key: _form,
        child: ListView(
          padding: const EdgeInsets.all(Gap.m),
          children: [
            Readable(
              maxWidth: 900,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  _section('Informasi utama', [
                    _text('name', 'Judul listing', required: true),
                    if (!_isEdit) _text('code', 'Kode listing', required: true),
                    DropdownButtonFormField<String>(
                      initialValue: _type,
                      decoration: const InputDecoration(
                        labelText: 'Tipe properti *',
                      ),
                      items: [
                        for (final t in PropertyType.all)
                          DropdownMenuItem(
                            value: t,
                            child: Text(PropertyType.label(t)),
                          ),
                      ],
                      onChanged: (v) => setState(() => _type = v!),
                    ),
                    SegmentedButton<String>(
                      segments: const [
                        ButtonSegment(
                          value: TransactionType.sale,
                          label: Text('Jual'),
                        ),
                        ButtonSegment(
                          value: TransactionType.rent,
                          label: Text('Sewa'),
                        ),
                      ],
                      selected: {_tx},
                      onSelectionChanged: (s) => setState(() => _tx = s.first),
                    ),
                    if (_tx == TransactionType.sale)
                      _text(
                        'price',
                        'Harga jual (Rp)',
                        required: true,
                        number: true,
                        validate: (s) => (num.tryParse(s) ?? 0) <= 0
                            ? 'Harga harus lebih dari 0.'
                            : null,
                      )
                    else
                      _text(
                        'rental_price',
                        'Harga sewa (Rp)',
                        required: true,
                        number: true,
                        validate: (s) => (num.tryParse(s) ?? 0) <= 0
                            ? 'Harga harus lebih dari 0.'
                            : null,
                      ),
                    if (!_isEdit)
                      DropdownButtonFormField<String>(
                        initialValue: _status,
                        isExpanded: true,
                        decoration: const InputDecoration(
                          labelText: 'Status awal',
                        ),
                        items: const [
                          DropdownMenuItem(
                            value: PropertyStatus.available,
                            child: Text('Tersedia (publik)'),
                          ),
                          DropdownMenuItem(
                            value: PropertyStatus.draft,
                            child: Text('Draf (tidak publik)'),
                          ),
                        ],
                        onChanged: (v) => setState(() => _status = v!),
                      ),
                    _text(
                      'short_description',
                      'Deskripsi singkat',
                      maxLines: 3,
                      maxLength: 500,
                    ),
                    _text('description', 'Deskripsi lengkap', maxLines: 6),
                  ]),
                  _section(
                    'Lokasi umum',
                    note: 'Terlihat publik. Jangan isi alamat lengkap di sini.',
                    [
                      _locationDropdown(
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
                        _locationDropdown(
                          'Kota/Kabupaten',
                          _city,
                          (f) => master.cities(_province, force: f),
                          (v) => setState(() {
                            _city = v;
                            _district = null;
                          }),
                          key: ValueKey('c$_province'),
                        ),
                      if (_city != null)
                        _locationDropdown(
                          'Kecamatan',
                          _district,
                          (f) => master.districts(_city, force: f),
                          (v) => setState(() => _district = v),
                          key: ValueKey('d$_city'),
                        ),
                      _text('sub_district', 'Kelurahan'),
                      _text(
                        'postal_code',
                        'Kode pos',
                        number: true,
                        maxLength: 10,
                      ),
                      _text(
                        'area_label',
                        'Label area',
                        helper: 'Contoh: Kota Wisata Cibubur',
                      ),
                      _text('general_location', 'Lokasi umum'),
                    ],
                  ),
                  _section(
                    'Alamat lengkap (privat)',
                    note: 'Hanya terlihat oleh Marketing utama dan co-listing.',
                    [
                      _text('cluster_name', 'Nama cluster'),
                      _text('block_number', 'Blok'),
                      _text('street_name', 'Jalan'),
                      _text('house_number', 'Nomor rumah'),
                      _text('floor_number', 'Lantai unit'),
                      _text('room_number', 'Nomor unit'),
                      _text(
                        'latitude',
                        'Latitude',
                        number: true,
                        decimal: true,
                        validate: (s) =>
                            s.isEmpty || ((num.tryParse(s) ?? 999).abs() <= 90)
                            ? null
                            : 'Latitude -90 sampai 90.',
                      ),
                      _text(
                        'longitude',
                        'Longitude',
                        number: true,
                        decimal: true,
                        validate: (s) =>
                            s.isEmpty || ((num.tryParse(s) ?? 999).abs() <= 180)
                            ? null
                            : 'Longitude -180 sampai 180.',
                      ),
                    ],
                  ),
                  _section('Data & keterangan', [
                    _text(
                      'land_area',
                      'Luas tanah (m²)',
                      number: true,
                      decimal: true,
                    ),
                    _text(
                      'building_area',
                      'Luas bangunan (m²)',
                      number: true,
                      decimal: true,
                    ),
                    _text('floor', 'Jumlah lantai', number: true),
                    _text('bedrooms', 'Kamar tidur', number: true),
                    _text('bathrooms', 'Kamar mandi', number: true),
                    _text('year_built', 'Tahun dibangun', number: true),
                    _text('orientation', 'Menghadap', helper: 'Contoh: Timur'),
                    _text(
                      'maintenance_fee',
                      'Biaya pemeliharaan / bulan (Rp)',
                      number: true,
                    ),
                  ]),
                  _section(
                    'Dokumen kepemilikan',
                    note:
                        'Centang dokumen yang dimiliki. Dokumen hanya bisa diunggah jika dicentang, dan centang tidak bisa dihapus selama dokumennya ada.',
                    [
                      for (final k in certTypes)
                        CheckboxListTile(
                          contentPadding: EdgeInsets.zero,
                          title: Text(DocumentRules.label(k)),
                          value: _d.certs[k] ?? false,
                          onChanged: (v) =>
                              setState(() => _d.certs[k] = v ?? false),
                        ),
                    ],
                  ),
                  _section('Spesifikasi ruangan', [
                    for (final e in PropertySections.roomLabels.entries)
                      _text(e.key, e.value, number: true),
                  ]),
                  _section('Fasilitas', [
                    _text(
                      'electricity_capacity',
                      'Daya listrik',
                      helper: 'Contoh: 2200 VA',
                    ),
                    _text('air_conditioners', 'Jumlah AC', number: true),
                    _text('tv_provider', 'TV / provider'),
                    _text('water_source', 'Sumber air', helper: 'Contoh: PAM'),
                    DropdownButtonFormField<String?>(
                      initialValue: _d.furnishingStatus,
                      decoration: const InputDecoration(labelText: 'Perabot'),
                      items: [
                        const DropdownMenuItem(
                          value: null,
                          child: Text('Tidak diisi'),
                        ),
                        for (final e
                            in PropertySections.furnishingLabels.entries)
                          DropdownMenuItem(value: e.key, child: Text(e.value)),
                      ],
                      onChanged: (v) => setState(() => _d.furnishingStatus = v),
                    ),
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
                              onSelected: (on) => setState(
                                () => on
                                    ? _facilities.add(f.id)
                                    : _facilities.remove(f.id),
                              ),
                            ),
                        ],
                      ),
                    ),
                  ]),
                  _section('Area luar', [
                    for (final e in PropertySections.outdoorLabels.entries)
                      SwitchListTile(
                        contentPadding: EdgeInsets.zero,
                        title: Text(e.value),
                        value: _d.outdoor[e.key] ?? false,
                        onChanged: (v) => setState(() => _d.outdoor[e.key] = v),
                      ),
                    for (final n in _d.extraOutdoor)
                      _extraTile(
                        n,
                        null,
                        () => setState(() => _d.extraOutdoor.remove(n)),
                      ),
                    _addExtraButton(
                      'Tambah area luar lain',
                      _d.extraOutdoor.length,
                      () => _addExtra(withMeters: false),
                    ),
                  ]),
                  _section('Jarak ke fasilitas umum (meter)', [
                    for (final e in PropertySections.distanceLabels.entries)
                      _text(e.key, e.value, number: true),
                    for (final pl in _d.extraDistances)
                      _extraTile(
                        pl.name,
                        Fmt.distance(pl.meters),
                        () => setState(() => _d.extraDistances.remove(pl)),
                      ),
                    _addExtraButton(
                      'Tambah fasilitas umum lain',
                      _d.extraDistances.length,
                      () => _addExtra(withMeters: true),
                    ),
                  ]),
                  if (!_isEdit)
                    _section(
                      'Data pemilik (privat)',
                      note:
                          'Hanya Anda sebagai Marketing utama yang dapat melihat data ini.',
                      [
                        _text('owner_name', 'Nama pemilik', required: true),
                        _text('owner_phone', 'Telepon pemilik'),
                        _text(
                          'owner_email',
                          'Email pemilik',
                          validate: (s) => s.isEmpty || s.contains('@')
                              ? null
                              : 'Format email tidak valid.',
                        ),
                        _text(
                          'owner_address',
                          'Alamat pribadi pemilik',
                          maxLines: 2,
                        ),
                      ],
                    ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Asks for a custom outdoor area (name) or nearby place (name + meters).
class _ExtraDialog extends StatefulWidget {
  const _ExtraDialog({required this.withMeters, required this.taken});
  final bool withMeters;
  final Set<String> taken;

  @override
  State<_ExtraDialog> createState() => _ExtraDialogState();
}

class _ExtraDialogState extends State<_ExtraDialog> {
  final _key = GlobalKey<FormState>();
  final _name = TextEditingController();
  final _meters = TextEditingController();

  @override
  void dispose() {
    _name.dispose();
    _meters.dispose();
    super.dispose();
  }

  void _save() {
    if (!_key.currentState!.validate()) return;
    Navigator.pop(
      context,
      NearbyPlace(_name.text.trim(), int.tryParse(_meters.text.trim()) ?? 0),
    );
  }

  @override
  Widget build(BuildContext context) => AlertDialog(
    title: Text(
      widget.withMeters ? 'Tambah fasilitas umum' : 'Tambah area luar',
    ),
    content: Form(
      key: _key,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          TextFormField(
            controller: _name,
            autofocus: true,
            maxLength: 50,
            textCapitalization: TextCapitalization.sentences,
            textInputAction: widget.withMeters
                ? TextInputAction.next
                : TextInputAction.done,
            onFieldSubmitted: widget.withMeters ? null : (_) => _save(),
            decoration: InputDecoration(
              labelText: widget.withMeters ? 'Nama fasilitas' : 'Nama area',
              helperText: widget.withMeters
                  ? 'Contoh: Pasar, Masjid'
                  : 'Contoh: Rooftop, Gazebo',
            ),
            validator: (v) {
              final s = (v ?? '').trim();
              if (s.isEmpty) return 'Nama wajib diisi.';
              if (widget.taken.contains(s.toLowerCase())) {
                return 'Sudah ada di daftar.';
              }
              return null;
            },
          ),
          if (widget.withMeters)
            TextFormField(
              controller: _meters,
              keyboardType: TextInputType.number,
              textInputAction: TextInputAction.done,
              onFieldSubmitted: (_) => _save(),
              decoration: const InputDecoration(labelText: 'Jarak (meter)'),
              validator: (v) {
                final m = int.tryParse((v ?? '').trim());
                return m == null || m < 0 || m > 1000000
                    ? 'Isi angka 0–1.000.000.'
                    : null;
              },
            ),
        ],
      ),
    ),
    actions: [
      TextButton(
        onPressed: () => Navigator.pop(context),
        child: const Text('Batal'),
      ),
      FilledButton(onPressed: _save, child: const Text('Tambah')),
    ],
  );
}
