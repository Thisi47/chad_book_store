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