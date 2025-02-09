import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:pin_code_fields/pin_code_fields.dart';
import 'package:salespulse/services/auth_api.dart';
import 'package:salespulse/utils/app_size.dart';
import 'package:salespulse/views/auth/login_view.dart';

class ValidationReset extends StatefulWidget {
  const ValidationReset({super.key});

  @override
  State<ValidationReset> createState() => _ValidationResetState();
}

class _ValidationResetState extends State<ValidationReset> {

   ServicesAuth api = ServicesAuth();

final GlobalKey<FormState> _globalKey = GlobalKey<FormState>();
final _newPassword = TextEditingController();
  final _confirmPassword = TextEditingController();
  String resetTokenValue = "";

  @override
  void dispose() {
    _newPassword.dispose();
    _confirmPassword.dispose();
    super.dispose();
  }




// ENVOIE DES DONNEE VERS API SERVER
  Future<void> _sendToserver(BuildContext context) async {
  if (_globalKey.currentState!.validate()) {
    var data = {
        "reset_token": resetTokenValue,
        "new_password": _newPassword.text.trim(),
        "confirm_password": _confirmPassword.text.trim()
      };
  
    try {
      showDialog(
          context: context,
          builder: (context) {
            return const Center(
              child: CircularProgressIndicator(),
            );
          });
      final response = await api.postValidatePassword(data);
      final body = json.decode(response.body);
      // ignore: use_build_context_synchronously
      Navigator.pop(context); // Fermer le dialog

      if (response.statusCode == 200) {
          // ignore: use_build_context_synchronously
          api.showSnackBarSuccessPersonalized(context, body["message"]);
          // ignore: use_build_context_synchronously
          Navigator.pushReplacement(context,
              MaterialPageRoute(builder: (context) => const LoginView()));

      } else {
        // ignore: use_build_context_synchronously
        api.showSnackBarErrorPersonalized(context, body["message"]);
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
        toolbarHeight: AppSizes.responsiveValue(context, 80.0),
        elevation: 0,
        backgroundColor: Colors.grey[200],
        leading: IconButton(
            onPressed: () => Navigator.pop(context),
            icon: const Icon(Icons.arrow_back_ios_new_rounded, size: AppSizes.iconLarge)),
      ),
      body: Container(
        padding: EdgeInsets.all(AppSizes.responsiveValue(context, 10.0)),
        child: SingleChildScrollView(
          child: Form(
            key: _globalKey,
            child: Column(
              children: [
                _text(context),
                _formNewPassword(context),
                _formConfirmPassword(context),
                _secondText(context),
                _codes4Champs(context),
                SizedBox(height: AppSizes.responsiveValue(context, 100)),
                _sendButton(context)
              ],
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
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: EdgeInsets.all(AppSizes.responsiveValue(context, 8.0)),
            child: Text("Validation le mot de passe",
                style: GoogleFonts.roboto(
                    fontSize: AppSizes.fontLarge, fontWeight: FontWeight.w600)),
          ),
          Padding(
            padding: EdgeInsets.all(AppSizes.responsiveValue(context, 8.0)),
            child: Text(
                "Veuillez entrer les bonnes informations pour pouvoir valider le nouveau mot de passe",
                style: GoogleFonts.roboto(
                    fontSize: AppSizes.fontMedium, fontWeight: FontWeight.w300)),
          ),
        ],
      ),
    );
  }

  Widget _formNewPassword(BuildContext context) {
    return Padding(
      padding: EdgeInsets.all(AppSizes.responsiveValue(context, 8.0)),
      child: TextFormField(
         controller: _newPassword,
        validator: (value) {
          if (value!.isEmpty) {
            return 'Veuillez entrer un nouveau mot de passe';
          }
          return null;
        },
        keyboardType: TextInputType.visiblePassword,
        decoration: InputDecoration(
          prefixIcon: const Icon(Icons.key_rounded, size: AppSizes.fontLarge),
          isDense: true, // Réduit la hauteur
                              contentPadding: EdgeInsets.symmetric(vertical: AppSizes.responsiveValue(context, 8.0)),
          filled: true,
          fillColor: Colors.grey[100],
          labelText: "Nouveau mot de passe",
          labelStyle:
              GoogleFonts.aBeeZee(fontSize: AppSizes.fontMedium, fontWeight: FontWeight.w500),
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(20)),
        ),
      ),
    );
  }

  Widget _formConfirmPassword(BuildContext context) {
    return Padding(
      padding: EdgeInsets.all(AppSizes.responsiveValue(context, 8.0)),
      child: TextFormField(
         controller: _confirmPassword,
        validator: (value) {
          if (value!.isEmpty) {
            return 'Veuillez retaper le meme mot de passe';
          }
          return null;
        },
        keyboardType: TextInputType.visiblePassword,
        decoration: InputDecoration(
          prefixIcon: const Icon(Icons.lock_outline, size: AppSizes.iconLarge),
          isDense: true, // Réduit la hauteur
                              contentPadding: EdgeInsets.symmetric(vertical: AppSizes.responsiveValue(context, 8.0)),
          filled: true,
          fillColor: Colors.grey[100],
          labelText: "Confirmer",
          labelStyle:
              GoogleFonts.aBeeZee(fontSize: AppSizes.fontMedium, fontWeight: FontWeight.w500),
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(20)),
        ),
      ),
    );
  }

  Widget _secondText(BuildContext context) {
    return Padding(
        padding: EdgeInsets.all(AppSizes.responsiveValue(context, 8.0)),
        child: Container(
            padding: EdgeInsets.all(AppSizes.responsiveValue(context, 8.0)),
            child: Text("Entrez les 4 chiffres envoyés sur votre e-mail",
                style: GoogleFonts.roboto(
                    fontSize: AppSizes.fontMedium, fontWeight: FontWeight.w400))));
  }

  Widget _codes4Champs(BuildContext context) {
    return Padding(
      padding: EdgeInsets.all(AppSizes.responsiveValue(context, 10.0)),
      child: Padding(
          padding: EdgeInsets.all(AppSizes.responsiveValue(context, 8.0)),
          child: PinCodeTextField(
            appContext: context,
            length: 4,
            pinTheme: PinTheme(
                shape: PinCodeFieldShape.box,
                borderRadius: BorderRadius.circular(10),
                fieldHeight: AppSizes.responsiveValue(context, 80.0),
                fieldWidth: AppSizes.responsiveValue(context, 75.0),
                activeColor: Colors.blue,
                inactiveColor: Colors.grey),
            onCompleted: (value) {
              setState(() {
                  resetTokenValue = value;
              });
            },
            validator: (value) {
              if (value!.isEmpty) {
                return 'Veuillez entrer les 4 chiffres de validation';
              }
              return null;
            },
          )),
    );
  }

  Widget _sendButton(BuildContext context) {
    return ElevatedButton(
        style: ElevatedButton.styleFrom(
            backgroundColor: const Color.fromARGB(255, 255, 115, 0),
            minimumSize:  Size(AppSizes.responsiveValue(context, 350.0), AppSizes.responsiveValue(context, 40.0))),
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
