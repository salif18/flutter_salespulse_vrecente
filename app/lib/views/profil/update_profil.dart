// ignore_for_file: use_build_context_synchronously

import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:salespulse/providers/auth_provider.dart';
import 'package:salespulse/services/auth_api.dart';
import 'package:salespulse/utils/app_size.dart';

class UpdateProfil extends StatefulWidget {
  const UpdateProfil({super.key});

  @override
  State<UpdateProfil> createState() => _UpdateProfilState();
}

class _UpdateProfilState extends State<UpdateProfil> {
  ServicesAuth api = ServicesAuth();
  // CLE KEY POUR LE FORMULAIRE
  final GlobalKey<FormState> _globalKey = GlobalKey<FormState>();
   
  final _name = TextEditingController();
  final _numero = TextEditingController();
  final _email = TextEditingController();
  final _entreprise = TextEditingController();

   @override
  void dispose() {
    _name.dispose();
    _numero.dispose();
    _email.dispose();
    _entreprise.dispose();
    super.dispose();
  }

  Future _sendUpdate() async {
    final provider = Provider.of<AuthProvider>(context, listen: false);
    final userId =  provider.userId;
    final token =  provider.token;
    var data = {
      "name": _name.text,
        "boutique_name": _entreprise.text,
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
          
      final res = await api.postUpdateUser(data,token, userId);
      final body = json.decode(res.body);
      Navigator.pop(context);
      if (res.statusCode == 200) {
        api.showSnackBarSuccessPersonalized(context, body['message']);
        Navigator.pop(context);
      } else {
        api.showSnackBarErrorPersonalized(context, body["message"]);
      }
    } catch (err) {
      api.showSnackBarErrorPersonalized(context,
          "Erreur lors de l'envoi des données , veuillez réessayer. $err");
    }
  }
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[200],
      appBar: AppBar(
        backgroundColor:const Color(0xFF1D1A30),
        toolbarHeight:  AppSizes.responsiveValue(context, 80),
        leading: IconButton(
            onPressed: () => Navigator.pop(context),
            icon:const Icon(Icons.arrow_back_ios_new_rounded, size: AppSizes.iconLarge, color:Colors.white)),
        title: Text(
          "Modification de compte",
          style: GoogleFonts.roboto(
            fontSize: AppSizes.fontLarge,
            fontWeight: FontWeight.w500,
            color: Colors.white
          ),
        ),
      ),
      body: Container(
        padding:  EdgeInsets.all(AppSizes.responsiveValue(context, 20),),
        child: SingleChildScrollView(
          child: Container(
            padding:  EdgeInsets.all(AppSizes.responsiveValue(context, 20),),
            decoration: BoxDecoration(
                color: Colors.white, borderRadius: BorderRadius.circular(20)),
            child: Form(
              key: _globalKey,
              child: Column(
                children: [
                  _text(context),
                  _textFieldName(
                    context,
                  ),
                  _textFieldEntreprise(context),
                  _textFieldNumber(context),
                  _textFieldMail(context),
                   SizedBox(height:  AppSizes.responsiveValue(context, 100),),
                  _buttonSend(context),
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
      padding:  EdgeInsets.all(AppSizes.responsiveValue(context, 10),),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding:  EdgeInsets.all(AppSizes.responsiveValue(context, 8),),
            child: Text(
              "Changer le profil ",
              style:
                  GoogleFonts.roboto(fontSize: AppSizes.fontLarge, fontWeight: FontWeight.w600),
            ),
          ),
          Padding(
            padding:  EdgeInsets.all(AppSizes.responsiveValue(context, 8),),
            child: Text(
              "Vous pouvez apporter des modifications à votre profil",
              style:
                  GoogleFonts.roboto(fontSize: AppSizes.fontSmall, fontWeight: FontWeight.w400),
            ),
          )
        ],
      ),
    );
  }

  Widget _textFieldName(BuildContext context) {
    return Padding(
      padding:  EdgeInsets.all(AppSizes.responsiveValue(context, 8),),
      child: TextFormField(
         controller: _name,
        keyboardType: TextInputType.name,
        decoration: InputDecoration(
          filled: true,
          fillColor: Colors.grey[100],
          hintText: "Name",
          hintStyle:
              GoogleFonts.aBeeZee(fontSize: AppSizes.fontMedium, fontWeight: FontWeight.w400),
          prefixIcon: const Icon(Icons.person_2_outlined, size: AppSizes.iconLarge),
          border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(20),
              borderSide: BorderSide.none),
        ),
      ),
    );
  }

  Widget _textFieldEntreprise(BuildContext context) {
    return Padding(
      padding: EdgeInsets.all(AppSizes.responsiveValue(context, 8),),
      child: TextFormField(
         controller: _entreprise,
        keyboardType: TextInputType.name,
        decoration: InputDecoration(
          filled: true,
          fillColor: Colors.grey[100],
          hintText: "Services bussiness",
          hintStyle:
              GoogleFonts.aBeeZee(fontSize: AppSizes.fontMedium, fontWeight: FontWeight.w400),
          prefixIcon: const Icon(Icons.person_2_outlined, size: AppSizes.iconLarge),
          border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(20),
              borderSide: BorderSide.none),
        ),
      ),
    );
  }

  Widget _textFieldNumber(BuildContext context) {
    return Padding(
      padding:  EdgeInsets.all(AppSizes.responsiveValue(context, 8),),
      child: TextFormField(
         controller: _numero,
        keyboardType: TextInputType.phone,
        decoration: InputDecoration(
          filled: true,
          fillColor: Colors.grey[100],
          hintText: "Numero",
          hintStyle:
              GoogleFonts.aBeeZee(fontSize: AppSizes.fontMedium, fontWeight: FontWeight.w400),
          prefixIcon: const Icon(Icons.phone_android, size: AppSizes.iconLarge),
          border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(20),
              borderSide: BorderSide.none),
        ),
      ),
    );
  }

  Widget _textFieldMail(BuildContext context) {
    return Padding(
      padding: EdgeInsets.all(AppSizes.responsiveValue(context, 8),),
      child: TextFormField(
         controller: _email,
        keyboardType: TextInputType.emailAddress,
        decoration: InputDecoration(
          filled: true,
          fillColor: Colors.grey[100],
          hintText: "Email",
          hintStyle:
              GoogleFonts.aBeeZee(fontSize: AppSizes.fontMedium, fontWeight: FontWeight.w400),
          prefixIcon: const Icon(Icons.mail_outline, size: AppSizes.iconLarge),
          border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(20),
              borderSide: BorderSide.none),
        ),
      ),
    );
  }

  Widget _buttonSend(BuildContext context) {
    return Padding(
      padding: EdgeInsets.all(AppSizes.responsiveValue(context, 20),),
      child: ElevatedButton.icon(
          onPressed: () {
            _sendUpdate();
          },
          style: ElevatedButton.styleFrom(
              backgroundColor: const Color.fromARGB(255, 255, 115, 0),
              elevation: 5,
              fixedSize: Size(AppSizes.responsiveValue(context, 320), AppSizes.responsiveValue(context, 40),)),
          icon: Icon(Icons.edit, size: AppSizes.iconLarge, color: Colors.grey[100]),
          label: Text("Modifier le profil",
              style: GoogleFonts.roboto(
                  fontSize: AppSizes.fontSmall,
                  fontWeight: FontWeight.w500,
                  color: Colors.grey[100]))),
    );
  }
}
