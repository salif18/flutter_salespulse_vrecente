import 'dart:async';
import 'dart:io';
import 'dart:math';

import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:salespulse/models/categories_model.dart';
import 'package:salespulse/providers/auth_provider.dart';
import 'package:salespulse/services/categ_api.dart';
import 'package:salespulse/utils/app_size.dart';

class CategoriesView extends StatefulWidget {
  const CategoriesView({super.key});

  @override
  State<CategoriesView> createState() => _CategoriesViewState();
}

class _CategoriesViewState extends State<CategoriesView> {
  ServicesCategories api = ServicesCategories();
  final GlobalKey<ScaffoldState> drawerKey = GlobalKey<ScaffoldState>();
  final GlobalKey<FormState> _globalKey = GlobalKey<FormState>();
  final StreamController<List<CategoriesModel>> _listCategories =
      StreamController<List<CategoriesModel>>();
  final _categorieName = TextEditingController();

  @override
  void initState() {
    _getCategories();
    super.initState();
  }

  @override
  void dispose() {
    _listCategories.close();
    _categorieName.dispose();
    super.dispose();
  }

  // OBTENIR LES CATEGORIES API
  Future<void> _getCategories() async {
    final token = Provider.of<AuthProvider>(context, listen: false).token;
    final userId = Provider.of<AuthProvider>(context, listen: false).userId;
    try {
      final res = await api.getCategories(userId, token);
      final body = res.data;
      if (res.statusCode == 200) {
        setState(() {
          final products = (body["results"] as List)
              .map((json) => CategoriesModel.fromJson(json))
              .toList();
          _listCategories.add(products);
        });
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
      Exception(e); // Ajout d'une impression pour le debug
    }
  }

//SUPPRIMER CATEGORIE API
  Future<void> _removeCategories(id) async {
    final token = Provider.of<AuthProvider>(context, listen: false).token;
    try {
      final res = await api.deleteCategories(id, token);
      final body = res.data;
      if (res.statusCode == 200) {
        // ignore: use_build_context_synchronously
        api.showSnackBarSuccessPersonalized(context, body["message"]);
        _getCategories(); // Actualiser la liste des catégories
      } else {
        // ignore: use_build_context_synchronously
        api.showSnackBarErrorPersonalized(context, body["message"]);
      }
    } catch (e) {
      // ignore: use_build_context_synchronously
      api.showSnackBarErrorPersonalized(context, e.toString());
    }
  }

//AJOUTER CATEGORIE API
  Future<void> _sendToserver(BuildContext context) async {
    final token = Provider.of<AuthProvider>(context, listen: false).token;
    final userId = Provider.of<AuthProvider>(context, listen: false).userId;
    if (_globalKey.currentState!.validate()) {
      final data = {
        "userId": userId,
        "name": _categorieName.text,
      };
      try {
        showDialog(
          context: context,
          builder: (context) {
            return const Center(
              child: CircularProgressIndicator(),
            );
          },
        );
        final res = await api.postCategories(data, token);
        // ignore: use_build_context_synchronously
        Navigator.pop(context); // Fermer le dialog

        if (res.statusCode == 201) {
          // ignore: use_build_context_synchronously
          api.showSnackBarSuccessPersonalized(context, res.data["message"]);
          // ignore: use_build_context_synchronously
          Navigator.push(context,
              MaterialPageRoute(builder: (context) => const CategoriesView()));
        } else {
          // ignore: use_build_context_synchronously
          api.showSnackBarErrorPersonalized(context, res.data["message"]);
        }
      } on SocketException {
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
        // ignore: use_build_context_synchronously
        Navigator.pop(context); // Fermer le dialog
        // ignore: use_build_context_synchronously
        api.showSnackBarErrorPersonalized(context, e.toString());
      }
    }
  }

  //rafraichire la page en actualisanst la requete
  Future<void> _refresh() async {
    await Future.delayed(const Duration(seconds: 3));
    if (mounted) {
      // Vérifier si le widget est monté avant d'appeler setState()
      setState(() {
        _getCategories(); // Rafraîchir les produits
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: CustomScrollView(slivers: [
        SliverAppBar(
          backgroundColor: const Color(0xff001c30),
          toolbarHeight: min(AppSizes.responsiveValue(context, 80.0),80),
          pinned: true,
          floating: true,
          leading: IconButton(
              onPressed: () => Navigator.pop(context),
              icon: Icon(Icons.arrow_back_ios_new_outlined,
                  color: Colors.white, size: min(AppSizes.responsiveValue(context, 24.0),30),)),
          flexibleSpace: FlexibleSpaceBar(
            title: Text(
              "Liste des catégories",
              style: GoogleFonts.roboto(
                  fontSize: min(AppSizes.responsiveValue(context, 15.0),24), color: Colors.white),
            ),
          ),
        ),
        StreamBuilder<List<CategoriesModel>>(
          stream: _listCategories.stream,
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const SliverFillRemaining(
                child: Center(child: CircularProgressIndicator()),
              );
            } else if (snapshot.hasError) {
              return SliverFillRemaining(
                child: Center(
                    child: Container(
                  padding: EdgeInsets.all(AppSizes.responsiveValue(context, 8.0)),
                  height: MediaQuery.of(context).size.width * 0.4,
                  width: MediaQuery.of(context).size.width * 0.9,
                  decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(20)),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Padding(
                        padding: EdgeInsets.all(AppSizes.responsiveValue(context, 0.0)),
                        child: SizedBox(
                                width: MediaQuery.of(context).size.width * 0.7,                          
                                child: Text(
                                  "Erreur de chargement des données. Réessayer en tirant l'ecrans vers le bas !!",
                                  style: GoogleFonts.roboto(
                                      fontSize: AppSizes.fontMedium),
                                ))
                      ),
                      SizedBox(width: AppSizes.responsiveValue(context, 40.0)),
                      IconButton(
                          onPressed: () {
                            _refresh();
                          },
                          icon:const Icon(Icons.refresh_outlined,
                              size: AppSizes.iconLarge))
                    ],
                  ),
                )),
              );
            } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
              return const SliverToBoxAdapter(
                child: Center(
                  child: Text("Pas de données disponibles"),
                ),
              );
            } else {
              return SliverList(
                delegate: SliverChildBuilderDelegate(
                  (context, index) {
                    CategoriesModel categorie = snapshot.data![index];
                    return Dismissible(
                      key: Key(categorie.id.toString()),
                      direction: DismissDirection.endToStart,
                      onDismissed: (direction) {
                        _removeCategories(categorie.id);
                      },
                      confirmDismiss: (direction) async {
                        return await showRemoveCategorie(context);
                      },
                      background: Container(
                        color: Colors.red,
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.end,
                          children: [
                            const Icon(Icons.delete_outline,
                                color: Colors.white, size: AppSizes.iconLarge),
                            SizedBox(width: AppSizes.responsiveValue(context, 50.0)),
                          ],
                        ),
                      ),
                      child: Container(
                        decoration: const BoxDecoration(
                            color: Color.fromARGB(255, 235, 235, 235),
                            border: Border(
                                bottom: BorderSide(
                                    color:
                                        Color.fromARGB(255, 255, 255, 255)))),
                        child: ListTile(
                          title: Text(
                            categorie.name,
                            style: GoogleFonts.roboto(
                                fontSize: min(AppSizes.responsiveValue(context, 14.0),20),),
                          ),
                        ),
                      ),
                    );
                  },
                  childCount: snapshot.data!.length,
                ),
              );
            }
          },
        ),
      ]),
      floatingActionButton: FloatingActionButton(
        backgroundColor:const Color.fromARGB(255, 255, 136, 0),
        onPressed: () {
          _addCateShow(context);
        },
        child: Icon(
          Icons.add,
          size: min(AppSizes.responsiveValue(context, 24.0),30),
          color: Colors.white,
        ),
      ),
    );
  }

//FENETRE POUR AJOUTER CATEGORIE
  void _addCateShow(BuildContext context) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Center(
            child: Text(
              "Ajouter categories",
              style: GoogleFonts.roboto(
                fontSize: min(AppSizes.responsiveValue(context, 14.0),20),
                fontWeight: FontWeight.w400,
              ),
            ),
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Form(
                key: _globalKey,
                child: Column(
                  children: [
                    TextFormField(
                      controller: _categorieName,
                      validator: (value) {
                        if (value!.isEmpty) {
                          return 'Veuillez entrer une categorie';
                        }
                        return null;
                      },
                      decoration: InputDecoration(
                        hintText: "Nom de la categorie",
                        hintStyle:
                            GoogleFonts.roboto(fontSize: min(AppSizes.responsiveValue(context, 14.0),20),),
                        prefixIcon: Icon(
                          Icons.category_rounded,
                          size: min(AppSizes.responsiveValue(context, 14.0),20),
                          color: Colors.purpleAccent,
                        ),
                        isDense: true, // Réduit la hauteur
                              contentPadding: EdgeInsets.symmetric(vertical: AppSizes.responsiveValue(context, 8.0)),
                      ),
                    ),
                    SizedBox(height: AppSizes.responsiveValue(context, 20.0)),
                    ElevatedButton(
                      onPressed: () {
                        _sendToserver(context);
                        Navigator.pop(context);
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor:const Color.fromARGB(255, 255, 136, 0),
                        minimumSize: Size(
                          min(AppSizes.responsiveValue(context, 400.0),420),
                         min(AppSizes.responsiveValue(context, 40.0),60),),
                      ),
                      child: Text(
                        "Enregistrer",
                        style: GoogleFonts.roboto(
                          fontSize: min(AppSizes.responsiveValue(context, 14.0),20),
                          fontWeight: FontWeight.w400,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }

// FENTRE DIALOGUE POUR CONFIRMER LA SUPPRESSION
  Future<bool> showRemoveCategorie(BuildContext context) async {
    return await showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text("Confirmer"),
          content: const Text(
              "Êtes-vous sûr de vouloir supprimer cette catégorie ?"),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop(false);
              },
              child: Text("Annuler",
                  style: GoogleFonts.roboto(fontSize: AppSizes.fontMedium)),
            ),
            TextButton(
              onPressed: () {
                Navigator.of(context).pop(true);
              },
              child: Text("Supprimer",
                  style: GoogleFonts.roboto(fontSize: AppSizes.fontMedium)),
            ),
          ],
        );
      },
    );
  }
}
