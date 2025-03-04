import 'dart:async';
import 'dart:io';
import 'dart:math';

import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:salespulse/models/fournisseurs_model.dart';
import 'package:salespulse/providers/auth_provider.dart';
import 'package:salespulse/services/fournisseur_api.dart';
import 'package:salespulse/utils/app_size.dart';

class FournisseurView extends StatefulWidget {
  const FournisseurView({super.key});

  @override
  State<FournisseurView> createState() => _FournisseurViewState();
}

class _FournisseurViewState extends State<FournisseurView> {
  ServicesFournisseurs api = ServicesFournisseurs();
  final GlobalKey<ScaffoldState> drawerKey = GlobalKey<ScaffoldState>();
  final GlobalKey<FormState> _globalKey = GlobalKey<FormState>();
  final StreamController<List<FournisseurModel>> _listFournisseurs =
      StreamController<List<FournisseurModel>>();
  final _prenom = TextEditingController();
  final _nom = TextEditingController();
  final _numero = TextEditingController();
  final _address = TextEditingController();
  final _produit = TextEditingController();

  @override
  void initState() {
    _getfournisseurs();
    super.initState();
  }

  @override
  void dispose() {
    _listFournisseurs.close();
    _prenom.dispose();
    _nom.dispose();
    _numero.dispose();
    _address.dispose();
    _produit.dispose();
    super.dispose();
  }

  // OBTENIR LES CATEGORIES API
  Future<void> _getfournisseurs() async {
    final token = Provider.of<AuthProvider>(context, listen: false).token;
    final userId = Provider.of<AuthProvider>(context, listen: false).userId;
    try {
      final res = await api.getFournisseurs(userId, token);
      final body = res.data;
      if (res.statusCode == 200) {
        setState(() {
          final fournisseurs = (body["fournisseurs"] as List)
              .map((json) => FournisseurModel.fromJson(json))
              .toList();
          _listFournisseurs.add(fournisseurs);
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
  Future<void> _removeFournisseur(id) async {
    final token = Provider.of<AuthProvider>(context, listen: false).token;
    try {
      final res = await api.deleteFournisseurs(id, token);
      final body = res.data;
      if (res.statusCode == 200) {
        // ignore: use_build_context_synchronously
        api.showSnackBarSuccessPersonalized(context, body["message"]);
        _getfournisseurs(); // Actualiser la liste des catégories
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
        "prenom": _prenom.text,
        "nom": _nom.text,
        "numero": _numero.text,
        "address": _address.text,
        "produit": _produit.text
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
        final res = await api.postFournisseur(data, token);
        // ignore: use_build_context_synchronously
        Navigator.pop(context); // Fermer le dialog

        if (res.statusCode == 201) {
          // ignore: use_build_context_synchronously
          api.showSnackBarSuccessPersonalized(context, res.data["message"]);
          // ignore: use_build_context_synchronously
          Navigator.push(context,
              MaterialPageRoute(builder: (context) => const FournisseurView()));
        } else {
          // ignore: use_build_context_synchronously
          api.showSnackBarErrorPersonalized(context, res.data["message"]);
        }
      } catch (e) {
        // ignore: use_build_context_synchronously
        Navigator.pop(context); // Fermer le dialog
        // ignore: use_build_context_synchronously
        api.showSnackBarErrorPersonalized(context, e.toString());
      }
    }
  }

  Future<void> _refresh() async {
    await Future.delayed(const Duration(seconds: 3));
    setState(() {
      _getfournisseurs();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: CustomScrollView(
        slivers: [
          SliverAppBar(
            backgroundColor: const Color(0xff001c30),
            expandedHeight: 120, // Augmentation de la hauteur
            pinned: true,
            floating: true,
            leading: IconButton(
              onPressed: () {
                Navigator.pop(context);
              },
              icon: const Icon(Icons.arrow_back_ios_rounded,
                  size: AppSizes.iconHyperLarge, color: Colors.white),
            ),
            flexibleSpace: FlexibleSpaceBar(
              title: Text(
                "Mes fournisseurs",
                style: GoogleFonts.roboto(
                    fontSize: min(AppSizes.responsiveValue(context, 16.0),24), color: Colors.white),
              ),
            ),
          ),
          // Utiliser un SliverList à la place d'un ListView.builder pour éviter les conflits de défilement
          StreamBuilder<List<FournisseurModel>>(
            stream: _listFournisseurs.stream,
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const SliverFillRemaining(
                    child: Center(child: CircularProgressIndicator()));
              } else if (snapshot.hasError) {
                return SliverFillRemaining(
                    child: Center(
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
                              ))),
                      const SizedBox(width: 40),
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
                return const SliverToBoxAdapter(
                    child: Center(child: Text("Pas de données disponibles")));
              } else {
                return SliverList(
                  delegate: SliverChildBuilderDelegate(
                    (context, index) {
                      FournisseurModel fournisseur = snapshot.data![index];
                      return Dismissible(
                        key: Key(fournisseur.id.toString()),
                        direction: DismissDirection.endToStart,
                        onDismissed: (direction) {
                          _removeFournisseur(fournisseur.id);
                        },
                        confirmDismiss: (direction) async {
                          return await showRemoveFournisseur(context);
                        },
                        background: Container(
                          color: Colors.red,
                          child: const Row(
                            mainAxisAlignment: MainAxisAlignment.end,
                            children: [
                              Icon(Icons.delete_outline,
                                  color: Colors.white,
                                  size: AppSizes.iconLarge),
                              SizedBox(width: 50),
                            ],
                          ),
                        ),
                        child: Container(
                          height: min(AppSizes.responsiveValue(context, 114.0),120),
                          decoration: const BoxDecoration(
                              border: Border(
                                  bottom: BorderSide(
                                      color:
                                          Color.fromARGB(255, 245, 245, 245)))),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            crossAxisAlignment: CrossAxisAlignment.center,
                            children: [
                              Padding(
                                padding: const EdgeInsets.all(8.0),
                                child: Row(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Padding(
                                      padding: const EdgeInsets.all(8.0),
                                      child: Container(
                                        width: 50,
                                        height: 50,
                                        decoration: BoxDecoration(
                                            borderRadius:
                                                BorderRadius.circular(20)),
                                        child: Image.asset(
                                          "assets/logos/salespulse.jpg",
                                          fit: BoxFit.contain,
                                        ),
                                      ),
                                    ),
                                    Padding(
                                      padding: const EdgeInsets.only(left: 15),
                                      child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          Text(fournisseur.prenom,
                                              style: GoogleFonts.roboto(
                                                  fontSize: min(AppSizes.responsiveValue(context, 14.0),20),
                                                  fontWeight: FontWeight.w500)),
                                          Text(fournisseur.numero.toString(),
                                              style: GoogleFonts.roboto(
                                                  fontSize: min(AppSizes.responsiveValue(context, 14.0),20),
                                                  color: Colors.grey[500])),
                                        ],
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              // Ajouter d'autres détails comme "Numero", "Address", "Produit"
                            ],
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
        ],
      ),
      floatingActionButton: FloatingActionButton(
        backgroundColor: const Color.fromARGB(255, 255, 136, 0),
        onPressed: () {
          _addFournisseurShow(context);
        },
        child: const Icon(
          Icons.add,
          size: AppSizes.iconLarge,
          color: Colors.white,
        ),
      ),
    );
  }

//FENETRE POUR AJOUTER CATEGORIE
  void _addFournisseurShow(BuildContext context) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Center(
            child: Text(
              "Ajouter categories",
              style: GoogleFonts.roboto(
                fontSize:min(AppSizes.responsiveValue(context, 14.0),20),
                fontWeight: FontWeight.w400,
              ),
            ),
          ),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Form(
                  key: _globalKey,
                  child: Column(
                    children: [
                      TextFormField(
                        controller: _prenom,
                        validator: (value) {
                          if (value!.isEmpty) {
                            return 'Veuillez entrer le prenom du fournisseur';
                          }
                          return null;
                        },
                        decoration: InputDecoration(
                          hintText: "Prénom du fournisseur",
                          hintStyle:
                              GoogleFonts.roboto(fontSize: min(AppSizes.responsiveValue(context, 14.0),20),),
                          prefixIcon: Icon(
                            Icons.person,
                            size: min(AppSizes.responsiveValue(context, 24.0),30),
                            color: Colors.purpleAccent,
                          ),
                        ),
                      ),
                      const SizedBox(height: 20),
                      TextFormField(
                        controller: _nom,
                        validator: (value) {
                          if (value!.isEmpty) {
                            return 'Veuillez entrer le nom du fournisseur';
                          }
                          return null;
                        },
                        decoration: InputDecoration(
                          hintText: "Nom du fournisseur",
                          hintStyle:
                              GoogleFonts.roboto(fontSize:min(AppSizes.responsiveValue(context, 14.0),20),),
                          prefixIcon: Icon(
                            Icons.person,
                            size: min(AppSizes.responsiveValue(context, 24.0),30),
                            color: Colors.purpleAccent,
                          ),
                          isDense: true, // Réduit la hauteur
                          contentPadding:
                              const EdgeInsets.symmetric(vertical: 8.0),
                        ),
                      ),
                      const SizedBox(height: 20),
                      TextFormField(
                        controller: _numero,
                        keyboardType: TextInputType.number,
                        validator: (value) {
                          if (value!.isEmpty) {
                            return 'Veuillez entrer le numero du fournisseur';
                          }
                          return null;
                        },
                        decoration: InputDecoration(
                          hintText: "Numero du fournisseur",
                          hintStyle:
                              GoogleFonts.roboto(fontSize: min(AppSizes.responsiveValue(context, 14.0),20),),
                          prefixIcon: Icon(
                            Icons.phone,
                            size: min(AppSizes.responsiveValue(context, 24.0),30),
                            color: Colors.purpleAccent,
                          ),
                          isDense: true, // Réduit la hauteur
                          contentPadding:
                              const EdgeInsets.symmetric(vertical: 8.0),
                        ),
                      ),
                      const SizedBox(height: 20),
                      TextFormField(
                        controller: _produit,
                        validator: (value) {
                          if (value!.isEmpty) {
                            return 'Veuillez entrer le nom du produit';
                          }
                          return null;
                        },
                        decoration: InputDecoration(
                          hintText: "Nom du produit",
                          hintStyle:
                              GoogleFonts.roboto(fontSize: min(AppSizes.responsiveValue(context, 14.0),20),),
                          prefixIcon: Icon(
                            Icons.article_rounded,
                            size: min(AppSizes.responsiveValue(context, 24.0),30),
                            color: Colors.purpleAccent,
                          ),
                          isDense: true, // Réduit la hauteur
                          contentPadding:
                              const EdgeInsets.symmetric(vertical: 8.0),
                        ),
                      ),
                      const SizedBox(height: 20),
                      TextFormField(
                        controller: _address,
                        validator: (value) {
                          if (value!.isEmpty) {
                            return 'Veuillez entrer address du fournisseur';
                          }
                          return null;
                        },
                        decoration: InputDecoration(
                          hintText: "Address du fournisseur",
                          hintStyle:
                              GoogleFonts.roboto(fontSize: min(AppSizes.responsiveValue(context, 14.0),20),),
                          prefixIcon: Icon(
                            Icons.location_on,
                            size: min(AppSizes.responsiveValue(context, 24.0),30),
                            color: Colors.purpleAccent,
                          ),
                          isDense: true, // Réduit la hauteur
                          contentPadding:
                              const EdgeInsets.symmetric(vertical: 8.0),
                        ),
                      ),
                      const SizedBox(height: 20),
                      ElevatedButton(
                        onPressed: () {
                          _sendToserver(context);
                          Navigator.pop(context);
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color.fromARGB(255, 255, 136, 0),
                          minimumSize: Size(
                            min(AppSizes.responsiveValue(context, 400.0),20),
                            min(AppSizes.responsiveValue(context, 40.0),60),
                          ),
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
          ),
        );
      },
    );
  }

// FENTRE DIALOGUE POUR CONFIRMER LA SUPPRESSION
  Future<bool> showRemoveFournisseur(BuildContext context) async {
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
