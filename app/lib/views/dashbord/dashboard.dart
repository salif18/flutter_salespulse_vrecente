import 'dart:async';
import 'dart:convert';
import 'dart:math';

import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:salespulse/components/bar_chart.dart';
import 'package:salespulse/components/drawer.dart';
import 'package:salespulse/components/line_chart.dart';
import 'package:salespulse/models/stats_categorie_model.dart';
import 'package:salespulse/models/stats_week_model.dart';
import 'package:salespulse/models/stats_year_model.dart';
import 'package:salespulse/models/stocks_model.dart';
import 'package:salespulse/providers/auth_provider.dart';
import 'package:salespulse/services/depense_api.dart';
import 'package:salespulse/services/stats_api.dart';
import 'package:salespulse/services/stocks_api.dart';
import 'package:salespulse/services/vente_api.dart';
import 'package:salespulse/utils/app_size.dart';

class DashboardView extends StatefulWidget {
  const DashboardView({super.key});

  @override
  State<DashboardView> createState() => _DashboardViewState();
}

class _DashboardViewState extends State<DashboardView> {
  final GlobalKey<ScaffoldState> drawerKey = GlobalKey<ScaffoldState>();
  ServicesDepense depenseApi = ServicesDepense();
  ServicesStocks stockApi = ServicesStocks();
  ServicesVentes venteApi = ServicesVentes();
  ServicesStats statsApi = ServicesStats();

  List<ProduitBestVendu> populaireVente = [];
  List<StocksModel> stocks = [];
  List<StatsWeekModel> statsHebdo = [];
  List<StatsYearModel> statsYear = [];
  int totalAchatOfAchat = 0;
  int totalAchatOfVente = 0;
  int beneficeTotal = 0;
  int venteTotal = 0;
  int depenseTotal = 0;

  int totalHebdo = 0;

  @override
  void initState() {
    super.initState();
    _loadProducts(); // Charger les produits au démarrage
    _loadVentes();
    _loadDepenses();
    _loadMostCategorie();
    _loadStatsHebdo();
    _loadStatsYear();
  }

  // Fonction pour récupérer les produits depuis le serveur et ajouter au stream
  Future<void> _loadProducts() async {
    try {
      final token = Provider.of<AuthProvider>(context, listen: false).token;
      final userId = Provider.of<AuthProvider>(context, listen: false).userId;
      final res = await stockApi.getAllProducts(token, userId);
      final body = res.data;
      if (res.statusCode == 200) {
        // Ajouter les produits au stream
        setState(() {
          stocks = (body["produits"] as List)
              .map((json) => StocksModel.fromJson(json))
              .toList();
          totalAchatOfAchat = body["totalAchatOfAchat"];
        });
      } else {
        Exception("Failed to load products");
      }
    }on DioException {
      statsApi.showSnackBarErrorPersonalized(
          // ignore: use_build_context_synchronously
          context,
          "Problème de connexion : Vérifiez votre Internet.");
    } on TimeoutException {
      statsApi.showSnackBarErrorPersonalized(
          // ignore: use_build_context_synchronously
          context,
          "Le serveur ne répond pas. Veuillez réessayer plus tard.");
    } catch (e) {
      Exception("Error loading products");
    }
  }

  Future<void> _loadDepenses() async {
    try {
      final token = Provider.of<AuthProvider>(context, listen: false).token;
      final userId = Provider.of<AuthProvider>(context, listen: false).userId;
      final res = await depenseApi.getAllDepenses(token, userId);
      final body = jsonDecode(res.body);
      if (res.statusCode == 200) {
        setState(() {
          depenseTotal = body["depensesTotal"];
        });
      } else {
        Exception("Failed to load products");
      }
    } catch (e) {
      Exception("Error loading products");
    }
  }

  // Fonction pour récupérer les produits depuis le serveur et ajouter au stream
  Future<void> _loadVentes() async {
    try {
      final token = Provider.of<AuthProvider>(context, listen: false).token;
      final userId = Provider.of<AuthProvider>(context, listen: false).userId;
      final res = await venteApi.getAllVentes(token, userId);
      final body = res.data;
    
      if (res.statusCode == 200) {
        setState(() {
          totalAchatOfVente = body["totalAchatOfVente"];
          venteTotal = body["total_vente"];
          beneficeTotal = body["benefice_total"];
        });
      } else {
        Exception("Failed to load products");
      }
    } catch (e) {
      Exception("Error loading products");
    }
  }

  // Fonction pour récupérer les produits depuis le serveur et ajouter au stream
  Future<void> _loadMostCategorie() async {
    try {
      final token = Provider.of<AuthProvider>(context, listen: false).token;
      final userId = Provider.of<AuthProvider>(context, listen: false).userId;
      final res = await statsApi.getStatsByCategories(token, userId);
      final body = jsonDecode(res.body);
      if (res.statusCode == 200) {
        setState(() {
          populaireVente = (body["results"] as List)
              .map((json) => ProduitBestVendu.fromJson(json))
              .toList();
        });
      } else {
        Exception("Failed to load products");
      }
    } catch (e) {
      Exception("Error loading products");
    }
  }

  // Fonction pour récupérer les produits depuis le serveur et ajouter au stream
  Future<void> _loadStatsHebdo() async {
    try {
      final token = Provider.of<AuthProvider>(context, listen: false).token;
      final userId = Provider.of<AuthProvider>(context, listen: false).userId;
      final res = await statsApi.getStatsHebdo(token, userId);
      final body = jsonDecode(res.body);
      if (res.statusCode == 200) {
        setState(() {
          totalHebdo = body["totalHebdo"];
          statsHebdo = (body["stats"] as List)
              .map((json) => StatsWeekModel.fromJson(json))
              .toList();
        });
      } else {
        Exception("Failed to load products");
      }
    } catch (e) {
      Exception("Error loading products");
    }
  }

  // Fonction pour récupérer les produits depuis le serveur et ajouter au stream
  Future<void> _loadStatsYear() async {
    try {
      final token = Provider.of<AuthProvider>(context, listen: false).token;
      final userId = Provider.of<AuthProvider>(context, listen: false).userId;
      final res = await statsApi.getStatsByMonth(token, userId);
      final body = jsonDecode(res.body);
      if (res.statusCode == 200) {
        setState(() {
          statsYear = (body["results"] as List)
              .map((json) => StatsYearModel.fromJson(json))
              .toList();
        });
      } else {
        Exception("Failed to load products");
      }
    } catch (e) {
      Exception("Error loading products");
    }
  }

  //rafraichire la page en actualisanst la requete
  Future<void> _refresh() async {
    await Future.delayed(const Duration(seconds: 3));
    setState(() {
      _loadProducts();
      _loadDepenses();
      _loadMostCategorie();
      _loadStatsHebdo();
      _loadStatsYear();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        key: drawerKey,
        drawer: const DrawerWidget(),
        backgroundColor: const Color.fromARGB(255, 223, 223, 223),
        body: RefreshIndicator(
          backgroundColor: Colors.transparent,
          color: Colors.grey[100],
          onRefresh: _refresh,
          displacement: 50,
          child: CustomScrollView(
            slivers: [
              SliverAppBar(
                backgroundColor: const Color(0xff001c30),
                toolbarHeight: min(AppSizes.responsiveValue(context, 50.0),100),
                pinned: true,
                floating: true,
                leading: IconButton(onPressed: (){
                  drawerKey.currentState!.openDrawer();
                }, icon:Icon(Icons.sort, size: min(AppSizes.responsiveValue(context, 24),38),color:Color.fromARGB(255, 255, 136, 0),)),
                flexibleSpace: FlexibleSpaceBar(
                  title: Text("Tableau de bord",style:GoogleFonts.roboto(fontSize: min(AppSizes.responsiveValue(context, 16),25), color:Colors.white)),
                ),
              ),
              SliverToBoxAdapter(
                child: _statsWeek(context),
              ),
              SliverToBoxAdapter(child: _statsStock(context)),
              SliverToBoxAdapter(child: _statsCaisse(context)),
              SliverToBoxAdapter(child: _statsCaisse1(context)),
              SliverToBoxAdapter(child: _statsCaisse2(context)),
              SliverToBoxAdapter(child: _statsAnnuel(context)),
            ],
          ),
        ));
  }

  Widget _statsWeek(BuildContext context) {
    return LayoutBuilder(builder: (context, constraints) {
      return Container(
        // width: constraints.maxWidth,
        // height: min(AppSizes.responsiveValue(context, 300.0),900),
        decoration: BoxDecoration(
          // borderRadius: BorderRadius.circular(20),
          // color: const Color(0xff001c30),
          boxShadow: [
            BoxShadow(
              color: const Color.fromARGB(255, 36, 34, 34)
                  .withOpacity(0.2), // Couleur de l'ombre
              spreadRadius: 2, // Taille de la diffusion de l'ombre
              blurRadius: 8, // Flou de l'ombre
              offset: const Offset(0, 4), // Décalage de l'ombre (x,y)
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
                padding: EdgeInsets.symmetric(horizontal:min(AppSizes.responsiveValue(context, 15.0),20),vertical: min(AppSizes.responsiveValue(context, 8.0),16)),
                child: FittedBox(
                  fit: BoxFit.scaleDown,
                  child: Text("Hebdomadaire",
                      style: GoogleFonts.roboto(
                          fontWeight: FontWeight.w600,
                          fontSize: min(AppSizes.responsiveValue(context, 16),30),
                          color: const Color.fromARGB(255, 7, 7, 7))),
                )),
            Padding(
              padding: EdgeInsets.only(left: min(AppSizes.responsiveValue(context, 15.0),20)),
              child: FittedBox(
                fit: BoxFit.scaleDown,
                child: Text("$totalHebdo XOF",
                    style: GoogleFonts.roboto(
                        fontWeight: FontWeight.w600,
                        fontSize: min(AppSizes.responsiveValue(context, 16.0),30),
                        color: const Color.fromARGB(255, 10, 10, 10))),
              ),
            ),
            BarChartWidget(
              data: statsHebdo,
            )
          ],
        ),
      );
    });
  }

  Widget _statsStock(BuildContext context) {
    List<StocksModel> filterStocks =
        stocks.where((product) => product.stocks == 0).toList();

    return LayoutBuilder(builder: (context, constraints) {
      return Container(
        // width: constraints.maxWidth,
        padding:  EdgeInsets.symmetric(horizontal:min(AppSizes.responsiveValue(context, 10.0),20),vertical:min(AppSizes.responsiveValue(context, 10.0),5)),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Expanded(
              flex: 1,
              child: _buildStatContainer(
                title: "Les plus achetés",
                icon: Icons.star_rate_rounded,
                iconColor: Colors.yellow,
                backgroundColor: const Color.fromARGB(255, 255, 149, 50),
                textColor: Colors.white,
                child: Expanded(
                  child: ListView.builder(
                    shrinkWrap: true,
                    itemCount: populaireVente.length.clamp(0, 5), // max 4 items
                    itemBuilder: (context, index) {
                      final stock = populaireVente[index];
                      return Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Flexible(
                            flex: 1,
                            child: Container(
                              width: AppSizes.responsiveValue(context, 100),
                              alignment: Alignment.centerLeft,
                              child: FittedBox(
                                fit: BoxFit.scaleDown,
                                child: Text(
                                  stock.id.nom,
                                  style: GoogleFonts.roboto(
                                      fontSize: min(AppSizes.responsiveValue(context, 13.0),20),
                                      color: Colors.white),
                                )),
                            ),
                          ),
                            Flexible(
                              flex: 1,
                              child: Container(
                                alignment: Alignment.bottomLeft,
                                child: FittedBox(
                                fit: BoxFit.scaleDown,
                                child: Text(
                                 stock.id.categories,
                                  style: GoogleFonts.roboto(
                                      fontSize: min(AppSizes.responsiveValue(context, 13.0),20),
                                      color: Colors.white),
                                )),
                              ),
                            ),
                        Flexible(
                          flex:1,
                          child: FittedBox(
                              fit: BoxFit.scaleDown,
                              child: Text(
                                stock.totalVendu.toString(),
                                style: GoogleFonts.roboto(
                                    fontSize: min(AppSizes.responsiveValue(context, 12.0),20),
                                    color:const Color.fromARGB(255, 255, 238, 0)),
                              )),
                        ),
                        ]);
                    },
                  ),
                ),
              ),
            ),
            Expanded(
              flex: 1,
              child: _buildStatContainer(
                title: "Manque de stock",
                icon: Icons.hourglass_empty_rounded,
                iconColor: const Color.fromARGB(255, 236, 40, 40),
                backgroundColor: const Color(0xfff0f1f5),
                textColor: const Color.fromARGB(255, 39, 39, 39),
                child: filterStocks.isEmpty
                    ? Center(
                        child: FittedBox(
                        fit: BoxFit.scaleDown,
                        child: Text("Aucun stock manquant",
                            style: GoogleFonts.roboto(
                                fontSize: min(AppSizes.responsiveValue(context, 14.0),20),)),
                      ))
                    : Expanded(
                        child: ListView.builder(
                          shrinkWrap: true,
                          itemCount:
                              filterStocks.length.clamp(0, 5), // max 4 items
                          itemBuilder: (context, index) {
                            final stock = filterStocks[index];
                            return Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              
                              children: [
                                Flexible(
                                  flex:1,
                                  child: FittedBox(
                                    fit: BoxFit.scaleDown,
                                    child: Text(stock.nom,
                                        style: GoogleFonts.roboto(
                                            fontSize: min(AppSizes.responsiveValue(context, 12.0),20),)),
                                  ),
                                ),
                                Flexible(
                                  flex: 1,
                                  child: FittedBox(
                                    fit: BoxFit.scaleDown,
                                    child: Text(stock.categories.toLowerCase(),
                                        style: GoogleFonts.roboto(
                                            fontSize: min(AppSizes.responsiveValue(context, 12.0),20),
                                            color:const Color.fromARGB(255, 122, 0, 204)
                                          )),
                                  ),
                                ),
                              ],
                            );
                          },
                        ),
                      ),
              ),
            ),
          ],
        ),
      );
    });
  }

  Widget _buildStatContainer({
    required String title,
    required IconData icon,
    required Color iconColor,
    required Color backgroundColor,
    required Color textColor,
    Widget? child,
  }) {
    return Flexible(
      flex: 1,
      child: Container(
        // width: 180,
        height: min(AppSizes.responsiveValue(context, 200.0),300),
        margin:  EdgeInsets.symmetric(horizontal:AppSizes.responsiveValue(context, 5),vertical: AppSizes.responsiveValue(context, 5)),
        padding: EdgeInsets.symmetric(horizontal:AppSizes.responsiveValue(context, 5.0),vertical: AppSizes.responsiveValue(context, 10.0)),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(20),
          color: backgroundColor,
          boxShadow: [
            BoxShadow(
              color: const Color.fromARGB(255, 36, 34, 34).withOpacity(0.2),
              spreadRadius: 2,
              blurRadius: 8,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(icon, size: min(AppSizes.responsiveValue(context, 24.0),30), color: iconColor),
                SizedBox(width: AppSizes.responsiveValue(context, 10.0)),
                Text(
                  title,
                  style: GoogleFonts.roboto(
                    fontSize: min(AppSizes.responsiveValue(context, 14.0),20),
                    color: textColor,
                  ),
                ),
              ],
            ),
            SizedBox(height: AppSizes.responsiveValue(context, 10)),
            if (child != null) child,
          ],
        ),
      ),
    );
  }

  Widget _statsCaisse(BuildContext context) {
    int revenu = beneficeTotal - depenseTotal;
    return LayoutBuilder(builder: (context, constraints) {
      return Container(
        margin: EdgeInsets.symmetric(horizontal:AppSizes.responsiveValue(context, 10.0),vertical: AppSizes.responsiveValue(context, 2)),
        padding: EdgeInsets.all(AppSizes.responsiveValue(context, 10.0)),
        width: constraints.maxWidth,
        decoration: BoxDecoration(
          color: const Color(0xfff0f1f5),
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: const Color.fromARGB(255, 36, 34, 34)
                  .withOpacity(0.2), // Couleur de l'ombre
              spreadRadius: 2, // Taille de la diffusion de l'ombre
              blurRadius: 8, // Flou de l'ombre
              offset: const Offset(0, 4), // Décalage de l'ombre (x,y)
            ),
          ],
        ),
        height: min(AppSizes.responsiveValue(context, 100.0),200),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Padding(
                    padding: EdgeInsets.all(AppSizes.responsiveValue(context, 5.0)),
                    child: Icon(Icons.line_axis_rounded,
                        size: min(AppSizes.responsiveValue(context, 24.0),30),
                        color: Color.fromARGB(255, 20, 151, 3))),
                Padding(
                    padding: EdgeInsets.all(AppSizes.responsiveValue(context, 5.0)),
                    child: FittedBox(
                      fit: BoxFit.scaleDown,
                      child: Text(
                        "Etat de caisse",
                        style:
                            GoogleFonts.roboto(fontSize: min(AppSizes.responsiveValue(context, 14.0),20),),
                      ),
                    ))
              ],
            ),
            Padding(
              padding: EdgeInsets.all(AppSizes.responsiveValue(context, 2.0)),
              child: Row(
                children: [
                  FittedBox(
                    fit: BoxFit.scaleDown,
                    child: Text(
                      "$revenu XOF",
                      style: GoogleFonts.roboto(
                        fontSize: min(AppSizes.responsiveValue(context, 14.0),20),
                        fontWeight:FontWeight.bold , color: revenu < 0? Colors.red : Colors.black),
                    ),
                  ),
                  SizedBox(width: AppSizes.responsiveValue(context, 25)),
                  revenu > 0
                      ? Icon(
                          Icons.arrow_upward_rounded,
                          size: min(AppSizes.responsiveValue(context, 24.0),30),
                          color: Colors.blue,
                        )
                      : Icon(
                          Icons.arrow_downward_outlined,
                          size:min(AppSizes.responsiveValue(context, 24.0),30),
                          color: Colors.red,
                        )
                ],
              ),
            )
          ],
        ),
      );
    });
  }

  Widget _statsCaisse1(BuildContext context) {
    int prixGlobalAchat = totalAchatOfAchat + totalAchatOfVente;

    return LayoutBuilder(builder: (context, constraints) {
      return Container(
        margin: EdgeInsets.symmetric(horizontal:min(AppSizes.responsiveValue(context, 8.0),16),vertical: min(AppSizes.responsiveValue(context, 8),8)),
        width: constraints.maxWidth,
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Flexible(
              flex: 1,
              child: Container(
                margin: EdgeInsets.all(AppSizes.responsiveValue(context, 5.0)),
                padding: EdgeInsets.all(AppSizes.responsiveValue(context, 10.0)),
                decoration: BoxDecoration(
                  color: const Color(0xfff764ba),
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: [
                    BoxShadow(
                      color: const Color.fromARGB(255, 36, 34, 34)
                          .withOpacity(0.2), // Couleur de l'ombre
                      spreadRadius: 2, // Taille de la diffusion de l'ombre
                      blurRadius: 8, // Flou de l'ombre
                      offset: const Offset(0, 4), // Décalage de l'ombre (x,y)
                    ),
                  ],
                ),
                height: min(AppSizes.responsiveValue(context, 100.0),200),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Padding(
                            padding: EdgeInsets.all(AppSizes.responsiveValue(context, 5.0)),
                            child: Icon(Icons.monetization_on,
                                size: min(AppSizes.responsiveValue(context, 24.0),30),
                                color: Color.fromARGB(255, 255, 230, 1))),
                        Padding(
                            padding: EdgeInsets.all(AppSizes.responsiveValue(context, 5)),
                            child: FittedBox(
                              fit: BoxFit.scaleDown,
                              child: Text(
                                "Prix d'achat",
                                style: GoogleFonts.roboto(
                                    fontSize: min(AppSizes.responsiveValue(context, 14.0),20),
                                    color: Colors.white),
                              ),
                            ))
                      ],
                    ),
                    Padding(
                      padding: EdgeInsets.symmetric(horizontal:  AppSizes.responsiveValue(context, 10.0)),
                      child: FittedBox(
                        fit: BoxFit.scaleDown,
                        child: Text(
                          "$prixGlobalAchat XOF",
                          style: GoogleFonts.roboto(
                              fontSize: min(AppSizes.responsiveValue(context, 14.0),20),
                              color: Colors.white),
                        ),
                      ),
                    )
                  ],
                ),
              ),
            ),
            Flexible(
              flex: 1,
              child: Container(
                margin: EdgeInsets.all(AppSizes.responsiveValue(context, 5.0)),
                padding: EdgeInsets.all(AppSizes.responsiveValue(context, 10.0)),
                decoration: BoxDecoration(
                  color: const Color(0xffffffff),
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: [
                    BoxShadow(
                      color: const Color.fromARGB(255, 36, 34, 34)
                          .withOpacity(0.2), // Couleur de l'ombre
                      spreadRadius: 2, // Taille de la diffusion de l'ombre
                      blurRadius: 8, // Flou de l'ombre
                      offset: const Offset(0, 4), // Décalage de l'ombre (x,y)
                    ),
                  ],
                ),
                width: AppSizes.responsiveValue(context, 180.0),
                height: min(AppSizes.responsiveValue(context, 100.0),200),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Padding(
                            padding: EdgeInsets.all(AppSizes.responsiveValue(context, 5.0)),
                            child:Icon(
                              Icons.attach_money_outlined,
                              size: min(AppSizes.responsiveValue(context, 24.0),30),
                              color: Color.fromARGB(255, 16, 230, 23),
                            )),
                        Padding(
                            padding: EdgeInsets.all(AppSizes.responsiveValue(context, 2.0)),
                            child: FittedBox(
                              fit: BoxFit.scaleDown,
                              child: Text(
                                "Prix de vente",
                                style: GoogleFonts.roboto(
                                    fontSize: min(AppSizes.responsiveValue(context, 14.0),20),),
                              ),
                            ))
                      ],
                    ),
                    Padding(
                      padding: EdgeInsets.symmetric(horizontal:  AppSizes.responsiveValue(context, 10.0)),
                      child: FittedBox(
                        fit: BoxFit.scaleDown,
                        child: Text(
                          "$venteTotal XOF",
                          style:
                              GoogleFonts.roboto(fontSize:min(AppSizes.responsiveValue(context, 14.0),20),),
                        ),
                      ),
                    )
                  ],
                ),
              ),
            ),
          ],
        ),
      );
    });
  }

  Widget _statsCaisse2(BuildContext context) {
    return LayoutBuilder(builder: (context, constraints) {
      return Container(
        margin: EdgeInsets.symmetric(horizontal:min(AppSizes.responsiveValue(context, 8.0),16)),
        // width: constraints.maxWidth,
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Expanded(
              flex: 1,
              child: Container(
                margin:EdgeInsets.all(AppSizes.responsiveValue(context, 5.0)),
                padding: EdgeInsets.all(AppSizes.responsiveValue(context, 10.0)),
                decoration: BoxDecoration(
                  color: const Color(0xff2f80ed),
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: [
                    BoxShadow(
                      color: const Color.fromARGB(255, 36, 34, 34)
                          .withOpacity(0.2), // Couleur de l'ombre
                      spreadRadius: 2, // Taille de la diffusion de l'ombre
                      blurRadius: 8, // Flou de l'ombre
                      offset: const Offset(0, 4), // Décalage de l'ombre (x,y)
                    ),
                  ],
                ),
                // width: AppSizes.responsiveValue(context, 180.0),
                height: min(AppSizes.responsiveValue(context, 100.0),200),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Padding(
                            padding: EdgeInsets.all(AppSizes.responsiveValue(context, 5.0)),
                            child: Icon(
                              Icons.monetization_on,
                              size: min(AppSizes.responsiveValue(context, 24.0),30),
                              color: Color.fromARGB(255, 255, 255, 255),
                            )),
                        Padding(
                            padding: EdgeInsets.all(AppSizes.responsiveValue(context, 2.0)),
                            child: FittedBox(
                              fit: BoxFit.scaleDown,
                              child: Text(
                                "Benefices",
                                style: GoogleFonts.roboto(
                                    fontSize: min(AppSizes.responsiveValue(context, 14.0),20),
                                    color: Colors.white),
                              ),
                            ))
                      ],
                    ),
                    Padding(
                      padding: EdgeInsets.all(AppSizes.responsiveValue(context, 2.0)),
                      child: FittedBox(
                        fit: BoxFit.scaleDown,
                        child: Text(
                          "$beneficeTotal XOF",
                          style: GoogleFonts.roboto(
                              fontSize: min(AppSizes.responsiveValue(context, 14.0),20), color: Colors.white),
                        ),
                      ),
                    )
                  ],
                ),
              ),
            ),
            Expanded(
              flex: 1,
              child: Container(
                margin: EdgeInsets.all(AppSizes.responsiveValue(context, 5.0)),
                padding: EdgeInsets.all(AppSizes.responsiveValue(context, 10.0)),
                decoration: BoxDecoration(
                  color: const Color(0xFF292D4E),
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: [
                    BoxShadow(
                      color: const Color.fromARGB(255, 36, 34, 34)
                          .withOpacity(0.2), // Couleur de l'ombre
                      spreadRadius: 2, // Taille de la diffusion de l'ombre
                      blurRadius: 8, // Flou de l'ombre
                      offset: const Offset(0, 4), // Décalage de l'ombre (x,y)
                    ),
                  ],
                ),
                height: min(AppSizes.responsiveValue(context, 100.0),200),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Padding(
                            padding: EdgeInsets.all(AppSizes.responsiveValue(context, 5.0)),
                            child:Icon(Icons.monetization_on,
                                size: min(AppSizes.responsiveValue(context, 24.0),30),
                                color: Color.fromARGB(255, 255, 17, 0))),
                        Padding(
                            padding: EdgeInsets.all(AppSizes.responsiveValue(context, 5.0)),
                            child: FittedBox(
                              fit: BoxFit.scaleDown,
                              child: Text(
                                "Depenses",
                                style: GoogleFonts.roboto(
                                    fontSize: min(AppSizes.responsiveValue(context, 14.0),20),
                                    color: Colors.white),
                              ),
                            ))
                      ],
                    ),
                    Padding(
                      padding: EdgeInsets.all(AppSizes.responsiveValue(context, .02)),
                      child: FittedBox(
                        fit: BoxFit.scaleDown,
                        child: Text(
                          "$depenseTotal XOF",
                          style: GoogleFonts.roboto(
                              fontSize: min(AppSizes.responsiveValue(context, 14.0),20),
                              color: Colors.white),
                        ),
                      ),
                    )
                  ],
                ),
              ),
            ),
          ],
        ),
      );
    });
  }

  Widget _statsAnnuel(BuildContext context) {
    return LayoutBuilder(builder: (context, constraints) {
      return Container(
        margin: EdgeInsets.symmetric(horizontal:min(AppSizes.responsiveValue(context, 5.0),10),vertical:  min(AppSizes.responsiveValue(context, 10.0),10)),
        // width: constraints.maxWidth,
        // height: min(AppSizes.responsiveValue(context, 270.0),900),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(20),
          color: const Color.fromARGB(255, 223, 223, 223),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
                padding: EdgeInsets.symmetric(horizontal:AppSizes.responsiveValue(context, 15.0),vertical:AppSizes.responsiveValue(context, 5.0)),
                child: FittedBox(
                  fit: BoxFit.scaleDown,
                  child: Text("Annuel",
                      style: GoogleFonts.roboto(
                          fontWeight: FontWeight.w600,
                          fontSize: min(AppSizes.responsiveValue(context, 16),30),
                          color: const Color.fromARGB(255, 12, 12, 12))),
                )),
            // Padding(
            //   padding: const EdgeInsets.only(left: 15),
            //   child: FittedBox(
            //     fit: BoxFit.scaleDown,
            //     child: Text("125000 fcfa",
            //         style: GoogleFonts.roboto(
            //             fontWeight: FontWeight.w600,
            //             fontSize: 18,
            //             color: const Color.fromARGB(255, 5, 5, 5))),
            //   ),
            // ),
            LineChartWidget(data: statsYear),
          ],
        ),
      );
    });
  }
}
