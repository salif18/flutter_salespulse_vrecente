import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:printing/printing.dart';
import 'package:salespulse/https/domaine.dart';
import 'package:salespulse/utils/app_size.dart';
// ignore: depend_on_referenced_packages
import 'package:pdf/pdf.dart';
// ignore: depend_on_referenced_packages
import 'package:pdf/widgets.dart' as pw;
import 'package:provider/provider.dart';
import 'package:salespulse/providers/auth_provider.dart';
import 'package:salespulse/providers/panier_provider.dart';

const String domaineName = Domaine.domaineURI;

class ServicesPanier {
  Dio dio = Dio(
    BaseOptions(
      connectTimeout: const Duration(milliseconds: 15000), // 15 secondes
      receiveTimeout: const Duration(milliseconds: 15000), // 15 secondes
    ),
  );

  //AJOUTER DES COMMANDES
  Future<Response> postOrders(Map<String, dynamic> data, String token) async {
    var uri = "$domaineName/ventes";
    return await dio.post(
      uri,
      data: data,
      options: Options(
        headers: {
          "Content-Type": "application/json",
          "Authorization": "Bearer $token"
        },
      ),
    );
  }

  //message en cas de succès!
  Future<void> showSnackBarSuccessPersonalized(
      BuildContext context, String message) {
    final panierProvider = Provider.of<PanierProvider>(context, listen: false);

    return showDialog<void>(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Center(
              child: Text(
            'Réception',
            style: GoogleFonts.roboto(fontSize: AppSizes.fontLarge),
          )),
          contentPadding:
              const EdgeInsets.all(20.0), // Padding autour du contenu
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(15.0), // Arrondi des coins
          ),
          content: SizedBox(
            width: 300, // Largeur fixe pour le dialogue
            child: Column(
              mainAxisSize: MainAxisSize
                  .min, // Pour ajuster la hauteur en fonction du contenu
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                SizedBox(
                  width: 100, // Largeur de l'image
                  height: 100, // Hauteur de l'image
                  child: Image.asset("assets/logos/succes1.jpg"),
                ),
                const SizedBox(height: 15),
                Text(
                  message,
                  style: GoogleFonts.aBeeZee(
                      fontSize: AppSizes.fontLarge, color: Colors.green),
                  textAlign: TextAlign.center, // Centrer le texte
                ),
              ],
            ),
          ),
          actions: <Widget>[
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                TextButton(
                  onPressed: () {
                    panierProvider.clearCart();
                    Navigator.of(context).pop();
                  },
                  child: Container(
                      width: 100,
                      height: 40,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(20),
                        color: Colors.black,
                      ),
                      child: Center(
                          child: Text(
                        'Retour',
                        style: GoogleFonts.roboto(
                            fontSize: AppSizes.fontMedium, color: Colors.white),
                      ))),
                ),
                IconButton(
                    onPressed: () {
                      _printReceipt(context);
                    },
                    icon: const Icon(
                      Icons.print_rounded,
                      size: AppSizes.iconHyperLarge,
                      color: Colors.blue,
                    ))
              ],
            ),
          ],
        );
      },
    );
  }

  Future<void> _printReceipt(BuildContext context) async {
    final pdf = pw.Document();
    // Utiliser Consumer pour récupérer les données du panier
    final store = Provider.of<AuthProvider>(context, listen: false).societeName;
    final panierProvider = Provider.of<PanierProvider>(context, listen: false);
    final panier = panierProvider.myCart;
    int total = panierProvider.total;
    final now = DateTime.now();
    final date = DateFormat("dd MMM yyyy").format(now);

    // final String date = "2024-09-09";
    // Ajouter les détails du reçu au PDF
    pdf.addPage(
      pw.Page(
        build: (pw.Context context) {
          return pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              pw.Text(store,
                  style: pw.TextStyle(
                      fontSize: 24, fontWeight: pw.FontWeight.bold)),
              pw.SizedBox(height: 10),
              pw.Text("Date: $date", style: const pw.TextStyle(fontSize: 12)),
              pw.SizedBox(height: 10),
              pw.Text("Détails du reçu :",
                  style: pw.TextStyle(
                      fontSize: 16, fontWeight: pw.FontWeight.bold)),
              pw.SizedBox(height: 10),
              // ignore: deprecated_member_use
              pw.Table.fromTextArray(
                headers: ['Produit', 'Prix Unitaire', 'Quantité', 'Somme'],
                data: panier.map((product) {
                  return [
                    product.nom,
                    "${product.prixVente} \$",
                    "${product.qty}",
                    "$total \$"
                  ];
                }).toList(),
              ),
              pw.SizedBox(height: 20),
              pw.Divider(),
              pw.Text(
                "Total: $total \$",
                style:
                    pw.TextStyle(fontSize: 16, fontWeight: pw.FontWeight.bold),
              ),
            ],
          );
        },
      ),
    );

    // Utiliser le package `printing` pour imprimer ou sauvegarder le PDF
    await Printing.layoutPdf(
      onLayout: (PdfPageFormat format) async {
        // Sauvegarder le PDF
        final pdfFile = pdf.save();
        // Effacer le panier après la sauvegarde
        panierProvider.clearCart();
        return pdfFile;
      },
    );
  }

  //message en cas d'erreur!
  void showSnackBarErrorPersonalized(BuildContext context, String message) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(message,
          style: GoogleFonts.roboto(fontSize: MediaQuery.of(context).size.width *0.4, fontWeight: FontWeight.w400)),
      backgroundColor: const Color.fromARGB(255, 11, 26, 73),
      duration: const Duration(seconds: 5),
      action: SnackBarAction(
          label: "",
          onPressed: () {
            ScaffoldMessenger.of(context).hideCurrentSnackBar();
          }),
    ));
  }
}
