import 'package:chad_book_store/features/auth/presentation/auth_error_message.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

void main() {
  group('authErrorMessage', () {
    test('translates invalid credentials without exposing server details', () {
      final message = authErrorMessage(
        AuthApiException(
          'Invalid login credentials',
          statusCode: '400',
          code: 'invalid_credentials',
        ),
      );

      expect(
        message,
        'Adresse e-mail ou mot de passe incorrect. Vérifiez vos identifiants ou choisissez « Mot de passe oublié ? ».',
      );
      expect(message, isNot(contains('Invalid login credentials')));
    });

    test('explains unconfirmed email and offers the resend path', () {
      final error = AuthApiException(
        'Email not confirmed',
        statusCode: '400',
        code: 'email_not_confirmed',
      );

      expect(isEmailNotConfirmedError(error), isTrue);
      expect(
        authErrorMessage(error),
        contains('vérifiez aussi les courriers indésirables'),
      );
    });

    test('explains rate limits and connection failures', () {
      const emailRateLimitMessage =
          'La limite d’envoi des e-mails Supabase est atteinte. Attendez le renouvellement du quota avant de demander un nouvel e-mail.';

      expect(
        authErrorMessage(
          AuthApiException('Email rate limit exceeded', statusCode: '429'),
        ),
        emailRateLimitMessage,
      );
      expect(
        authErrorMessage(
          AuthApiException(
            'Too many requests',
            statusCode: '429',
            code: 'over_email_send_rate_limit',
          ),
        ),
        emailRateLimitMessage,
      );
      expect(
        authErrorMessage(
          AuthApiException(
            'Too many requests',
            statusCode: '400',
            code: 'over_request_rate_limit',
          ),
        ),
        'Trop de tentatives. Patientez quelques instants avant de réessayer.',
      );
      expect(
        authErrorMessage(AuthRetryableFetchException()),
        'Connexion impossible. Vérifiez votre connexion internet puis réessayez.',
      );
    });

    test('explains existing accounts and expired recovery links', () {
      expect(
        authErrorMessage(
          AuthApiException(
            'User already registered',
            statusCode: '422',
            code: 'user_already_exists',
          ),
        ),
        'Un compte utilise déjà cette adresse. Connectez-vous ou réinitialisez votre mot de passe.',
      );
      expect(
        authCallbackErrorMessage('otp_expired'),
        'Ce lien a expiré ou a déjà été utilisé. Demandez un nouvel e-mail de récupération.',
      );
      expect(
        authCallbackErrorMessage('access_denied'),
        'La connexion a été annulée ou refusée. Vous pouvez réessayer.',
      );
    });

    test('uses a safe fallback for unknown errors', () {
      expect(
        authErrorMessage(Exception('internal server details')),
        'Une erreur est survenue. Veuillez réessayer.',
      );
    });
  });
}
