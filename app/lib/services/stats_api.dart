import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:http/http.dart' as http;
import 'package:salespulse/https/domaine.dart';

const String domaineName = Domaine.domaineURI;

class ServicesStats {
  //obtenir depenses
  getStatsByCategories(token, userId) async {
    var uri = "$domaineName/ventes/stats-by-categories/$userId";
    return await http.get(Uri.parse(uri), headers: {
      "Content-Type": "application/json",
      "Authorization": "Bearer $token"
    }).timeout(const Duration(seconds: 15));
  }

  getStatsHebdo(token, userId) async {
    var uri = "$domaineName/ventes/stats-by-hebdo/$userId";
    return await http.get(Uri.parse(uri), headers: {
      "Content-Type": "application/json",
      "Authorization": "Bearer $token"
    }).timeout(const Duration(seconds: 15));
  }

  getStatsByMonth(token, userId) async {
    var uri = "$domaineName/ventes/stats-by-month/$userId";
    return await http.get(Uri.parse(uri), headers: {
      "Content-Type": "application/json",
      "Authorization": "Bearer $token"
    }).timeout(const Duration(seconds: 15));
  }

  
//messade d'affichage des reponse de la requette en cas dechec
  void showSnackBarErrorPersonalized(BuildContext context, String message) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(message,
          style: GoogleFonts.roboto(fontSize:MediaQuery.of(context).size.width *0.04,fontWeight: FontWeight.w400)),
      backgroundColor: const Color.fromARGB(255, 34, 27, 51),
      duration: const Duration(seconds: 5),
      action: SnackBarAction(
        label: "",
        onPressed: () {
          ScaffoldMessenger.of(context).hideCurrentSnackBar();
        },
      ),
    ));
  }
}
