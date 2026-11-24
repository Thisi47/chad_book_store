# Tchad Books — Administration

Interface d’administration légère en React, TypeScript et Vite. Elle utilise Supabase Auth et le client public Supabase depuis le navigateur ; aucune clé `service_role` ne doit être ajoutée à ce projet.

## Démarrage local

```sh
cp .env.example .env.local
# Renseigner VITE_SUPABASE_URL et VITE_SUPABASE_ANON_KEY
npm install
npm run dev
```

## Première configuration Supabase

1. Exécuter `supabase/migrations/20261124150000_admin_console.sql` dans le SQL Editor Supabase.
2. Créer un compte administrateur via Supabase Auth (ou inscrire le compte depuis le flux d’inscription existant).
3. Dans le SQL Editor, ajouter ce compte à `public.admin_users` :

```sql
insert into public.admin_users (user_id)
select id from auth.users where lower(email) = lower('admin@example.com')
on conflict (user_id) do nothing;
```

4. Renseigner les variables Vite dans `.env.local` et lancer le serveur.

Les permissions d’administration sont contrôlées par RLS. Le navigateur n’obtient aucun secret serveur. Les utilisateurs mobiles conservent la lecture publique du catalogue, l’accès à leurs propres commandes et la lecture des fichiers pour les livres achetés.

## Fonctions

- Tableau de bord avec nombre de livres, fichiers manquants et commandes récentes.
- Création, modification et suppression des livres du catalogue.
- Envoi de fichiers PDF, EPUB, TXT et Markdown vers le bucket privé `book-files`, puis association automatique au livre sélectionné.
- Consultation des commandes récentes sans action sur le parcours d’achat.
- Interface responsive pour ordinateur, tablette et mobile.

Les fichiers de couverture restent des URLs externes pour conserver le schéma actuel de l’application mobile.
