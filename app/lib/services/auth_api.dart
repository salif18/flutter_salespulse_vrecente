import "dart:convert";

import "package:flutter/material.dart";
import "package:google_fonts/google_fonts.dart";

import "package:http/http.dart" as http;
import 'package:dio/dio.dart';
import "package:salespulse/https/domaine.dart";

const String domaineName = Domaine.domaineURI;

class ServicesAuth {
  Dio dio = Dio(
    BaseOptions(
      connectTimeout: const Duration(milliseconds: 60000), // 15 secondes
      receiveTimeout: const Duration(milliseconds: 60000), // 15 secondes
    ),
  );

  // fonction de connection
  postLoginUser(data) async {
    var url = "$domaineName/auth/login";
    return await http.post(Uri.parse(url), body: jsonEncode(data), headers: {
      "Content-Type": "application/json",
      "Authorization": "Bearer "
    }).timeout(const Duration(seconds: 15));
  }

// fonction de creation de compte
  postRegistreUser(data) async {
    var url = "$domaineName/auth/registre";
    return await http.post(Uri.parse(url), body: jsonEncode(data), headers: {
      "Content-Type": "application/json",
      "Authorization": "Bearer "
    }).timeout(const Duration(seconds: 15));
  }

//fontion de modification de passeword
  postUpdateUser(data, token, userId) async {
    var uri = "$domaineName/auth/update_user/$userId";
    return await http.post(
      Uri.parse(uri),
      body: jsonEncode(data),
      headers: {
        "Content-Type": "application/json",
        "Authorization": "Bearer $token"
      },
    ).timeout(const Duration(seconds: 15));
  }

  //fontion de modification de passeword
  postUpdatePassword(data, token, userId) async {
    var uri = "$domaineName/auth/update_password/$userId";
    return await http.post(
      Uri.parse(uri),
      body: jsonEncode(data),
      headers: {
        "Content-Type": "application/json",
        "Authorization": "Bearer $token"
      },
    ).timeout(const Duration(seconds: 15));
  }

  //fontion de reinitialisation de password
  postResetPassword(data) async {
    var uri = "$domaineName/reset/reset_token";
    return await http.post(
      Uri.parse(uri),
      body: jsonEncode(data),
      headers: {"Content-Type": "application/json", "Authorization": "Bearer "},
    ).timeout(const Duration(seconds: 15));
  }

  //fontion de validation de mot de password reinitialiser
  postValidatePassword(data) async {
    var uri = "$domaineName/reset/reset_valid";
    return await http.post(
      Uri.parse(uri),
      body: jsonEncode(data),
      headers: {"Content-Type": "application/json", "Authorization": "Bearer "},
    ).timeout(const Duration(seconds: 15));
  }

  //message en cas de succès!
  void showSnackBarSuccessPersonalized(BuildContext context, String message) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(message,
          style: GoogleFonts.roboto(fontSize: MediaQuery.of(context).size.width *0.04, fontWeight: FontWeight.w400)),
      backgroundColor: Colors.deepOrange,
      duration: const Duration(seconds: 5),
     
    ));
  }

  
//messade d'affichage des reponse de la requette en cas dechec
  void showSnackBarErrorPersonalized(BuildContext context, String message) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(message,
          style: GoogleFonts.roboto(fontSize:MediaQuery.of(context).size.width *0.04,fontWeight: FontWeight.w400)),
      backgroundColor: Colors.deepOrange,
      duration: const Duration(seconds: 5),
     
    ));
  }
}
