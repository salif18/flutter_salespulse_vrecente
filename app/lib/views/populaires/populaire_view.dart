import 'dart:async';
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:salespulse/models/stats_categorie_model.dart';
import 'package:salespulse/providers/auth_provider.dart';
import 'package:salespulse/services/stats_api.dart';
import 'package:salespulse/utils/app_size.dart';

class PopulaireView extends StatefulWidget {
  const PopulaireView({super.key});

  @override
  State<PopulaireView> createState() => _PopulaireViewState();
}

class _PopulaireViewState extends State<PopulaireView> {
  final GlobalKey<ScaffoldState> drawerKey = GlobalKey<ScaffoldState>();
  DateTime selectedDate = DateTime.now();
  ServicesStats api = ServicesStats();
  final StreamController<List<ProduitBestVendu>> _streamController =
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

  Future<void> _loadProducts() async {
    try {
      final token = Provider.of<AuthProvider>(context, listen: false).token;
      final userId = Provider.of<AuthProvider>(context, listen: false).userId;
      final res = await api.getStatsByCategories(token, userId);
      final body = jsonDecode(res.body);

      if (res.statusCode == 200) {
        final products = (body["results"] as List)
            .map((json) => ProduitBestVendu.fromJson(json))
            .toList();

        if (!_streamController.isClosed) {
          _streamController.add(products); // Ajouter les produits au stream
        }
      } else {
        if (!_streamController.isClosed) {
          _streamController.addError("Failed to load products");
        }
      }
    } catch (e) {
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
    return Scaffold(
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
              expandedHeight: 100,
              pinned: true,
              floating: true,
              centerTitle: true,
              leading: IconButton(
                  onPressed: () {
                    Navigator.pop(context);
                  },
                  icon: const Icon(Icons.arrow_back_ios_new,
                      size: AppSizes.iconHyperLarge, color: Colors.white)),
              flexibleSpace: FlexibleSpaceBar(
                title: Text(
                  "Les plus achetés",
                  style: GoogleFonts.roboto(
                      fontSize: AppSizes.fontLarge, color: Colors.white),
                ),
              ),
            ),
            SliverToBoxAdapter(
              child: Center(
                child: StreamBuilder<List<ProduitBestVendu>>(
                  stream: _streamController.stream,
                  builder: (context, snapshot) {
                    if (snapshot.connectionState == ConnectionState.waiting) {
                      return const Center(child: CircularProgressIndicator());
                    } else if (snapshot.hasError) {
                      return Center(
                          child: Container(
                        padding: const EdgeInsets.all(8),
                        height: MediaQuery.of(context).size.width * 0.4,
                        width: MediaQuery.of(context).size.width * 0.9,
                        decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(20)),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Padding(
                              padding: const EdgeInsets.all(8.0),
                              child: SizedBox(
                                width: MediaQuery.of(context).size.width * 0.6,
                               
                                child: Text(
                                  "Erreur de chargement des données. Verifier votre réseau de connexion. Réessayer en tirant l'ecrans vers le bas!!",
                                  style: GoogleFonts.roboto(
                                      fontSize: AppSizes.fontMedium),
                                ))
                            ),
                            const SizedBox(width: 40),
                            IconButton(
                                onPressed: () {
                                  _refresh();
                                },
                                icon:const Icon(Icons.refresh_outlined,
                                    size: AppSizes.iconLarge))
                          ],
                        ),
                      ));
                    } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
                      return const Text("Aucun produit disponible.");
                    } else {
                      final List<ProduitBestVendu> articles = snapshot.data!;

                      return SingleChildScrollView(
                        scrollDirection: Axis.horizontal,
                        child: Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(10),
                            color: Colors.white,
                          ),
                          child: DataTable(
                            columnSpacing: 10,
                            columns: [
                              DataColumn(
                                label: Container(
                                  padding: const EdgeInsets.all(5),
                                  child: Text(
                                    "Name",
                                    style: GoogleFonts.roboto(
                                      fontSize: AppSizes.fontMedium,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ),
                              ),
                              DataColumn(
                                label: Container(
                                  padding: const EdgeInsets.all(5),
                                  child: Text(
                                    "Categories",
                                    style: GoogleFonts.roboto(
                                      fontSize: AppSizes.fontMedium,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ),
                              ),
                              DataColumn(
                                label: Container(
                                  padding: const EdgeInsets.all(5),
                                  child: Text(
                                    "Nombre d'achat",
                                    style: GoogleFonts.roboto(
                                      fontSize: AppSizes.fontMedium,
                                      fontWeight: FontWeight.bold,
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
                                      padding: const EdgeInsets.all(5),
                                      child: Text(
                                        article.id.nom,
                                        style: GoogleFonts.roboto(
                                          fontSize: AppSizes.fontMedium,
                                        ),
                                      ),
                                    ),
                                  ),
                                  DataCell(
                                    Container(
                                      padding: const EdgeInsets.all(5),
                                      child: Text(
                                        article.id.categories,
                                        style: GoogleFonts.roboto(
                                          fontSize: AppSizes.fontMedium,
                                        ),
                                      ),
                                    ),
                                  ),
                                  DataCell(
                                    Container(
                                      padding: const EdgeInsets.all(5),
                                      child: Text(
                                        article.totalVendu.toString(),
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
            )
          ],
        ),
      ),
    );
  }
}
