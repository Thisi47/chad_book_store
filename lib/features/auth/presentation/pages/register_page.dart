import 'package:chad_book_store/features/auth/data/auth_repository.dart';
import 'package:chad_book_store/features/auth/presentation/auth_error_message.dart';
import 'package:chad_book_store/core/widgets/app_feedback.dart';
import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:go_router/go_router.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

class RegisterPage extends HookConsumerWidget {
  const RegisterPage({super.key, this.returnTo});

  final String? returnTo;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final formKey = useMemoized(() => GlobalKey<FormState>());
    final emailController = useTextEditingController();
    final passwordController = useTextEditingController();
    final confirmationController = useTextEditingController();
    final isPasswordVisible = useState(false);
    final isLoading = useState(false);

    Future<void> createAccount() async {
      if (!formKey.currentState!.validate()) return;

      isLoading.value = true;
      try {
        final response = await ref
            .read(authRepositoryProvider)
            .signUp(
              email: emailController.text.trim(),
              password: passwordController.text,
            );
        if (!context.mounted) return;

        if (response.session != null) {
          context.go(_safeReturnTo(returnTo));
        } else {
          showAppMessage(
            context,
            'Compte créé. Confirmez votre adresse depuis le lien envoyé '
            'par e-mail (vérifiez aussi vos courriers indésirables) avant '
            'de vous connecter.',
          );
          context.go(
            Uri(
              path: '/login',
              queryParameters: {'returnTo': _safeReturnTo(returnTo)},
            ).toString(),
          );
        }
      } catch (error) {
        if (context.mounted) {
          showAppMessage(context, authErrorMessage(error), isError: true);
        }
      } finally {
        if (context.mounted) isLoading.value = false;
      }
    }

    return Scaffold(
      appBar: AppBar(title: const Text('Créer un compte')),
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Form(
            key: formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const Icon(Icons.person_add_alt_1, size: 64),
                const SizedBox(height: 16),
                Text(
                  'Rejoignez Chad Books',
                  textAlign: TextAlign.center,
                  style: Theme.of(context).textTheme.headlineSmall,
                ),
                const SizedBox(height: 24),
                TextFormField(
                  controller: emailController,
                  decoration: const InputDecoration(
                    labelText: 'E-mail',
                    border: OutlineInputBorder(),
                    prefixIcon: Icon(Icons.email_outlined),
                  ),
                  keyboardType: TextInputType.emailAddress,
                  textInputAction: TextInputAction.next,
                  autofillHints: const [AutofillHints.newUsername],
                  validator: _validateEmail,
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: passwordController,
                  obscureText: !isPasswordVisible.value,
                  decoration: InputDecoration(
                    labelText: 'Mot de passe',
                    border: const OutlineInputBorder(),
                    prefixIcon: const Icon(Icons.lock_outline),
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
                  textInputAction: TextInputAction.next,
                  autofillHints: const [AutofillHints.newPassword],
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
                    prefixIcon: Icon(Icons.lock_outline),
                  ),
                  textInputAction: TextInputAction.done,
                  validator: (value) {
                    if (value != passwordController.text) {
                      return 'Les mots de passe ne correspondent pas.';
                    }
                    return null;
                  },
                  onFieldSubmitted: (_) =>
                      isLoading.value ? null : createAccount(),
                ),
                const SizedBox(height: 24),
                FilledButton(
                  onPressed: isLoading.value ? null : createAccount,
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
                      : const Text('Créer mon compte'),
                ),
                TextButton(
                  onPressed: isLoading.value
                      ? null
                      : () => context.go(
                          Uri(
                            path: '/login',
                            queryParameters: {
                              'returnTo': _safeReturnTo(returnTo),
                            },
                          ).toString(),
                        ),
                  child: const Text('Déjà un compte ? Se connecter'),
                ),
              ],
            ),
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

String _safeReturnTo(String? path) {
  if (path == null ||
      !path.startsWith('/') ||
      path.startsWith('//') ||
      path.startsWith('/login')) {
    return '/home';
  }
  return path;
}
