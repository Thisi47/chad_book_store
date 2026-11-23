import 'package:chad_book_store/features/profile/data/profile_repository.dart';
import 'package:chad_book_store/core/theme/theme_controller.dart';
import 'package:chad_book_store/core/widgets/app_feedback.dart';
import 'package:chad_book_store/core/widgets/app_bottom_navigation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class ProfilePage extends ConsumerStatefulWidget {
  const ProfilePage({super.key});

  @override
  ConsumerState<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends ConsumerState<ProfilePage> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _nameController;
  late final TextEditingController _phoneController;
  late final TextEditingController _emailController;
  String? _avatarUrl;
  bool _isSaving = false;
  bool _isUploading = false;

  @override
  void initState() {
    super.initState();
    final metadata =
        Supabase.instance.client.auth.currentUser?.userMetadata ?? {};
    _nameController = TextEditingController(
      text: metadata['full_name']?.toString() ?? '',
    );
    _phoneController = TextEditingController(
      text: metadata['phone']?.toString() ?? '',
    );
    _emailController = TextEditingController(
      text: Supabase.instance.client.auth.currentUser?.email ?? '',
    );
    _avatarUrl = metadata['avatar_url']?.toString();
  }

  @override
  void dispose() {
    _nameController.dispose();
    _phoneController.dispose();
    _emailController.dispose();
    super.dispose();
  }

  Future<void> _pickAvatar() async {
    setState(() => _isUploading = true);
    try {
      final image = await ImagePicker().pickImage(
        source: ImageSource.gallery,
        imageQuality: 85,
      );
      if (image == null) return;

      final url = await ref
          .read(profileRepositoryProvider)
          .uploadAvatar(bytes: await image.readAsBytes(), fileName: image.name);
      if (mounted) setState(() => _avatarUrl = url);
      _showMessage('Photo de profil mise à jour.');
    } catch (error) {
      _showMessage('Impossible d’ajouter la photo : $error', isError: true);
    } finally {
      if (mounted) setState(() => _isUploading = false);
    }
  }

  Future<void> _saveProfile() async {
    if (!_formKey.currentState!.validate()) return;

    final emailChanged =
        _emailController.text.trim() !=
        Supabase.instance.client.auth.currentUser?.email;
    setState(() => _isSaving = true);
    try {
      await ref
          .read(profileRepositoryProvider)
          .updateProfile(
            fullName: _nameController.text,
            phone: _phoneController.text,
            email: _emailController.text,
          );
      _showMessage(
        emailChanged
            ? 'Profil mis à jour. Confirmez le changement via le lien envoyé à votre nouvelle adresse e-mail.'
            : 'Profil mis à jour.',
      );
    } catch (error) {
      _showMessage('Impossible de modifier le profil : $error', isError: true);
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  void _showMessage(String message, {bool isError = false}) {
    if (!mounted) return;
    showAppMessage(context, message, isError: isError);
  }

  @override
  Widget build(BuildContext context) {
    final user = Supabase.instance.client.auth.currentUser;
    final themeMode = ref.watch(themeModeProvider);
    return Scaffold(
      appBar: AppBar(title: const Text('Mon profil')),
      bottomNavigationBar: const AppBottomNavigation(selectedIndex: 3),
      body: user == null
          ? const Center(child: Text('Connectez-vous pour voir votre profil.'))
          : SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 32),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Center(
                      child: Stack(
                        alignment: Alignment.bottomRight,
                        children: [
                          CircleAvatar(
                            radius: 56,
                            backgroundImage: _avatarUrl == null
                                ? null
                                : NetworkImage(_avatarUrl!),
                            child: _avatarUrl == null
                                ? const Icon(Icons.person, size: 56)
                                : null,
                          ),
                          IconButton.filled(
                            tooltip: 'Ajouter une photo',
                            onPressed: _isUploading ? null : _pickAvatar,
                            icon: _isUploading
                                ? const SizedBox(
                                    width: 18,
                                    height: 18,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                    ),
                                  )
                                : const Icon(Icons.camera_alt),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 28),
                    Text(
                      'Mes informations',
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: 14),
                    TextFormField(
                      controller: _nameController,
                      decoration: const InputDecoration(
                        labelText: 'Nom complet',
                        border: OutlineInputBorder(),
                        prefixIcon: Icon(Icons.person_outline),
                      ),
                      textCapitalization: TextCapitalization.words,
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: _phoneController,
                      decoration: const InputDecoration(
                        labelText: 'Téléphone',
                        border: OutlineInputBorder(),
                        prefixIcon: Icon(Icons.phone_outlined),
                      ),
                      keyboardType: TextInputType.phone,
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: _emailController,
                      decoration: const InputDecoration(
                        labelText: 'Adresse e-mail',
                        border: OutlineInputBorder(),
                        prefixIcon: Icon(Icons.email_outlined),
                      ),
                      keyboardType: TextInputType.emailAddress,
                      validator: _validateEmail,
                    ),
                    const SizedBox(height: 24),
                    Text(
                      'Personnalisation',
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: 10),
                    Card(
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'Apparence',
                              style: TextStyle(fontWeight: FontWeight.w700),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              'Choisissez le confort visuel qui vous convient.',
                              style: TextStyle(
                                color: Theme.of(
                                  context,
                                ).colorScheme.onSurfaceVariant,
                                fontSize: 13,
                              ),
                            ),
                            const SizedBox(height: 14),
                            DropdownButtonFormField<ThemeMode>(
                              key: ValueKey(themeMode),
                              initialValue: themeMode,
                              isExpanded: true,
                              decoration: const InputDecoration(
                                prefixIcon: Icon(Icons.contrast_outlined),
                                border: OutlineInputBorder(),
                              ),
                              items: const [
                                DropdownMenuItem(
                                  value: ThemeMode.system,
                                  child: Text('Automatique'),
                                ),
                                DropdownMenuItem(
                                  value: ThemeMode.light,
                                  child: Text('Clair'),
                                ),
                                DropdownMenuItem(
                                  value: ThemeMode.dark,
                                  child: Text('Sombre'),
                                ),
                              ],
                              onChanged: (mode) {
                                if (mode != null) {
                                  ref
                                      .read(themeModeProvider.notifier)
                                      .setMode(mode);
                                }
                              },
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 24),
                    FilledButton(
                      onPressed: _isSaving ? null : _saveProfile,
                      child: _isSaving
                          ? const SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                          : const Text('Enregistrer les modifications'),
                    ),
                  ],
                ),
              ),
            ),
    );
  }
}

String? _validateEmail(String? value) {
  final email = value?.trim() ?? '';
  if (!RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$').hasMatch(email)) {
    return 'Saisissez une adresse e-mail valide.';
  }
  return null;
}
