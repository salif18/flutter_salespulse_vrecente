import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:date_field/date_field.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:salespulse/components/drawer.dart';
import 'package:salespulse/models/depenses_model.dart';
import 'package:salespulse/providers/auth_provider.dart';
import 'package:salespulse/services/depense_api.dart';
import 'package:salespulse/utils/app_size.dart';

class DepensesView extends StatefulWidget {
  const DepensesView({super.key});

  @override
  State<DepensesView> createState() => _DepensesViewState();
}

class _DepensesViewState extends State<DepensesView> {
  final GlobalKey<ScaffoldState> drawerKey = GlobalKey<ScaffoldState>();
  // Clé Key du formulaire
  final GlobalKey<FormState> _globalKey = GlobalKey<FormState>();
  DateTime? selectedDate;
  ServicesDepense api = ServicesDepense();
  final StreamController<List<DepensesModel>> _streamController =
      StreamController();
  List<DepensesModel> filteredDepenses = [];
  final _montantController = TextEditingController();
  final _motifController = TextEditingController();
  

  @override
  void initState() {
    super.initState();
    _loadProducts(); // Charger les produits au démarrage
  }

  @override
  void dispose() {
    _montantController.dispose();
    _motifController.dispose();
    _streamController
        .close(); // Fermer le StreamController pour éviter les fuites de mémoire
    super.dispose();
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

  Future<void> _loadProducts() async {
    try {
      final token = Provider.of<AuthProvider>(context, listen: false).token;
      final userId = Provider.of<AuthProvider>(context, listen: false).userId;
      final res = await api.getAllDepenses(token, userId);
      final body = jsonDecode(res.body);

      if (res.statusCode == 200) {
        final depenses = (body["results"] as List)
            .map((json) => DepensesModel.fromJson(json))
            .toList();

        if (!_streamController.isClosed) {
          _streamController.add(depenses); // Ajouter les dépenses au stream
        }
      } else {
        if (!_streamController.isClosed) {
          _streamController.addError("Failed to load depenses");
        }
      }
    } on SocketException {
      api.showSnackBarErrorPersonalized(
          // ignore: use_build_context_synchronously
          context, "Problème de connexion : Vérifiez votre Internet.");
     
    } on TimeoutException {
      api.showSnackBarErrorPersonalized(
          // ignore: use_build_context_synchronously
          context, "Le serveur ne répond pas. Veuillez réessayer plus tard.");
      
    }
    catch (e) {
      if (!_streamController.isClosed) {
        _streamController.addError("Error loading depenses");
      }
    }
  }

  // Envoie des donnees vers le server
  Future<void> _sendNewDepenseToServer() async {
    if (_globalKey.currentState!.validate()) {
      final token = Provider.of<AuthProvider>(context, listen: false).token;
      final userId = Provider.of<AuthProvider>(context, listen: false).userId;

      final data = {
        "userId": userId,
        "montants": _montantController.text,
        "motifs": _motifController.text
      };

      try {
        final res = await api.postNewDepenses(data, token);
        if (res.statusCode == 201) {
          // ignore: use_build_context_synchronously
          api.showSnackBarSuccessPersonalized(context, res.data["message"]);
          // ignore: use_build_context_synchronously
          Navigator.push(context,
              MaterialPageRoute(builder: (context) => const DepensesView()));
        } else {
          // ignore: use_build_context_synchronously
          api.showSnackBarErrorPersonalized(context, res.data["message"]);
        }
      } catch (e) {
        // ignore: use_build_context_synchronously
        api.showSnackBarErrorPersonalized(context, e.toString());
      }
    }
  }

  int _totalFilter() {
    return filteredDepenses.isEmpty
        ? 0
        : filteredDepenses
            .map((article) => article.montants)
            .reduce((a, b) => a + b);
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
              expandedHeight: AppSizes.responsiveValue(context, 100),
              pinned: true,
              floating: true,
              leading: IconButton(
                  onPressed: () {
                    drawerKey.currentState!.openDrawer();
                  },
                  icon: const Icon(Icons.sort,
                      size: AppSizes.iconHyperLarge, color: Color.fromARGB(255, 255, 136, 0),)),
              flexibleSpace: FlexibleSpaceBar(
                title: Text("Dépenses",
                    style: GoogleFonts.roboto(
                        fontSize: AppSizes.fontLarge, color: Colors.white)),
              ),
            ),
            SliverToBoxAdapter(
              child: Container(
                color: const Color(0xff001c30),
                height: AppSizes.responsiveValue(context, 150),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Container(
                            padding: EdgeInsets.all(AppSizes.responsiveValue(context, 10),),
                            child: Text(
                              "Total",
                              style: GoogleFonts.roboto(
                                  fontSize: AppSizes.fontMedium,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.white),
                            )),
                        Container(
                            padding: EdgeInsets.only(left: AppSizes.responsiveValue(context, 10),),
                            child: Text(
                              "${_totalFilter()} XOF",
                              style: GoogleFonts.roboto(
                                  fontSize: AppSizes.fontSmall,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.white),
                            )),
                      ],
                    ),
                    Container(
                      padding: EdgeInsets.symmetric(horizontal: AppSizes.responsiveValue(context, 16),),
                      constraints:
                          BoxConstraints(maxWidth: AppSizes.responsiveValue(context, 260), minHeight: AppSizes.responsiveValue(context, 20)),
                      child: DateTimeFormField(
                        decoration: InputDecoration(
                          hintText: 'Choisir pour une date',
                          hintStyle: GoogleFonts.roboto(
                              fontSize: 14, color: Colors.white),
                          fillColor:const Color.fromARGB(255, 255, 136, 0),
                          // Color.fromARGB(255, 82, 119, 175),
                          filled: true,
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(20),
                            borderSide: BorderSide.none,
                          ),
                          prefixIcon: const Icon(Icons.calendar_month_rounded,
                              color: Color.fromARGB(255, 255, 255, 255),
                              size: 28),
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
                    ),
                  ],
                ),
              ),
            ),
            StreamBuilder<List<DepensesModel>>(
              stream: _streamController.stream,
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return SliverFillRemaining(child: Center(child: CircularProgressIndicator()));
                } else if (snapshot.hasError) {
                  return Center(
                      child: Container(
                    padding: EdgeInsets.all(AppSizes.responsiveValue(context, 8),),
                    height: MediaQuery.of(context).size.width * 0.4,
                    width: MediaQuery.of(context).size.width * 0.9,
                    decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(20)),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Padding(
                          padding: EdgeInsets.all(AppSizes.responsiveValue(context, 8),),
                          child: SizedBox(
                            width: MediaQuery.of(context).size.width * 0.6,
                           
                            child: Text(
                              "Erreur de chargement des données. Verifier votre réseau de connexion. Réessayer en tirant l'ecrans vers le bas !!",
                              style: GoogleFonts.roboto(
                                  fontSize: AppSizes.fontMedium),
                            ))
                        ),
                        SizedBox(width: AppSizes.responsiveValue(context, 40),),
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
                  return SliverFillRemaining(child: Text("Aucun produit disponible."));
                } else {
                  final List<DepensesModel> depenses = snapshot.data!;
                  // Filtrer les articles par la date sélectionnée
                  filteredDepenses = selectedDate == null
                      ? depenses
                      : depenses.where((article) {
                          if (selectedDate != null) {
                            return article.date.year ==
                                    selectedDate!.year &&
                                article.date.month == selectedDate!.month &&
                                article.date.day == selectedDate!.day;
                          }
                          return false;
                        }).toList();
                  return SliverToBoxAdapter(
                    child: ListView.builder(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      itemCount: filteredDepenses.length,
                      itemBuilder: (BuildContext context, int index) {
                        DepensesModel depense = filteredDepenses[index];
                        return Container(
                          height: AppSizes.responsiveValue(context, 100),
                          padding: EdgeInsets.all(AppSizes.responsiveValue(context, 15),),
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(10),
                            color:const Color.fromARGB(255, 250, 250, 250),
                            border: const Border(
                              bottom: BorderSide(
                                  color: Color.fromARGB(255, 230, 230, 230)),
                            ),
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Padding(
                                padding: EdgeInsets.all(AppSizes.responsiveValue(context, 8),),
                                child: Row(
                                  crossAxisAlignment:
                                      CrossAxisAlignment.start,
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Padding(
                                      padding:
                                          EdgeInsets.only(left: AppSizes.responsiveValue(context, 15),),
                                      child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            depense.motifs,
                                            style: GoogleFonts.roboto(
                                              fontSize: AppSizes.fontMedium,
                                              fontWeight: FontWeight.w600,
                                            ),
                                          ),
                                          Text(
                                            "${depense.montants.toString()} XOF",
                                            style: GoogleFonts.roboto(
                                              fontSize: AppSizes.fontMedium,
                                              color: Colors.grey[500],
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              Padding(
                                padding: EdgeInsets.all(AppSizes.responsiveValue(context, 8),),
                                child: Column(
                                  crossAxisAlignment:
                                      CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      "Date",
                                      style: GoogleFonts.montserrat(
                                          fontSize: AppSizes.fontMedium,
                                          fontWeight: FontWeight.w600),
                                    ),
                                    Text(DateFormat("dd MMM yyyy")
                                        .format(depense.date)),
                                  ],
                                ),
                              )
                            ],
                          ),
                        );
                      },
                    ),
                  );
                }
              },
            ),
          ],
        ),
      ),
      floatingActionButton: ElevatedButton(
        style: ElevatedButton.styleFrom(
          backgroundColor: const Color.fromARGB(255, 255, 136, 0),
        ),
        onPressed: () {
          _addDepenses(context);
        },
        child: const Icon(Icons.add,
            size: AppSizes.iconLarge, color: Colors.white),
      ),
    );
  }

  void _addDepenses(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (BuildContext context) {
        return Container(
          padding: EdgeInsets.all(AppSizes.responsiveValue(context, 8),),
          height: MediaQuery.of(context).size.height * 0.6,
          child: Form(
            key: _globalKey,
            child: SingleChildScrollView(
              child: Column(
                children: [
                  Text("Enregistrer vos depenses",
                      style: GoogleFonts.roboto(
                          fontSize: AppSizes.fontMedium,
                          fontWeight: FontWeight.w500)),
                  SizedBox(height: AppSizes.responsiveValue(context, 20),),
                  SizedBox(height: AppSizes.responsiveValue(context, 20),),
                  Padding(
                    padding: EdgeInsets.all(AppSizes.responsiveValue(context, 8),),
                    child: TextFormField(
                      keyboardType: TextInputType.number,
                      controller: _montantController,
                      decoration: InputDecoration(
                         hintText: "Somme depensée",
                         fillColor: Colors.grey[100],
                          filled: true,
                          isDense: true, // Réduit la hauteur
                                contentPadding:EdgeInsets.symmetric(vertical: AppSizes.responsiveValue(context, 8),horizontal: AppSizes.responsiveValue(context, 16),),
                          border: const OutlineInputBorder()),
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return "Le nom du produit est requis";
                        }
                        return null;
                      },
                    ),
                  ),
                  SizedBox(height: AppSizes.responsiveValue(context, 20),),
                  Padding(
                    padding: EdgeInsets.all(AppSizes.responsiveValue(context, 8),),
                    child: TextFormField(
                      controller: _motifController,
                      keyboardType: TextInputType.name,
                      decoration: InputDecoration(
                          hintText: "Motif du depense",
                          filled: true,
                          fillColor: Colors.grey[100],
                          isDense: true, // Réduit la hauteur
                                contentPadding:EdgeInsets.symmetric(vertical: AppSizes.responsiveValue(context, 8), horizontal: AppSizes.responsiveValue(context, 16),),
                          border: const OutlineInputBorder()),
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return "La description est requise";
                        }
                        return null;
                      },
                    ),
                  ),
                  SizedBox(height: AppSizes.responsiveValue(context, 20),),
                  ElevatedButton(
                    style: ElevatedButton.styleFrom(
                        backgroundColor: const Color.fromARGB(255, 255, 115, 0),
                        minimumSize: const Size(400, 50)),
                    onPressed: () {
                      _sendNewDepenseToServer();
                      Navigator.pop(context);
                    },
                    child: Text("Enregistrer",
                        style: GoogleFonts.roboto(
                            fontSize: AppSizes.fontMedium,
                            color: Colors.white)),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}
