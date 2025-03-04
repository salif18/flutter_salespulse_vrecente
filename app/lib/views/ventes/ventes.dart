import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:math';
import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:salespulse/components/drawer.dart';
import 'package:salespulse/models/ventes_model.dart';
import 'package:salespulse/providers/auth_provider.dart';
import 'package:salespulse/services/vente_api.dart';
import 'package:salespulse/utils/app_size.dart';
import 'package:salespulse/views/populaires/populaire_view.dart';

class VenteView extends StatefulWidget {
  const VenteView({super.key});

  @override
  State<VenteView> createState() => _VenteViewState();
}

class _VenteViewState extends State<VenteView> {
  final GlobalKey<ScaffoldState> drawerKey = GlobalKey<ScaffoldState>();
  ServicesVentes api = ServicesVentes();

  final StreamController<List<VentesModel>> _streamController =
      StreamController();

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

  //rafraichire la page en actualisanst la requete
  Future<void> _refresh() async {
    await Future.delayed(const Duration(seconds: 3));
    if (mounted) {
      // Vérifie que le widget est toujours monté avant de mettre à jour l'état
      setState(() {
        _loadProducts();
      });
    }
  }

  // Fonction pour récupérer les produits depuis le serveur et ajouter au stream
  Future<void> _loadProducts() async {
     final token = Provider.of<AuthProvider>(context, listen: false).token;
      final userId = Provider.of<AuthProvider>(context, listen: false).userId;
    
    try {
     
      final res = await api.getAllVentes(token, userId);
      final body = res.data;
      if (res.statusCode == 200) {
        final products = (body["results"] as List)
            .map((json) => VentesModel.fromJson(json))
            .toList();
       
        if (!_streamController.isClosed) {
          _streamController.add(products); // Ajouter les produits au stream
        } else {
          print("StreamController is closed, cannot add products.");
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
        _streamController.addError("Erreur lors de la requête : $e");
      }
    }
  }

  Future<void> _removeArticles(article) async {
    final token = Provider.of<AuthProvider>(context, listen: false).token;
    try {
      final res = await api.deleteVentes(article.venteId, token);
      final body = jsonDecode(res.body);
      if (res.statusCode == 200) {
        // ignore: use_build_context_synchronously
        Navigator.pop(context);
        // ignore: use_build_context_synchronously
        api.showSnackBarSuccessPersonalized(context, body["message"]);
      } else {
        // ignore: use_build_context_synchronously
        api.showSnackBarErrorPersonalized(context, body["message"]);
      }
    } catch (e) {
      // ignore: use_build_context_synchronously
      api.showSnackBarErrorPersonalized(context, e.toString());
    }
  }

  @override
  Widget build(BuildContext context) {
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
              expandedHeight:  min(AppSizes.responsiveValue(context, 100.0),80),
              pinned: true,
              floating: true,
              leading: IconButton(
                  onPressed: () {
                    drawerKey.currentState!.openDrawer();
                  },
                  icon: Icon(Icons.sort,
                      size: min(AppSizes.responsiveValue(context, 24.0),38), color: Color.fromARGB(255, 255, 136, 0),)),
              flexibleSpace: FlexibleSpaceBar(
                title: Text("Ventes",
                    style: GoogleFonts.roboto(
                        fontSize: min(AppSizes.responsiveValue(context, 16.0),24), color: Colors.white)),
              ),
            ),
            SliverToBoxAdapter(
              child: Container(
                color: const Color(0xff001c30),
                height:  min(AppSizes.responsiveValue(context, 120.0),100),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    ElevatedButton.icon(
                      onPressed: () {
                        Navigator.push(
                            context,
                            MaterialPageRoute(
                                builder: (context) => const PopulaireView()));
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.orange,
                        maximumSize: Size(min(AppSizes.responsiveValue(context, 200.0),250), min(AppSizes.responsiveValue(context, 40.0),60),)
                      ),
                      label: Text(
                        "Les plus achetés",
                        style: GoogleFonts.roboto(
                            fontSize: min(AppSizes.responsiveValue(context, 14.0),20), color: Colors.white),
                      ),
                      icon: const Icon(Icons.workspace_premium,
                          color: Color.fromARGB(255, 255, 255, 255), size: 30),
                    ),
                    SizedBox(
                      width:  AppSizes.responsiveValue(context, 20)
                    )
                  ],
                ),
              ),
            ),
            StreamBuilder<List<VentesModel>>(
              stream: _streamController.stream,
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const SliverFillRemaining(
                    child: Center(child: CircularProgressIndicator()),
                  );
                } else if (snapshot.hasError) {
                   print("Erreur: ${snapshot.error}");
                  return SliverFillRemaining(
                      child: Center(
                          child: Container(
                    padding: const EdgeInsets.all(8),
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
                                ))),
                        SizedBox(width:  AppSizes.responsiveValue(context, 40)),
                        IconButton(
                            onPressed: () {
                              _refresh();
                            },
                            icon: const Icon(Icons.refresh_outlined,
                                size: AppSizes.iconLarge))
                      ],
                    ),
                  )));
                } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
                  return const SliverFillRemaining(
                    child: Center(
                      child: Text("Aucun produit disponible."),
                    ),
                  );
                } else {
                  final List<VentesModel> articles = snapshot.data!;

                  return SliverToBoxAdapter(
                    child: SingleChildScrollView(
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
                                    // maxWidth: MediaQuery.of(context).size.width,
                                  ),
                                  padding: EdgeInsets.all( min(AppSizes.responsiveValue(context, 5.0),5),),
                                  child: Text(
                                    "Name",
                                    style: GoogleFonts.roboto(
                                      fontSize: min(AppSizes.responsiveValue(context, 14.0),20),
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
                                  padding: EdgeInsets.all( min(AppSizes.responsiveValue(context, 5.0),5),),
                                  child: Text(
                                    "Categories",
                                    style: GoogleFonts.roboto(
                                      fontSize: min(AppSizes.responsiveValue(context, 14.0),20),
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
                                  padding:  EdgeInsets.all(min(AppSizes.responsiveValue(context, 5),5),),
                                  child: Text(
                                    "Prix de vente",
                                    style: GoogleFonts.roboto(
                                      fontSize: min(AppSizes.responsiveValue(context, 14.0),20),
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
                                  padding: EdgeInsets.all(min(AppSizes.responsiveValue(context,5),5),),
                                  child: Text(
                                    "Quantités",
                                    style: GoogleFonts.roboto(
                                      fontSize: min(AppSizes.responsiveValue(context, 14.0),20),
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
                                  padding: EdgeInsets.all(min(AppSizes.responsiveValue(context, 5.0),5),),
                                  child: Text(
                                    "Date",
                                    style: GoogleFonts.roboto(
                                      fontSize: min(AppSizes.responsiveValue(context, 14.0),20),
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
                                  padding: EdgeInsets.all(min(AppSizes.responsiveValue(context, 5),5),),
                                  child: Text(
                                    "Actions",
                                    style: GoogleFonts.roboto(
                                      fontSize: min(AppSizes.responsiveValue(context, 14.0),20),
                                      fontWeight: FontWeight.bold,
                                      color: Colors.white,
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          ],
                          rows: articles.map((article) {
                            return DataRow(
                              cells: [
                                DataCell(
                                  Container(
                                    padding: EdgeInsets.all(min(AppSizes.responsiveValue(context, 5.0),5),),
                                    child: Text(
                                      article.nom,
                                      style: GoogleFonts.roboto(
                                        fontSize: min(AppSizes.responsiveValue(context, 12.0),20),
                                      ),
                                    ),
                                  ),
                                ),
                                DataCell(
                                  Container(
                                    padding:EdgeInsets.all(min(AppSizes.responsiveValue(context,5),5),),
                                    child: Text(
                                      article.categories,
                                      style: GoogleFonts.roboto(
                                        fontSize: min(AppSizes.responsiveValue(context, 12.0),20),
                                      ),
                                    ),
                                  ),
                                ),
                                DataCell(
                                  Container(
                                    padding: EdgeInsets.all(min(AppSizes.responsiveValue(context, 5.0),5),),
                                    child: Text(
                                      "${article.prixVente} XOF",
                                      style: GoogleFonts.roboto(
                                        fontSize:min(AppSizes.responsiveValue(context, 12.0),20),
                                      ),
                                    ),
                                  ),
                                ),
                                DataCell(
                                  Container(
                                    padding: EdgeInsets.all(min(AppSizes.responsiveValue(context, 5),5),),
                                    child: Text(
                                      article.qty.toString(),
                                      style: GoogleFonts.roboto(
                                        fontSize: min(AppSizes.responsiveValue(context, 12.0),20),
                                      ),
                                    ),
                                  ),
                                ),
                                DataCell(
                                  Container(
                                    padding: EdgeInsets.all(min(AppSizes.responsiveValue(context, 5.0),5),),
                                    child: Text(
                                      DateFormat("dd MMM yyyy")
                                          .format(article.dateVente),
                                      style: GoogleFonts.roboto(
                                        fontSize: min(AppSizes.responsiveValue(context, 12.0),20),
                                      ),
                                    ),
                                  ),
                                ),
                                DataCell(
                                  Container(
                                    padding: EdgeInsets.all(min(AppSizes.responsiveValue(context, 5),5),),
                                    child: Row(
                                      children: [
                                        Text(
                                          "Annuler",
                                          style: GoogleFonts.roboto(
                                              fontSize: min(AppSizes.responsiveValue(context, 12.0),20),
                                              color: Colors.blue),
                                        ),
                                        IconButton(
                                          icon: const Icon(
                                              Icons.move_down_outlined,
                                              color: Colors.blue),
                                          onPressed: () {
                                            _showAlertDelete(context, article);
                                          },
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                              ],
                            );
                          }).toList(),
                        ),
                      ),
                    ),
                  );
                }
              },
            ),
          ],
        ),
      ),
    );
  }

  Future<bool?> _showAlertDelete(BuildContext context, article) {
    return showDialog<bool>(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text("Annulation de vente"),
          content: const Text(
              "Êtes-vous sûr de vouloir annuler la vente et retourner cet article dans vos stocks ?"),
          actions: <Widget>[
            TextButton(
              onPressed: () => _removeArticles(article),
              child: const Text("Valider"),
            ),
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: const Text("Quitter"),
            ),
          ],
        );
      },
    );
  }
}
