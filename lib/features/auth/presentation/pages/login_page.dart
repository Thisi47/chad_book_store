import 'package:chad_book_store/features/auth/data/auth_repository.dart';
import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:go_router/go_router.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
// import 'package:go_router/go_router.dart';

class LoginPage extends HookConsumerWidget{
  const LoginPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Hooks : Gestion automatique des controlleurs de texte
    final emailController = useTextEditingController();
    final passwordController = useTextEditingController();

    // Pour gérer l'état du formulaire
    final formKey = useMemoized(() => GlobalKey<FormState>());

    // Pour cacher / afficher le mot de passe
    final isPasswordVisible = useState(false);

    final isLoading = useState(false);

    // Fonction de connexion isolée pour la clarté
    Future<void> _login() async{
      if(!formKey.currentState!.validate()) return;

      isLoading.value = true;

      try {
        await ref.read(authRepositoryProvider).signIn(
          email: emailController.text.trim(), 
          password: passwordController.text.trim());

          if(context.mounted) {
            context.go("/home");
          }
      } catch (e) {
        if(context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(e.toString().replaceAll("Exception:", "").trim()), 
              backgroundColor: Colors.red,
            ),
            
          );
        }
      } finally {
        if(context.mounted) isLoading.value = false;
      }
 
     }

    return Scaffold(
      body: Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(24.0),
        child: Form(
          key: formKey,
          child: Column( 
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Logo ou text
              const Icon(Icons.book, size: 80, color: Color(0xFF00695C),),
              const SizedBox(height: 20,),

              Text(
                "Chad Books",
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: const Color(0xFF00695C)
                ),
              ),
              const SizedBox(height: 40,),

              // Champ Email
              TextFormField(
                controller: emailController,
                decoration: InputDecoration(
                  labelText: "Email",
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.email_outlined)
                ),
                keyboardType: TextInputType.emailAddress,
                validator: (value) {
                  if (value == null || !value.contains("@")) {
                    return "Email invalide";
                  }
                  return null;
                },
              ),
              const SizedBox(height: 30,),

              // Champ de mot de passe 
              TextFormField(
                controller: passwordController,
                obscureText: !isPasswordVisible.value,
                decoration: InputDecoration(
                  labelText: "Mot de passe",
                  border: const OutlineInputBorder(),
                  prefixIcon: Icon(Icons.lock_outline),
                  suffixIcon: IconButton(
                    onPressed: () {
                      isPasswordVisible.value = !isPasswordVisible.value;
                    }, 
                    icon: Icon(isPasswordVisible.value ? Icons.visibility : Icons.visibility_off)
                  )
                ),
                validator: (value) {
                  if(value == null || value.length < 8) {
                    return "8 carectères au minimum";
                  }

                  return null;
                },
              ),
              const SizedBox(height: 30,),

              // Button de connexion
              FilledButton(
                onPressed: () {
                  if(formKey.currentState!.validate()) {
                    // TODO: Appel a la logique de connexion supabase
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text("Tentative de connexion !"))
                    );
                  }
                }, 
                style: FilledButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 16)
                ),
                child: isLoading.value 
                ? const SizedBox(
                  height: 20, 
                  width: 20, 
                  child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2,)
                  )
                : 
                const Text("Se connecter")
              )
            ],
          ),
        ),
      ),
      ),
    );
  }
}