import 'package:supabase_flutter/supabase_flutter.dart';

String authErrorMessage(Object error) {
  if (error is AuthRetryableFetchException) {
    return 'Connexion impossible. Vérifiez votre connexion internet puis réessayez.';
  }

  if (error is AuthException) {
    final normalizedMessage = error.message.toLowerCase();
    if (error.code == 'over_email_send_rate_limit' ||
        normalizedMessage.contains('email rate limit exceeded')) {
      return 'La limite d’envoi des e-mails Supabase est atteinte. Attendez le renouvellement du quota avant de demander un nouvel e-mail.';
    }

    switch (error.code) {
      case 'over_request_rate_limit':
        return 'Trop de tentatives. Patientez quelques instants avant de réessayer.';
      case 'invalid_credentials':
        return 'Adresse e-mail ou mot de passe incorrect. Vérifiez vos identifiants ou choisissez « Mot de passe oublié ? ».';
      case 'email_not_confirmed':
        return 'Votre adresse e-mail n’est pas encore confirmée. Ouvrez le message reçu (vérifiez aussi les courriers indésirables), puis réessayez.';
      case 'weak_password':
        return 'Le mot de passe est trop faible. Choisissez-en un autre, plus difficile à deviner.';
      case 'user_already_exists':
      case 'email_exists':
        return 'Un compte utilise déjà cette adresse. Connectez-vous ou réinitialisez votre mot de passe.';
      case 'signup_disabled':
        return 'La création de compte est momentanément indisponible. Réessayez plus tard.';
      case 'email_provider_disabled':
        return 'La connexion par e-mail est momentanément indisponible. Réessayez plus tard.';
      case 'user_banned':
        return 'Ce compte est temporairement suspendu. Contactez le support.';
      case 'same_password':
        return 'Choisissez un mot de passe différent de votre mot de passe actuel.';
      case 'validation_failed':
        return 'Les informations saisies ne sont pas valides. Vérifiez votre adresse e-mail et votre mot de passe.';
    }

    if (error.statusCode == '429') {
      return 'Trop de tentatives. Patientez quelques instants avant de réessayer.';
    }

    final statusCode = int.tryParse(error.statusCode ?? '');
    if (statusCode != null && statusCode >= 500) {
      return 'Le service est momentanément indisponible. Réessayez dans quelques instants.';
    }
  }

  return 'Une erreur est survenue. Veuillez réessayer.';
}

bool isEmailNotConfirmedError(Object error) =>
    error is AuthException && error.code == 'email_not_confirmed';

String authCallbackErrorMessage(String? errorCode) {
  if (errorCode == 'otp_expired' || errorCode == 'flow_state_expired') {
    return 'Ce lien a expiré ou a déjà été utilisé. Demandez un nouvel e-mail de récupération.';
  }
  if (errorCode == 'access_denied') {
    return 'La connexion a été annulée ou refusée. Vous pouvez réessayer.';
  }
  return 'L’authentification n’a pas abouti. Réessayez.';
}
