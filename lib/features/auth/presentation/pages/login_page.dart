import 'package:chad_book_store/features/auth/data/auth_repository.dart';
import 'package:chad_book_store/features/auth/presentation/auth_error_message.dart';
import 'package:chad_book_store/core/widgets/app_feedback.dart';
import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:go_router/go_router.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

class LoginPage extends HookConsumerWidget {
  const LoginPage({super.key, this.authErrorCode, this.returnTo});

  final String? authErrorCode;
  final String? returnTo;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final emailController = useTextEditingController();
    final passwordController = useTextEditingController();
    final formKey = useMemoized(() => GlobalKey<FormState>());
    final isPasswordVisible = useState(false);
    final isLoading = useState(false);

    useEffect(() {
      if (authErrorCode != null) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (context.mounted) {
            _showError(context, authCallbackErrorMessage(authErrorCode));
          }
        });
      }
      return null;
    }, [authErrorCode]);

    Future<void> loginWithGoogle() async {
      isLoading.value = true;
      try {
        final launched = await ref
            .read(authRepositoryProvider)
            .signInWithGoogle();
        if (!launched && context.mounted) {
          _showError(
            context,
            'Impossible d’ouvrir la connexion Google. Réessayez.',
          );
        }
      } catch (error) {
        if (context.mounted) _showError(context, authErrorMessage(error));
      } finally {
        if (context.mounted) isLoading.value = false;
      }
    }

    Future<void> login() async {
      if (!formKey.currentState!.validate()) return;

      isLoading.value = true;

      try {
        await ref
            .read(authRepositoryProvider)
            .signIn(
              email: emailController.text.trim(),
              password: passwordController.text,
            );

        if (context.mounted) {
          context.go(_safeReturnTo(returnTo));
        }
      } catch (error) {
        if (context.mounted) {
          _showError(
            context,
            authErrorMessage(error),
            action: isEmailNotConfirmedError(error)
                ? SnackBarAction(
                    label: 'Renvoyer le lien',
                    onPressed: () => _resendConfirmation(
                      context,
                      ref,
                      emailController.text.trim(),
                    ),
                  )
                : null,
          );
        }
      } finally {
        if (context.mounted) isLoading.value = false;
      }
    }

    return Scaffold(
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Form(
            key: formKey,
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const Icon(Icons.book, size: 80, color: Color(0xFF00695C)),
                const SizedBox(height: 20),
                Text(
                  'Chad Books',
                  textAlign: TextAlign.center,
                  style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: const Color(0xFF00695C),
                  ),
                ),
                const SizedBox(height: 40),
                TextFormField(
                  controller: emailController,
                  decoration: const InputDecoration(
                    labelText: 'E-mail',
                    border: OutlineInputBorder(),
                    prefixIcon: Icon(Icons.email_outlined),
                  ),
                  keyboardType: TextInputType.emailAddress,
                  textInputAction: TextInputAction.next,
                  autofillHints: const [AutofillHints.email],
                  validator: _validateEmail,
                ),
                const SizedBox(height: 20),
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
                  textInputAction: TextInputAction.done,
                  autofillHints: const [AutofillHints.password],
                  validator: (value) => value == null || value.isEmpty
                      ? 'Saisissez votre mot de passe.'
                      : null,
                  onFieldSubmitted: (_) => isLoading.value ? null : login(),
                ),
                Align(
                  alignment: Alignment.centerRight,
                  child: TextButton(
                    onPressed: isLoading.value
                        ? null
                        : () => _showPasswordResetDialog(
                            context,
                            ref,
                            emailController,
                          ),
                    child: const Text('Mot de passe oublié ?'),
                  ),
                ),
                const SizedBox(height: 12),
                FilledButton(
                  onPressed: isLoading.value ? null : login,
                  style: FilledButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                  ),
                  child: isLoading.value
                      ? const SizedBox(
                          height: 20,
                          width: 20,
                          child: CircularProgressIndicator(
                            color: Colors.white,
                            strokeWidth: 2,
                          ),
                        )
                      : const Text('Se connecter'),
                ),
                const Padding(
                  padding: EdgeInsets.symmetric(vertical: 16),
                  child: Row(
                    children: [
                      Expanded(child: Divider()),
                      Padding(
                        padding: EdgeInsets.symmetric(horizontal: 12),
                        child: Text('OU'),
                      ),
                      Expanded(child: Divider()),
                    ],
                  ),
                ),
                OutlinedButton.icon(
                  onPressed: isLoading.value ? null : loginWithGoogle,
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 14),
                  ),
                  icon: const Icon(Icons.account_circle_outlined),
                  label: const Text('Continuer avec Google'),
                ),
                TextButton(
                  onPressed: isLoading.value
                      ? null
                      : () => context.go(
                          Uri(
                            path: '/register',
                            queryParameters: {
                              'returnTo': _safeReturnTo(returnTo),
                            },
                          ).toString(),
                        ),
                  child: const Text('Pas encore de compte ? Créer un compte'),
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

Future<void> _showPasswordResetDialog(
  BuildContext parentContext,
  WidgetRef ref,
  TextEditingController emailController,
) async {
  final formKey = GlobalKey<FormState>();
  var isSending = false;
  String? errorMessage;

  await showDialog<void>(
    context: parentContext,
    builder: (dialogRouteContext) => StatefulBuilder(
      builder: (dialogContentContext, setDialogState) {
        Future<void> sendResetEmail() async {
          if (isSending || !formKey.currentState!.validate()) return;

          setDialogState(() {
            isSending = true;
            errorMessage = null;
          });
          try {
            await ref
                .read(authRepositoryProvider)
                .sendPasswordResetEmail(email: emailController.text.trim());
            if (dialogRouteContext.mounted) {
              Navigator.of(dialogRouteContext).pop();
            }
            if (parentContext.mounted) {
              _showMessage(
                parentContext,
                'Si un compte est associé à cette adresse, un e-mail de '
                'récupération va vous être envoyé.',
              );
            }
          } catch (error) {
            if (dialogRouteContext.mounted) {
              setDialogState(() {
                errorMessage = authErrorMessage(error);
                isSending = false;
              });
            }
          }
        }

        return AlertDialog(
          scrollable: true,
          icon: Icon(
            Icons.lock_reset_rounded,
            color: Theme.of(dialogContentContext).colorScheme.primary,
          ),
          title: const Text('Récupérer votre compte'),
          content: Form(
            key: formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const Text(
                  'Saisissez votre adresse e-mail pour recevoir un lien '
                  'de réinitialisation.',
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: emailController,
                  keyboardType: TextInputType.emailAddress,
                  autofocus: emailController.text.isEmpty,
                  decoration: const InputDecoration(
                    labelText: 'E-mail',
                    border: OutlineInputBorder(),
                    prefixIcon: Icon(Icons.email_outlined),
                  ),
                  validator: _validateEmail,
                ),
                if (errorMessage != null) ...[
                  const SizedBox(height: 12),
                  Text(
                    errorMessage!,
                    style: TextStyle(
                      color: Theme.of(dialogContentContext).colorScheme.error,
                    ),
                  ),
                ],
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: isSending
                  ? null
                  : () => Navigator.of(dialogRouteContext).pop(),
              child: const Text('Annuler'),
            ),
            FilledButton(
              onPressed: isSending ? null : sendResetEmail,
              child: isSending
                  ? const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Text('Envoyer le lien'),
            ),
          ],
        );
      },
    ),
  );
}

void _showError(
  BuildContext context,
  String message, {
  SnackBarAction? action,
}) {
  _showMessage(context, message, isError: true, action: action);
}

void _showMessage(
  BuildContext context,
  String message, {
  bool isError = false,
  SnackBarAction? action,
}) {
  showAppMessage(
    context,
    message,
    isError: isError,
    action: action,
    duration: action == null
        ? const Duration(seconds: 4)
        : const Duration(seconds: 12),
  );
}

Future<void> _resendConfirmation(
  BuildContext context,
  WidgetRef ref,
  String email,
) async {
  try {
    await ref
        .read(authRepositoryProvider)
        .resendSignupConfirmation(email: email);
    if (context.mounted) {
      _showMessage(
        context,
        'Un nouvel e-mail de confirmation a été envoyé. Vérifiez aussi vos courriers indésirables.',
      );
    }
  } catch (error) {
    if (context.mounted) {
      _showError(context, authErrorMessage(error));
    }
  }
}
