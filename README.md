# 📚 Tchad Books (chad_book_store)

![Flutter](https://img.shields.io/badge/Flutter-3.38.5-02569B?logo=flutter)
![Dart](https://img.shields.io/badge/Dart-3.10-0175C2?logo=dart)
![Supabase](https://img.shields.io/badge/Backend-Supabase-3ECF8E?logo=supabase)
![State](https://img.shields.io/badge/State-Riverpod-blue)
![License](https://img.shields.io/badge/License-MIT-green)

**La première plateforme e-commerce de livres optimisée pour le contexte tchadien.**

---

## 🌍 Le Projet
**Tchad Books** est une application mobile native (Android/iOS) conçue pour démocratiser l'accès à la lecture au Tchad. 

Contrairement aux solutions classiques, cette application est bâtie avec une philosophie **"Offline-First"** (Priorité hors-ligne) pour garantir une expérience utilisateur fluide même en cas de connexion internet instable ou inexistante à N'Djamena et en province.

### 🎯 Objectifs
* **Accessibilité :** Consultation du catalogue sans internet.
* **Performance :** Architecture réactive et légère.
* **Local :** Intégration future des paiements locaux (Airtel Money / Moov Africa).

---

## 🛠 La Stack Technique (2026 Standards)

Ce projet utilise les dernières technologies et bonnes pratiques de l'écosystème Flutter.

| Domaine | Technologie | Usage |
| :--- | :--- | :--- |
| **Framework** | Flutter 3.x | UI Multiplateforme |
| **Langage** | Dart 3.x | Typage fort, Null Safety |
| **Architecture** | **Clean Architecture** | Séparation des responsabilités |
| **State Mgt** | **Riverpod (Generator)** | Gestion d'état robuste et testable |
| **Backend** | **Supabase** | Auth, Base de données SQL (Postgres), Realtime |
| **Navigation** | **GoRouter** | Routing déclaratif et Deep Links |
| **UI Kit** | Flutter Hooks / Material 3 | Composants modernes et code concis |
| **Code Style** | Custom Lints | Analyse statique stricte |

---

## 🏗 Architecture du Code

Le projet suit une structure **Feature-First** combinée à la **Clean Architecture**. Cela permet une scalabilité maximale et facilite les tests unitaires.

```text
lib/
├── core/                # Composants partagés (Constants, Theme, Errors)
├── features/            # Modules fonctionnels
│   ├── auth/            # Authentification (Login, Register)
│   │   ├── data/        # Repositories & Data Sources (Supabase)
│   │   ├── domain/      # Entités & Business Logic
│   │   └── presentation/# Widgets & Controllers (Riverpod)
│   ├── products/        # Catalogue de livres
│   └── cart/            # Panier & Commandes
├── routing/             # Configuration des routes (GoRouter)
└── main.dart            # Point d'entrée & Injection de dépendances
```

## Catalogue, favoris, commandes et profil

Le catalogue et les détails des livres sont accessibles sans compte. La
connexion reste nécessaire pour commander, consulter l’historique, lire les
livres achetés, enregistrer des favoris et modifier son profil. Les favoris et
les champs du profil sont enregistrés dans les métadonnées du compte Supabase.
Les avatars sont stockés dans le bucket public `avatars`.

Pour activer la bibliothèque et la lecture, appliquez
[`supabase/migrations/20261123160000_restore_user_features.sql`](./supabase/migrations/20261123160000_restore_user_features.sql)
au projet Supabase. Dans le bucket privé `book-files`, téléversez chaque PDF et
renseignez son chemin dans `books.reading_path` (par exemple
`<id-du-livre>/livre.pdf`). La lecture génère une URL signée uniquement après
avoir vérifié que le compte a commandé le livre. Le total est recalculé côté
Postgres lors de la commande. Les commandes antérieures à la migration ne
contiennent pas les livres achetés et ne peuvent donc pas être ajoutées
automatiquement à la bibliothèque.

## Récupération du mot de passe

Dans le tableau de bord Supabase, ajoutez les URL de redirection utilisées à
**Authentication → URL Configuration → Redirect URLs**. Pour le mobile :

```text
chadbookstore://login-callback/
```

Pour Flutter Web, autorisez aussi l'URL `http://localhost:3000/login-callback`
en développement (adaptez le port si nécessaire), ainsi que l'URL équivalente
de votre site en production. La redirection Web utilise automatiquement
l'origine courante. Configurez également le **Site URL** Supabase avec l'URL
publique de votre application, et non `localhost`, en production.

Le modèle d'e-mail de récupération doit utiliser le lien de confirmation
Supabase (`{{ .ConfirmationURL }}`). Après ouverture du lien, l'application
permet de définir un nouveau mot de passe.

La création de compte est accessible depuis l'écran de connexion. Si la
confirmation d'e-mail est activée dans Supabase, la personne doit confirmer
son adresse avant sa première connexion.

## Connexion avec Google

Le bouton Google utilise le fournisseur OAuth configuré dans Supabase et
ramène l'utilisateur dans l'application via `chadbookstore://login-callback/`.
Google ouvre son écran de connexion dans le navigateur sécurisé du système
(Google interdit les WebViews intégrées pour cette authentification), puis
l'application reprend automatiquement la session.

Dans Google Cloud, l'URI de redirection autorisée du client Web doit être
`https://snjufojacjsxoyugkmou.supabase.co/auth/v1/callback`. Dans Supabase,
activez le fournisseur Google avec le client ID Web et son secret. Le callback
`chadbookstore://login-callback/` doit également figurer dans **Redirect URLs**.

Le service d'e-mail intégré de Supabase est limité (actuellement 2 e-mails
d'authentification par heure pour le projet). Pour les tests répétés ou la
production, configurez un SMTP personnalisé dans **Authentication → SMTP
Settings** et consultez les [limites Auth Supabase](https://supabase.com/docs/guides/auth/rate-limits).

## Livraison Android

La version de livraison est indiquée dans `pubspec.yaml`. Pour générer les
artefacts Android signés, créez `android/key.properties` à partir de
[`android/key.properties.example`](./android/key.properties.example) et placez
la clé `release-key.jks` dans `android/`. Ces deux fichiers sont ignorés par
Git. Gardez une copie chiffrée de la clé et de ses mots de passe : ils sont
nécessaires pour signer les futures mises à jour de l'application.

```sh
flutter build apk --release
flutter build appbundle --release
```
