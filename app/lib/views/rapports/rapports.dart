import 'dart:async';
import 'dart:io';

import 'package:date_field/date_field.dart';
import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:printing/printing.dart';
import 'package:provider/provider.dart';
import 'package:salespulse/components/drawer.dart';
import 'package:salespulse/models/ventes_model.dart';
import 'package:salespulse/providers/auth_provider.dart';
import 'package:salespulse/services/vente_api.dart';
import 'package:salespulse/utils/app_size.dart';
// ignore: depend_on_referenced_packages
import 'package:pdf/pdf.dart';
// ignore: depend_on_referenced_packages
import 'package:pdf/widgets.dart' as pw;

class RapportView extends StatefulWidget {
  const RapportView({super.key});

  @override
  State<RapportView> createState() => _RapportViewState();
}

class _RapportViewState extends State<RapportView> {
  final GlobalKey<ScaffoldState> drawerKey = GlobalKey<ScaffoldState>();
  DateTime? selectedDate;
  ServicesVentes api = ServicesVentes();
  final StreamController<List<VentesModel>> _streamController =
      StreamController();

  List<VentesModel> filteredArticles = [];
  List<VentesModel?> articleCopy = [];
  @override
  void initState() {
    super.initState();
    _loadProducts(); // Charger les produits au démarrage
  }

  @override
  void dispose() {
    _streamController
        .close(); // Fermer le StreamController pour éviter les fuites de mémoire
    super.dispose();
  }

  Future<void> _loadProducts() async {
    try {
      final token = Provider.of<AuthProvider>(context, listen: false).token;
      final userId = Provider.of<AuthProvider>(context, listen: false).userId;
      final res = await api.getAllVentes(token, userId);
      final body = res.data;

      if (res.statusCode == 200) {
        final products = (body["results"] as List)
            .map((json) => VentesModel.fromJson(json))
            .toList();

        if (!_streamController.isClosed) {
          _streamController.add(products); // Ajouter les produits au stream
          setState(() {
            articleCopy = products;
          });
        }
      } else {
        if (!_streamController.isClosed) {
          _streamController.addError("Failed to load products");
        }
      }
    } on DioException {
      api.showSnackBarErrorPersonalized(
          // ignore: use_build_context_synchronously
          context,
          "Problème de connexion : Vérifiez votre Internet.");
    } on TimeoutException {
      api.showSnackBarErrorPersonalized(
          // ignore: use_build_context_synchronously
          context,
          "Le serveur ne répond pas. Veuillez réessayer plus tard.");
    }  catch (e) {
      if (!_streamController.isClosed) {
        _streamController.addError("Error loading products");
      }
    }
  }

  //rafraichire la page en actualisanst la requete
  Future<void> _refresh() async {
    await Future.delayed(const Duration(seconds: 3));
    if (mounted) {
      // Vérifier si le widget est monté avant d'appeler setState()
      setState(() {
        _loadProducts(); // Rafraîchir les produits
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    //benefice total
    beneficeTotal() {
      if (filteredArticles.isEmpty) {
        return articleCopy.isNotEmpty
            ? articleCopy
                .map((article) =>
                    (article!.prixVente - article.prixAchat) * article.qty)
                .reduce((a, b) => a + b)
            : 0;
      } else {
        return filteredArticles
            .map((article) =>
                (article.prixVente - article.prixAchat) * article.qty)
            .reduce((a, b) => a + b);
      }
    }

    //quantite total de produit
    int nombreTotalDeProduit() {
      if (filteredArticles.isEmpty)
        return articleCopy.isNotEmpty
            ? articleCopy.map((a) => a!.qty).reduce((a, b) => a + b)
            : 0;
      return filteredArticles.map((a) => a.qty).reduce((a, b) => a + b);
    }

    //somme total
    //calcule somme total
    sommeTotal() {
      if (filteredArticles.isEmpty) {
        return articleCopy.isNotEmpty
            ? articleCopy
                .map((x) => x!.prixVente * x.qty)
                .reduce((a, b) => a + b)
            : 0;
      } else {
        return filteredArticles
            .map((x) => x.prixVente * x.qty)
            .reduce((a, b) => a + b);
      }
    }

    return Scaffold(
      key: drawerKey,
      drawer: const DrawerWidget(),
      backgroundColor: const Color(0xfff0f1f5),
      body: RefreshIndicator(
        backgroundColor: Colors.transparent,
        color: Colors.grey[100],
        onRefresh: _refresh,
        displacement: 50,
        child: CustomScrollView(
          slivers: [
            SliverAppBar(
              backgroundColor: const Color(0xff001c30),
              expandedHeight:AppSizes.responsiveValue(context, 100),
              pinned: true,
              floating: true,
              leading: IconButton(
                  onPressed: () {
                    drawerKey.currentState!.openDrawer();
                  },
                  icon: const Icon(
                    Icons.sort,
                    size: AppSizes.iconHyperLarge,
                    color: Color.fromARGB(255, 255, 136, 0),
                  )),
              flexibleSpace: FlexibleSpaceBar(
                title: Text("Rapports",
                    style: GoogleFonts.roboto(
                        fontSize: AppSizes.fontLarge, color: Colors.white)),
              ),
            ),
            SliverToBoxAdapter(
              child: Container(
                color: const Color(0xff001c30),
                height: AppSizes.responsiveValue(context, 150),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    LayoutBuilder(builder: (context, constraints) {
                      return Container(
                        padding: EdgeInsets.symmetric(horizontal: AppSizes.responsiveValue(context, 16),),
                        constraints:
                            BoxConstraints(maxWidth: AppSizes.responsiveValue(context, 250), minHeight: AppSizes.responsiveValue(context, 20),),
                        child: DateTimeFormField(
                          decoration: InputDecoration(
                            hintText: 'Choisir pour une date',
                            hintStyle: GoogleFonts.roboto(
                                fontSize: 14, color: Colors.white),
                            fillColor: const Color.fromARGB(255, 255, 136, 0),
                            // Color.fromARGB(255, 82, 119, 175),
                            filled: true,
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(20),
                              borderSide: BorderSide.none,
                            ),
                            prefixIcon: const Icon(Icons.calendar_month_rounded,
                                color: Colors.white, size: 28),
                          ),
                          hideDefaultSuffixIcon: true,
                          mode: DateTimeFieldPickerMode.date,
                          initialValue: null,
                          onChanged: (DateTime? value) {
                            if (value != null) {
                              setState(() {
                                selectedDate = value;
                              });
                            }
                          },
                          style: GoogleFonts.roboto(
                              fontSize: 12, color: Colors.white),
                        ),
                      );
                    }),
                  ],
                ),
              ),
            ),
            SliverToBoxAdapter(
              child: StreamBuilder<List<VentesModel>>(
                stream: _streamController.stream,
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Center(child: CircularProgressIndicator());
                  } else if (snapshot.hasError) {
                    return Center(
                        child: Container(
                      padding: EdgeInsets.all(AppSizes.responsiveValue(context, 8),),
                      // height: 120,
                      width: MediaQuery.of(context).size.width * 0.9,
                      height: MediaQuery.of(context).size.width * 0.4,
                      decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(20)),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Padding(
                            padding: const EdgeInsets.all(0.0),
                            child: SizedBox(
                                width: MediaQuery.of(context).size.width * 0.7,
                                child: Text(
                                  "Erreur de chargement des données. Réessayer en tirant l'ecrans vers le bas !!",
                                  style: GoogleFonts.roboto(
                                      fontSize: AppSizes.fontMedium),
                                )),
                          ),
                          SizedBox(width: AppSizes.responsiveValue(context, 40),),
                          IconButton(
                              onPressed: () {
                                _refresh();
                              },
                              icon: const Icon(Icons.refresh_outlined,
                                  size: AppSizes.iconLarge))
                        ],
                      ),
                    ));
                  } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
                    return const Text("Aucun produit disponible.");
                  } else {
                    final List<VentesModel> articles = snapshot.data!;

                    // Filtrer les articles par la date sélectionnée
                    // Filtrer les articles par la date sélectionnée, sinon afficher tous les articles
                    filteredArticles = selectedDate == null
                        ? articles
                        : articles.where((article) {
                            // Vérifier si `article.dateVente` n'est pas null également
                            if (selectedDate != null) {
                              return article.dateVente.year ==
                                      selectedDate!.year &&
                                  article.dateVente.month ==
                                      selectedDate!.month &&
                                  article.dateVente.day == selectedDate!.day;
                            }
                            return false;
                          }).toList();

                    if (filteredArticles.isEmpty) {
                      return const Text(
                          "Aucun article trouvé pour la date sélectionnée.");
                    }

                    return SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      child: Container(
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(10),
                          color: const Color.fromARGB(255, 235, 235, 235),
                        ),
                        child: DataTable(
                          columnSpacing: 1,
                          columns: [
                            DataColumn(
                              label: Expanded(
                                child: Container(
                                  color: Colors.orange,
                                  constraints: BoxConstraints(
                                    maxWidth: MediaQuery.of(context).size.width,
                                  ),
                                  padding:  EdgeInsets.all(AppSizes.responsiveValue(context, 5),),
                                  child: Text(
                                    "Name",
                                    style: GoogleFonts.roboto(
                                      fontSize: AppSizes.fontMedium,
                                      fontWeight: FontWeight.bold,
                                      color: Colors.white,
                                    ),
                                  ),
                                ),
                              ),
                            ),
                            DataColumn(
                              label: Expanded(
                                child: Container(
                                  color: Colors.orange,
                                  padding:  EdgeInsets.all(AppSizes.responsiveValue(context, 5),),
                                  child: Text(
                                    "Categories",
                                    style: GoogleFonts.roboto(
                                      fontSize: AppSizes.fontMedium,
                                      fontWeight: FontWeight.bold,
                                      color: Colors.white,
                                    ),
                                  ),
                                ),
                              ),
                            ),
                            DataColumn(
                              label: Expanded(
                                child: Container(
                                  color: Colors.orange,
                                  padding: EdgeInsets.all(AppSizes.responsiveValue(context, 5),),
                                  child: Text(
                                    "Prix d'achat",
                                    style: GoogleFonts.roboto(
                                      fontSize: AppSizes.fontMedium,
                                      fontWeight: FontWeight.bold,
                                      color: Colors.white,
                                    ),
                                  ),
                                ),
                              ),
                            ),
                            DataColumn(
                              label: Expanded(
                                child: Container(
                                  color: Colors.orange,
                                  padding:  EdgeInsets.all(AppSizes.responsiveValue(context, 5),),
                                  child: Text(
                                    "Prix de vente",
                                    style: GoogleFonts.roboto(
                                      fontSize: AppSizes.fontMedium,
                                      fontWeight: FontWeight.bold,
                                      color: Colors.white,
                                    ),
                                  ),
                                ),
                              ),
                            ),
                            DataColumn(
                              label: Expanded(
                                child: Container(
                                  color: Colors.orange,
                                  padding:  EdgeInsets.all(AppSizes.responsiveValue(context, 5),),
                                  child: Text(
                                    "Quantités",
                                    style: GoogleFonts.roboto(
                                      fontSize: AppSizes.fontMedium,
                                      fontWeight: FontWeight.bold,
                                      color: Colors.white,
                                    ),
                                  ),
                                ),
                              ),
                            ),
                            DataColumn(
                              label: Expanded(
                                child: Container(
                                  color: Colors.orange,
                                  padding:  EdgeInsets.all(AppSizes.responsiveValue(context, 5),),
                                  child: Text(
                                    "Somme",
                                    style: GoogleFonts.roboto(
                                      fontSize: AppSizes.fontMedium,
                                      fontWeight: FontWeight.bold,
                                      color: Colors.white,
                                    ),
                                  ),
                                ),
                              ),
                            ),
                            DataColumn(
                              label: Expanded(
                                child: Container(
                                  color: Colors.orange,
                                  padding:  EdgeInsets.all(AppSizes.responsiveValue(context, 5),),
                                  child: Text(
                                    "Benefices",
                                    style: GoogleFonts.roboto(
                                      fontSize: AppSizes.fontMedium,
                                      fontWeight: FontWeight.bold,
                                      color: Colors.white,
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          ],
                          rows: filteredArticles.map((article) {
                            final somme = article.prixVente * article.qty;
                            final benefices =
                                somme - (article.prixAchat * article.qty);

                            return DataRow(
                              cells: [
                                DataCell(
                                  Container(
                                    padding:  EdgeInsets.all(AppSizes.responsiveValue(context, 5),),
                                    child: Text(
                                      article.nom,
                                      style: GoogleFonts.roboto(
                                        fontSize: AppSizes.fontMedium,
                                      ),
                                    ),
                                  ),
                                ),
                                DataCell(
                                  Container(
                                    padding:  EdgeInsets.all(AppSizes.responsiveValue(context, 5),),
                                    child: Text(
                                      article.categories,
                                      style: GoogleFonts.roboto(
                                        fontSize: AppSizes.fontMedium,
                                      ),
                                    ),
                                  ),
                                ),
                                DataCell(
                                  Container(
                                    padding:  EdgeInsets.all(AppSizes.responsiveValue(context, 5),),
                                    child: Text(
                                      "${article.prixAchat.toStringAsFixed(2)} XOF",
                                      style: GoogleFonts.roboto(
                                        fontSize: AppSizes.fontMedium,
                                      ),
                                    ),
                                  ),
                                ),
                                DataCell(
                                  Container(
                                    padding: EdgeInsets.all(AppSizes.responsiveValue(context, 5),),
                                    child: Text(
                                      "${article.prixVente.toStringAsFixed(2)} XOF",
                                      style: GoogleFonts.roboto(
                                        fontSize: AppSizes.fontMedium,
                                      ),
                                    ),
                                  ),
                                ),
                                DataCell(
                                  Container(
                                    padding:  EdgeInsets.all(AppSizes.responsiveValue(context, 5),),
                                    child: Text(
                                      article.qty.toString(),
                                      style: GoogleFonts.roboto(
                                        fontSize: AppSizes.fontMedium,
                                      ),
                                    ),
                                  ),
                                ),
                                DataCell(
                                  Container(
                                    padding:  EdgeInsets.all(AppSizes.responsiveValue(context, 5),),
                                    child: Text(
                                      "${somme.toStringAsFixed(2)} XOF",
                                      style: GoogleFonts.roboto(
                                        fontSize: AppSizes.fontMedium,
                                      ),
                                    ),
                                  ),
                                ),
                                DataCell(
                                  Container(
                                    padding:  EdgeInsets.all(AppSizes.responsiveValue(context, 5),),
                                    child: Text(
                                      "${benefices.toStringAsFixed(2)} XOF",
                                      style: GoogleFonts.roboto(
                                        fontSize: AppSizes.fontMedium,
                                      ),
                                    ),
                                  ),
                                ),
                              ],
                            );
                          }).toList(),
                        ),
                      ),
                    );
                  }
                },
              ),
            ),
          ],
        ),
      ),
      bottomNavigationBar: LayoutBuilder(builder: (context, constraints) {
        return Container(
          width: constraints.maxWidth,
          padding: EdgeInsets.symmetric(horizontal: AppSizes.responsiveValue(context, 15), vertical: AppSizes.responsiveValue(context, 20)),
          height: AppSizes.responsiveValue(context, 150),
          decoration: BoxDecoration(
              color: const Color.fromARGB(255, 248, 248, 248),
              border: Border.all(
                  width: 1, color: const Color.fromARGB(255, 207, 212, 233))),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              SizedBox(
                width: AppSizes.responsiveValue(context, 100),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    FittedBox(
                      fit: BoxFit.scaleDown,
                      child: Text(
                        "Rapport du",
                        style:
                            GoogleFonts.roboto(fontSize: AppSizes.fontMedium),
                      ),
                    ),
                    FittedBox(
                      fit: BoxFit.scaleDown,
                      child: Text(
                          selectedDate != null
                              ? DateFormat("dd MMM yyyy").format(selectedDate!)
                              : 'general',
                          style: GoogleFonts.roboto(
                              fontSize: AppSizes.fontMedium)),
                    ),
                    IconButton(
                      onPressed: () {
                        _printReceipt(context, filteredArticles);
                      },
                      icon: const Icon(Icons.print, size: AppSizes.iconLarge),
                    ),
                  ],
                ),
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      SizedBox(
                        width: constraints.maxWidth * 0.40,
                        child: FittedBox(
                          fit: BoxFit.scaleDown,
                          child: Text(
                            "Produit ",
                            style: GoogleFonts.roboto(
                                fontSize: AppSizes.fontMedium),
                          ),
                        ),
                      ),
                      FittedBox(
                        fit: BoxFit.scaleDown,
                        child: Text(nombreTotalDeProduit().toString(),
                            style: GoogleFonts.roboto(
                                fontSize: AppSizes.fontMedium)),
                      ),
                    ],
                  ),
                  Row(
                    children: [
                      SizedBox(
                        width: constraints.maxWidth * 0.40,
                        child: FittedBox(
                          fit: BoxFit.scaleDown,
                          child: Text(
                            "Total",
                            style: GoogleFonts.roboto(
                                fontSize: AppSizes.fontMedium),
                          ),
                        ),
                      ),
                      FittedBox(
                        fit: BoxFit.scaleDown,
                        child: Text("${sommeTotal().toString()} XOF",
                            style: GoogleFonts.roboto(
                                fontSize: AppSizes.fontMedium)),
                      ),
                    ],
                  ),
                  Row(
                    children: [
                      SizedBox(
                        width: constraints.maxWidth * 0.40,
                        child: FittedBox(
                          fit: BoxFit.scaleDown,
                          child: Text(
                            "Benefices",
                            style: GoogleFonts.roboto(
                                fontSize: AppSizes.fontMedium),
                          ),
                        ),
                      ),
                      FittedBox(
                        fit: BoxFit.scaleDown,
                        child: Text("${beneficeTotal().toString()} XOF",
                            style: GoogleFonts.roboto(
                                fontSize: AppSizes.fontMedium)),
                      ),
                    ],
                  ),
                ],
              ),
            ],
          ),
        );
      }),
    );
  }

  Future<void> _printReceipt(
      BuildContext context, List<VentesModel> rapport) async {
    final pdf = pw.Document();
    final store = Provider.of<AuthProvider>(context, listen: false).societeName;
    final date = DateFormat("dd MMM yyyy").format(selectedDate!);

    //somme total
    //calcule somme total
    sommeTotal() {
      if (rapport.isEmpty) return 0;
      return rapport.map((x) => x.prixVente * x.qty).reduce((a, b) => a + b);
    }

    // Calculer le bénéfice total
    calculBenefice() {
      return rapport.map((article) {
        return ((article.prixVente - article.prixAchat) * article.qty);
      }).reduce((a, b) => a + b);
    }

    //quantite total de produit
    int nombreTotalDeProduit() {
      return rapport.map((a) => a.qty).reduce((a, b) => a + b);
    }

    // Ajouter les détails du reçu au PDF
    pdf.addPage(
      pw.Page(
        build: (pw.Context context) {
          return pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              pw.Text(
                store,
                style:
                    pw.TextStyle(fontSize: 24, fontWeight: pw.FontWeight.bold),
              ),
              pw.SizedBox(height: 10),
              pw.Text("Rapport du: $date",
                  style: pw.TextStyle(
                      fontSize: 12, fontWeight: pw.FontWeight.bold)),
              pw.SizedBox(height: 10),
              // ignore: deprecated_member_use
              pw.Table.fromTextArray(
                headers: [
                  'Nom',
                  'Catégorie',
                  'Prix Achat',
                  'Prix Vente',
                  'Quantité',
                  'Total',
                  'Bénéfices'
                ],
                data: rapport.map((article) {
                  final somme = article.prixVente * article.qty;
                  final benefice = somme - (article.prixAchat * article.qty);
                  return [
                    article.nom,
                    article.categories,
                    article.prixAchat.toStringAsFixed(2),
                    article.prixVente.toStringAsFixed(2),
                    article.qty.toString(),
                    somme.toStringAsFixed(2),
                    benefice.toStringAsFixed(2),
                  ];
                }).toList(),
              ),
              pw.SizedBox(height: 20),
              pw.Text(
                "Nombre de produit total: ${nombreTotalDeProduit().toStringAsFixed(2)}",
                style:
                    pw.TextStyle(fontSize: 14, fontWeight: pw.FontWeight.bold),
              ),
              pw.SizedBox(height: 20),
              pw.Text(
                "Somme total: ${sommeTotal().toStringAsFixed(2)} XOF",
                style:
                    pw.TextStyle(fontSize: 14, fontWeight: pw.FontWeight.bold),
              ),
              pw.SizedBox(height: 20),
              pw.Text(
                "Bénéfice total: ${calculBenefice().toStringAsFixed(2)} XOF",
                style:
                    pw.TextStyle(fontSize: 14, fontWeight: pw.FontWeight.bold),
              ),
            ],
          );
        },
      ),
    );

    // Impression ou exportation du PDF
    await Printing.layoutPdf(
        onLayout: (PdfPageFormat format) async => pdf.save());
  }
}
