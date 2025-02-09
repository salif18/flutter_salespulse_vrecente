import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:salespulse/services/auth_api.dart';
import 'package:salespulse/utils/app_size.dart';
import 'package:salespulse/views/auth/validation.dart';

class ResetToken extends StatefulWidget {
  const ResetToken({super.key});

  @override
  State<ResetToken> createState() => _ResetTokenState();
}

class _ResetTokenState extends State<ResetToken> {
  ServicesAuth api = ServicesAuth();

final GlobalKey<FormState> _globalKey = GlobalKey<FormState>();
final _numero = TextEditingController();
final _email = TextEditingController();

@override 
void dispose(){
  _numero.dispose();
  _email.dispose();
  super.dispose();
}


// ENVOIE DES DONNEE VERS API SERVER
  Future<void> _sendToserver(BuildContext context) async {
  if (_globalKey.currentState!.validate()) {
    final data = {
      "numero": _numero.text,
      "email": _email.text,
    };
  
    try {
      showDialog(
          context: context,
          builder: (context) {
            return const Center(
              child: CircularProgressIndicator(),
            );
          });
      final response = await api.postResetPassword(data);
      final body = json.decode(response.body);
      // ignore: use_build_context_synchronously
      Navigator.pop(context); // Fermer le dialog

      if (response.statusCode == 200) {
          // ignore: use_build_context_synchronously
          Navigator.pushReplacement(context,
              MaterialPageRoute(builder: (context) => const ValidationReset()));

      } else {
        // ignore: use_build_context_synchronously
        api.showSnackBarErrorPersonalized(context, body["message"]);
        print(body["message"]);
      }
    } catch (e) {
      // ignore: use_build_context_synchronously
      Navigator.pop(context); // Fermer le dialogue
      // ignore: use_build_context_synchronously
      api.showSnackBarErrorPersonalized(context, "Erreur: ${e.toString()}");
    }
  }
}

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[200],
      appBar: AppBar(
        toolbarHeight: AppSizes.responsiveValue(context, 80),
        backgroundColor: Colors.grey[200],
        leading: IconButton(
            onPressed: () => Navigator.pop(context),
            icon: const Icon(Icons.arrow_back_ios_new_rounded, size: AppSizes.iconLarge)),
      ),
      body: Container(
        padding: EdgeInsets.all(AppSizes.responsiveValue(context, 10)),
        child: SingleChildScrollView(
          child: Container(
            padding: EdgeInsets.all(AppSizes.responsiveValue(context, 10)),
            child: Form(
              key: _globalKey,
              child: Column(
                children: [
                  _text(context),
                  _formNumberField(context),
                  _formEmailField(context),
                  SizedBox(height: AppSizes.responsiveValue(context,100)),
                  _sendButton(context)
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _text(BuildContext context) {
    return Padding(
      padding: EdgeInsets.all(AppSizes.responsiveValue(context, 8.0)),
      child: Column(
        children: [
          Padding(
            padding: EdgeInsets.all(AppSizes.responsiveValue(context, 8.0)),
            child: Text("Réinitialiser le mot de passe",
                style: GoogleFonts.roboto(
                    fontSize: AppSizes.fontLarge, fontWeight: FontWeight.w600)),
          ),
          Padding(
            padding: EdgeInsets.all(AppSizes.responsiveValue(context, 8.0)),
            child: Text(
                "Veuillez entrer les bonnes informations pour pouvoir nous aider à réinitialiser votre mot de passe",
                style: GoogleFonts.roboto(
                    fontSize: AppSizes.fontMedium, fontWeight: FontWeight.w300)),
          ),
        ],
      ),
    );
  }

  Widget _formNumberField(BuildContext context) {
    return Padding(
      padding: EdgeInsets.all(AppSizes.responsiveValue(context, 8.0)),
      child: TextFormField(
        controller: _numero,
        validator: (value) {
          if (value!.isEmpty) {
            return 'Veuillez entrer votre numero ';
          }
          return null;
        },
        keyboardType: TextInputType.phone,
        decoration: InputDecoration(
          prefixIcon: const Icon(Icons.phone_android_rounded, size: AppSizes.iconLarge),
          isDense: true, // Réduit la hauteur
                              contentPadding: EdgeInsets.symmetric(vertical: AppSizes.responsiveValue(context, 8.0)),
          filled: true,
          fillColor: Colors.grey[100],
          hintText: "Numéro",
          hintStyle:
              GoogleFonts.aBeeZee(fontSize: AppSizes.fontMedium, fontWeight: FontWeight.w500),
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(20)),
        ),
      ),
    );
  }

  Widget _formEmailField(BuildContext context) {
    return Padding(
      padding: EdgeInsets.all(AppSizes.responsiveValue(context, 8.0)),
      child: TextFormField(
        controller: _email,
        validator: (value) {
          if (value!.isEmpty) {
            return 'Veuillez entrer votre email';
          }
          return null;
        },
        keyboardType: TextInputType.emailAddress,
        decoration: InputDecoration(
          prefixIcon: const Icon(Icons.mail_outline, size: AppSizes.iconLarge),
          isDense: true, // Réduit la hauteur
                              contentPadding: EdgeInsets.symmetric(vertical: AppSizes.responsiveValue(context, 8.0)),
          filled: true,
          fillColor: Colors.grey[100],
          hintText: "Email",
          hintStyle:
              GoogleFonts.aBeeZee(fontSize: AppSizes.fontMedium, fontWeight: FontWeight.w500),
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(20)),
        ),
      ),
    );
  }

  Widget _sendButton(BuildContext context) {
    return ElevatedButton(
        style: ElevatedButton.styleFrom(
            backgroundColor:const Color.fromARGB(255, 255, 115, 0),
            minimumSize: Size(AppSizes.responsiveValue(context, 350), AppSizes.responsiveValue(context, 40))),
        onPressed: () {
          _sendToserver(context);
        },
        child: Text("Envoyer",
            style: GoogleFonts.aBeeZee(
                fontSize: AppSizes.fontSmall,
                fontWeight: FontWeight.w500,
                color: Colors.white)));
  }
}
