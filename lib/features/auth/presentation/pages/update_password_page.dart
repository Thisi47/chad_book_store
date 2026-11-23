import 'package:chad_book_store/features/auth/data/auth_repository.dart';
import 'package:chad_book_store/features/auth/presentation/auth_error_message.dart';
import 'package:chad_book_store/core/widgets/app_feedback.dart';
import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:go_router/go_router.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

class UpdatePasswordPage extends HookConsumerWidget {
  const UpdatePasswordPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final formKey = useMemoized(() => GlobalKey<FormState>());
    final passwordController = useTextEditingController();
    final confirmationController = useTextEditingController();
    final isPasswordVisible = useState(false);
    final isLoading = useState(false);

    Future<void> updatePassword() async {
      if (!formKey.currentState!.validate()) return;

      isLoading.value = true;
      try {
        await ref
            .read(authRepositoryProvider)
            .updatePassword(password: passwordController.text);
        if (context.mounted) context.go('/home');
      } catch (error) {
        if (context.mounted) {
          showAppMessage(context, authErrorMessage(error), isError: true);
        }
      } finally {
        if (context.mounted) isLoading.value = false;
      }
    }

    return Scaffold(
      appBar: AppBar(title: const Text('Nouveau mot de passe')),
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Form(
            key: formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const Text(
                  'Choisissez un nouveau mot de passe pour votre compte.',
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 24),
                TextFormField(
                  controller: passwordController,
                  obscureText: !isPasswordVisible.value,
                  decoration: InputDecoration(
                    labelText: 'Nouveau mot de passe',
                    border: const OutlineInputBorder(),
                    suffixIcon: IconButton(
                      onPressed: () {
                        isPasswordVisible.value = !isPasswordVisible.value;
                      },
                      icon: Icon(
                        isPasswordVisible.value
                            ? Icons.visibility
                            : Icons.visibility_off,
                      ),
                    ),
                  ),
                  validator: (value) {
                    if (value == null || value.length < 8) {
                      return 'Le mot de passe doit contenir au moins 8 caractères.';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: confirmationController,
                  obscureText: !isPasswordVisible.value,
                  decoration: const InputDecoration(
                    labelText: 'Confirmer le mot de passe',
                    border: OutlineInputBorder(),
                  ),
                  validator: (value) {
                    if (value != passwordController.text) {
                      return 'Les mots de passe ne correspondent pas.';
                    }
                    return null;
                  },
                  onFieldSubmitted: (_) =>
                      isLoading.value ? null : updatePassword(),
                ),
                const SizedBox(height: 24),
                FilledButton(
                  onPressed: isLoading.value ? null : updatePassword,
                  style: FilledButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                  ),
                  child: isLoading.value
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                            color: Colors.white,
                            strokeWidth: 2,
                          ),
                        )
                      : const Text('Enregistrer le mot de passe'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
