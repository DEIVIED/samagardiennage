import 'package:flutter/material.dart';

import '../controllers/habitants_controller.dart';
import '../models/app_user.dart';

class HabitantCreationView extends StatefulWidget {
  const HabitantCreationView({super.key, required this.controller});

  final HabitantsController controller;

  @override
  State<HabitantCreationView> createState() => _HabitantCreationViewState();
}

class _HabitantCreationViewState extends State<HabitantCreationView> {
  static const _navy = Color(0xFF172747);
  static const _gold = Color(0xFFF5A817);
  final _formKey = GlobalKey<FormState>();
  final _name = TextEditingController();
  final _email = TextEditingController();
  final _phone = TextEditingController();
  final _address = TextEditingController();
  final _quartier = TextEditingController(text: 'Quartier Medina');
  bool _saving = false;

  @override
  void dispose() {
    for (final controller in [_name, _email, _phone, _address, _quartier]) {
      controller.dispose();
    }
    super.dispose();
  }

  Future<void> _save() async {
    if (_saving || !_formKey.currentState!.validate()) return;
    final timestamp = DateTime.now().microsecondsSinceEpoch.toString();
    final id = timestamp;
    final habitant = AppUser(
      id: id,
      fullName: _name.text.trim(),
      email: _email.text.trim(),
      type: AppUserType.habitant,
      isActive: true,
      phone: _phone.text.trim(),
      address: _address.text.trim(),
      quartierId: _quartier.text.trim().toLowerCase().replaceAll(' ', '_'),
      quartierName: _quartier.text.trim(),
      qrCode: 'SAMA-HABITANT-$timestamp',
    );
    setState(() => _saving = true);
    try {
      await widget.controller.createHabitant(habitant);
      if (mounted) Navigator.of(context).pop(habitant);
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Impossible d'enregistrer l'habitant.")),
        );
      }
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF4F2EC),
      appBar: AppBar(
        backgroundColor: _navy,
        foregroundColor: Colors.white,
        title: const Text('Nouvel habitant'),
      ),
      body: SafeArea(
        child: Form(
          key: _formKey,
          child: ListView(
            padding: const EdgeInsets.all(20),
            children: [
              const Text(
                'Informations de l’habitant',
                style: TextStyle(
                  fontWeight: FontWeight.w900,
                  fontSize: 18,
                  color: _navy,
                ),
              ),
              const SizedBox(height: 18),
              _field(_name, 'Nom complet', required: true),
              _field(
                _phone,
                'Téléphone',
                keyboard: TextInputType.phone,
                required: true,
              ),
              _field(_email, 'E-mail', keyboard: TextInputType.emailAddress),
              _field(_address, 'Adresse', required: true),
              _field(_quartier, 'Quartier', required: true),
              const SizedBox(height: 22),
              FilledButton.icon(
                onPressed: _saving ? null : _save,
                style: FilledButton.styleFrom(
                  backgroundColor: _gold,
                  foregroundColor: _navy,
                  padding: const EdgeInsets.symmetric(vertical: 15),
                ),
                icon: _saving
                    ? const SizedBox.square(
                        dimension: 18,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Icon(Icons.person_add_alt_1),
                label: Text(_saving ? 'Enregistrement...' : 'Créer l’habitant'),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _field(
    TextEditingController controller,
    String label, {
    TextInputType? keyboard,
    bool required = false,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: TextFormField(
        controller: controller,
        keyboardType: keyboard,
        validator: required
            ? (value) => value == null || value.trim().isEmpty
                  ? '$label obligatoire'
                  : null
            : null,
        decoration: InputDecoration(
          labelText: label,
          filled: true,
          fillColor: Colors.white,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide.none,
          ),
        ),
      ),
    );
  }
}
