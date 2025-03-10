import 'dart:convert';
import 'dart:math';

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:salespulse/providers/auth_provider.dart';
import 'package:salespulse/routes.dart';
import 'package:salespulse/services/auth_api.dart';
import 'package:salespulse/utils/app_size.dart';
import 'package:salespulse/views/auth/registre_view.dart';
import 'package:salespulse/views/auth/reset_password.dart';

class LoginView extends StatefulWidget {
  const LoginView({super.key});

  @override
  State<LoginView> createState() => _LoginViewState();
}

class _LoginViewState extends State<LoginView> {
  
  // CLE KEY POUR LE FORMULAIRE
  final GlobalKey<FormState> _globalKey = GlobalKey<FormState>();
  final ServicesAuth api = ServicesAuth();
 
  final _contacts = TextEditingController();
  final _password = TextEditingController(); 
  bool isVisibility = true;

  @override 
  void dispose(){
    _contacts.dispose(); 
    _password.dispose();
    super.dispose();
  }
  
  // ENVOIE DES DONNEES VERS API SERVER
  Future<void> _sendToserver(BuildContext context) async {
    if (_globalKey.currentState!.validate()) {
      final data = {
        "contacts": _contacts.text,
        "password": _password.text
      };
      final providerAuth = Provider.of<AuthProvider>(context, listen: false);
    
      try {
        showDialog(
          context: context,
          builder: (context) {
            return const Center(
              child: CircularProgressIndicator(),
            );
          });
        final response = await api.postLoginUser(data);
        final body = jsonDecode(response.body);
        // ignore: use_build_context_synchronously
        Navigator.pop(context); // Fermer le dialog

        if (response.statusCode == 200) {
          providerAuth.loginButton(body['token'], body["userId"].toString(), body["userName"], body["entreprise"], body["userNumber"]);
          // ignore: use_build_context_synchronously
          Navigator.push(context, MaterialPageRoute(builder: (context) => const Routes()));
        } else {
          // ignore: use_build_context_synchronously
          api.showSnackBarErrorPersonalized(context, body["message"]);
          Navigator.pop(context);
        }
      } catch (e) {
        // ignore: use_build_context_synchronously
        Navigator.pop(context); // Fermer le dialog
        // ignore: use_build_context_synchronously
        api.showSnackBarErrorPersonalized(context, e.toString());
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color.fromARGB(255, 229, 248, 255),
      body: CustomScrollView(
        slivers: [
          SliverToBoxAdapter(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Container(
                  width: MediaQuery.of(context).size.width,
                  height:  min(AppSizes.responsiveValue(context, 400),400),
                  decoration: const BoxDecoration(
                    image: DecorationImage(
                      image: AssetImage("assets/logos/logo2.jpg"), 
                      fit: BoxFit.contain
                    ),
                  ),
                ),
                Container(
                  height: AppSizes.responsiveValue(context, 400),
                  width: MediaQuery.of(context).size.width,
                  padding: EdgeInsets.only(top: min(AppSizes.responsiveValue(context, 50),50), left: min(AppSizes.responsiveValue(context, 10),10), right: min(AppSizes.responsiveValue(context, 10),10)),
                  decoration: const BoxDecoration(
                    color: Color(0xff001c30),
                    borderRadius: BorderRadius.only(
                      topLeft: Radius.circular(25),
                      topRight: Radius.circular(25),
                    ),
                  ),
                  child: Form(
                    key: _globalKey,
                    child: Column(
                      children: [
                        Padding(
                          padding: EdgeInsets.all(AppSizes.responsiveValue(context, 8.0)),
                          child: TextFormField(
                            controller: _contacts,
                            validator: (value) {
                              if (value!.isEmpty) {
                                return 'Veuillez entrer un numéro ou un e-mail';
                              }
                              return null;
                            },
                            keyboardType: TextInputType.emailAddress,
                            decoration: InputDecoration(
                              hintText: "Numéro ou e-mail",
                              hintStyle: GoogleFonts.roboto(fontSize: min(AppSizes.responsiveValue(context, 12),20)),
                              filled: true,
                              fillColor: const Color(0xfff0fcf3),
                              prefixIcon: const Icon(Icons.person_2_outlined, size: AppSizes.iconLarge),
                              isDense: true, // Réduit la hauteur
                              contentPadding:EdgeInsets.symmetric(vertical: AppSizes.responsiveValue(context, 8.0)),
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(20),
                                borderSide: BorderSide.none,
                              ),
                            ),
                          ),
                        ),
                        SizedBox(height: AppSizes.responsiveValue(context, 10)),
                        Padding(
                          padding: EdgeInsets.all(AppSizes.responsiveValue(context, 8.0)),
                          child: TextFormField(
                            controller: _password,
                            validator: (value) {
                              if (value!.isEmpty) {
                                return 'Veuillez entrer votre mot de passe';
                              }
                              return null;
                            },
                            obscureText: isVisibility,
                            decoration: InputDecoration(
                              hintText: "Mot de passe",
                              hintStyle: GoogleFonts.roboto(fontSize: min(AppSizes.responsiveValue(context, 12),20)),
                              filled: true,
                              fillColor: const Color(0xfff0fcf3),
                              prefixIcon: const Icon(Icons.lock_outline, size: AppSizes.iconLarge),
                              isDense: true, // Réduit la hauteur
                              contentPadding: EdgeInsets.symmetric(vertical: AppSizes.responsiveValue(context, 8.0)),
                              suffixIcon: IconButton(
                                onPressed: () {
                                  setState(() {
                                    isVisibility = !isVisibility;
                                  });
                                },
                                icon: Icon(isVisibility ? Icons.visibility_off : Icons.visibility),
                              ),
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(20),
                                borderSide: BorderSide.none,
                              ),
                            ),
                          ),
                        ),
                        // const SizedBox(height: 5),
                        Padding(
                          padding: EdgeInsets.all(AppSizes.responsiveValue(context, 8.0)),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.end,
                            children: [
                              TextButton(
                                onPressed: () {
                                  Navigator.push(context, MaterialPageRoute(builder: (context)=>const ResetToken()));
                                },
                                child: Text(
                                  "Mot de passe oublié ?",
                                  style: GoogleFonts.roboto(
                                    fontSize: min(AppSizes.responsiveValue(context, 12),20),
                                    color: Colors.blue[400],
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                        Padding(
                          padding: EdgeInsets.all(AppSizes.responsiveValue(context, 8.0)),
                          child: ElevatedButton(
                            style: ElevatedButton.styleFrom(
                              minimumSize: Size(AppSizes.responsiveValue(context, 400), min(AppSizes.responsiveValue(context, 40),60)),
                              backgroundColor: const Color.fromARGB(255, 255, 123, 0),
                            ),
                            onPressed: () {
                              _sendToserver(context);
                            },
                            child: Text(
                              "Se connecter",
                              style: GoogleFonts.roboto(
                                fontSize: min(AppSizes.responsiveValue(context, 12),20),
                                color: Colors.white,
                              ),
                            ),
                          ),
                        ),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text(
                              "Vous n'avez pas de compte ?",
                              style: GoogleFonts.roboto(
                                fontSize: min(AppSizes.responsiveValue(context, 12),20),
                                color: Colors.white,
                              ),
                            ),
                            TextButton(
                              onPressed: () {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(builder: (context) => const RegistreView()),
                                );
                              },
                              child: Text(
                                "Créer",
                                style: GoogleFonts.roboto(
                                  fontSize:min(AppSizes.responsiveValue(context, 12),20),
                                  fontWeight: FontWeight.bold,
                                  color: const Color.fromARGB(255, 255, 123, 0),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
