// ignore: deprecated_member_use, shortcut: GetX/plugins still use flutter/material types; migrate to material_ui when they do.
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../app/theme.dart';
import '../../core/network/api_exception.dart';
import '../../core/widgets/async_views.dart';
import '../../core/widgets/common.dart';
import '../../core/widgets/state_views.dart';
import '../properties/data/property_models.dart';
import '../properties/data/property_repository.dart';

/// Owner PII — Primary Marketing only, fetched every time (never cached).
class OwnerScreen extends StatelessWidget {
  const OwnerScreen({super.key, required this.propertyId});
  final String propertyId;

  @override
  Widget build(BuildContext context) {
    final repo = Get.find<PropertyRepository>();
    return Scaffold(
      appBar: AppBar(title: const Text('Data pemilik')),
      body: AsyncLoader<Owner>(
        load: (_) => repo.owner(propertyId),
        builder: (context, owner, _) =>
            _OwnerForm(propertyId: propertyId, owner: owner),
      ),
    );
  }
}

class _OwnerForm extends StatefulWidget {
  const _OwnerForm({required this.propertyId, required this.owner});
  final String propertyId;
  final Owner owner;

  @override
  State<_OwnerForm> createState() => _OwnerFormState();
}

class _OwnerFormState extends State<_OwnerForm> {
  final _form = GlobalKey<FormState>();
  late final _name = TextEditingController(text: widget.owner.name);
  late final _phone = TextEditingController(text: widget.owner.phone ?? '');
  late final _email = TextEditingController(text: widget.owner.email ?? '');
  late final _address = TextEditingController(
    text: widget.owner.privateAddress ?? '',
  );
  Map<String, String> _errors = {};
  bool _busy = false;

  @override
  void dispose() {
    for (final c in [_name, _phone, _email, _address]) {
      c.dispose();
    }
    super.dispose();
  }

  Future<void> _save() async {
    if (!_form.currentState!.validate()) return;
    setState(() {
      _busy = true;
      _errors = {};
    });
    final messenger = ScaffoldMessenger.of(context);
    String? v(TextEditingController c) =>
        c.text.trim().isEmpty ? null : c.text.trim();
    try {
      await Get.find<PropertyRepository>().updateOwner(
        widget.propertyId,
        Owner(
          id: widget.owner.id,
          name: _name.text.trim(),
          phone: v(_phone),
          email: v(_email),
          privateAddress: v(_address),
        ),
      );
      messenger.showSnackBar(
        const SnackBar(content: Text('Data pemilik disimpan')),
      );
    } on ApiException catch (e) {
      setState(() => _errors = e.fieldErrors);
      messenger.showSnackBar(SnackBar(content: Text(errorText(e))));
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) => Form(
    key: _form,
    child: ListView(
      padding: const EdgeInsets.all(Gap.m),
      children: [
        Readable(
          maxWidth: 560,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Pill(
                label: 'Privat — hanya Marketing utama',
                icon: LucideIcons.lock,
                color: context.c.warning,
              ),
              const SizedBox(height: Gap.m),
              TextFormField(
                controller: _name,
                decoration: InputDecoration(
                  labelText: 'Nama pemilik *',
                  errorText: _errors['name'],
                ),
                validator: (s) =>
                    (s ?? '').trim().isEmpty ? 'Nama wajib diisi.' : null,
              ),
              const SizedBox(height: Gap.m),
              TextFormField(
                controller: _phone,
                keyboardType: TextInputType.phone,
                decoration: InputDecoration(
                  labelText: 'Telepon',
                  errorText: _errors['phone'],
                ),
              ),
              const SizedBox(height: Gap.m),
              TextFormField(
                controller: _email,
                keyboardType: TextInputType.emailAddress,
                decoration: InputDecoration(
                  labelText: 'Email',
                  errorText: _errors['email'],
                ),
              ),
              const SizedBox(height: Gap.m),
              TextFormField(
                controller: _address,
                maxLines: 3,
                decoration: InputDecoration(
                  labelText: 'Alamat pribadi',
                  errorText: _errors['private_address'],
                ),
              ),
              const SizedBox(height: Gap.l),
              FilledButton(
                onPressed: _busy ? null : _save,
                child: Text(_busy ? 'Menyimpan…' : 'Simpan data pemilik'),
              ),
            ],
          ),
        ),
      ],
    ),
  );
}
