import 'dart:async'; // Pour StreamController
import 'dart:convert';
import 'dart:io';
import 'dart:math';
import 'package:auto_size_text/auto_size_text.dart';
import 'package:date_field/date_field.dart';
import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:salespulse/components/drawer.dart';
import 'package:salespulse/models/categories_model.dart';
import 'package:salespulse/models/stocks_model.dart';
import 'package:salespulse/providers/auth_provider.dart';
import 'package:salespulse/providers/panier_provider.dart';
import 'package:salespulse/services/categ_api.dart';
import 'package:salespulse/services/stocks_api.dart';
import 'package:salespulse/utils/app_size.dart';
import 'package:salespulse/views/categories/categories_view.dart';
import 'package:salespulse/views/fournisseurs/fournisseurs_view.dart';
import 'package:salespulse/views/panier/panier.dart';
import 'package:salespulse/views/qrcode/mobile_scanner.dart';
// import 'package:salespulse/views/qrcode/qr_code.dart';
import 'package:salespulse/views/search/search_view.dart';

class StocksView extends StatefulWidget {
  const StocksView({super.key});

  @override
  State<StocksView> createState() => _StocksViewState();
}

class _StocksViewState extends State<StocksView> {
  ServicesStocks api = ServicesStocks();
  ServicesCategories apiCatego = ServicesCategories();
  final GlobalKey<ScaffoldState> drawerKey = GlobalKey<ScaffoldState>();
  // Clé Key du formulaire
  final GlobalKey<FormState> _globalKey = GlobalKey<FormState>();
  final StreamController<List<StocksModel>> _streamController =
      StreamController();
  List<CategoriesModel> _listCategories = [];
  String? _categorieValue;

  // configuration de selection image depuis gallerie
  final ImagePicker _picker = ImagePicker();
  XFile? _articleImage;

// configuration des champs de formulaires pour le controller
  final _nameController = TextEditingController();
  String? _categoryController;
  final _prixAchatController = TextEditingController();
  final _prixVenteController = TextEditingController();
  final _stockController = TextEditingController();
  DateTime selectedDate = DateTime.now();

  @override
  void initState() {
    super.initState();
    _loadProducts(); // Charger les produits au démarrage
    _getCategories();
  }

  @override
  void dispose() {
    _nameController.dispose();
    _prixAchatController.dispose();
    _prixVenteController.dispose();
    _stockController.dispose();
    _streamController
        .close(); // Fermer le StreamController pour éviter les fuites de mémoire

    super.dispose();
  }

  //rafraichire la page en actualisanst la requete
  Future<void> _refresh() async {
    await Future.delayed(const Duration(seconds: 3));
    setState(() {
      _loadProducts();
      _getCategories();
    });
  }

  // Fonction pour récupérer les produits depuis le serveur et ajouter au stream
  Future<void> _loadProducts() async {
    try {
      final token = Provider.of<AuthProvider>(context, listen: false).token;
      final userId = Provider.of<AuthProvider>(context, listen: false).userId;
      final res = await api.getAllProducts(token, userId);
      final body = res.data;

      if (res.statusCode == 200) {
        final products = (body["produits"] as List)
            .map((json) => StocksModel.fromJson(json))
            .toList();

        if (!_streamController.isClosed) {
          _streamController.add(products); // Ajouter les produits au stream
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
    } catch (e) {
      if (!_streamController.isClosed) {
        _streamController.addError("Error loading products");
      }
    }
  }

  // OBTENIR LES CATEGORIES API
  Future<void> _getCategories() async {
    final token = Provider.of<AuthProvider>(context, listen: false).token;
    final userId = Provider.of<AuthProvider>(context, listen: false).userId;
    try {
      final res = await apiCatego.getCategories(userId, token);
      final body = res.data;
      if (res.statusCode == 200) {
        setState(() {
          _listCategories = (body["results"] as List)
              .map((json) => CategoriesModel.fromJson(json))
              .toList();
        });
      }
    } catch (e) {
      Exception(e); // Ajout d'une impression pour le debug
    }
  }

  // obtenir l"image depuis gallerie du telephone
  Future<void> _getImageToGalleriePhone() async {
    final XFile? imagePicked =
        await _picker.pickImage(source: ImageSource.gallery);
    setState(() {
      if (imagePicked != null) {
        _articleImage = imagePicked;
      }
    });
  }

// Envoie des donnees vers le server
  Future<void> _sendNewStocksToServer() async {
    if (_globalKey.currentState!.validate()) {
      if (_categoryController == null) {
        api.showSnackBarErrorPersonalized(
            context, "Veuillez sélectionner  une catégorie.");
        return;
      }
      final token = Provider.of<AuthProvider>(context, listen: false).token;
      final userId = Provider.of<AuthProvider>(context, listen: false).userId;

      FormData formData = FormData.fromMap({
        "userId": userId,
        "nom": _nameController.text,
        "image": _articleImage != null
            ? await MultipartFile.fromFile(_articleImage!.path,
                filename: _articleImage!.path.split("/").last)
            : "",
        "categories": _categoryController,
        "prix_achat": _prixAchatController.text,
        "prix_vente": _prixVenteController.text,
        "stocks": _stockController.text,
        "date_achat": selectedDate.toIso8601String(),
      });

      try {
        final res = await api.postNewProduct(formData, token);
        if (res.statusCode == 201) {
          // ignore: use_build_context_synchronously
          api.showSnackBarSuccessPersonalized(context, res.data["message"]);
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

// Envoie des donnees vers le server
  Future<void> _sendUpdateStockToServer(article) async {
    final token = Provider.of<AuthProvider>(context, listen: false).token;
    final userId = Provider.of<AuthProvider>(context, listen: false).userId;

    // Créez un map avec les données de base
    Map<String, dynamic> data = {
      "userId": userId,
      "nom": _nameController.text,
      "categories": _categoryController,
      "prix_achat": _prixAchatController.text,
      "prix_vente": _prixVenteController.text,
      "stocks": _stockController.text,
      "date_achat": selectedDate.toIso8601String(),
    };

    // Ajoutez l'image uniquement si elle est sélectionnée
    if (_articleImage != null) {
      data["image"] = await MultipartFile.fromFile(
        _articleImage!.path,
        filename: _articleImage!.path.split("/").last,
      );
    }

    // Créez le FormData à partir du map
    FormData formData = FormData.fromMap(data);
    try {
      final res = await api.updateProduct(formData, token, article.productId);
      if (res.statusCode == 200) {
        // ignore: use_build_context_synchronously
        api.showSnackBarSuccessPersonalized(context, res.data["message"]);
      } else {
        // ignore: use_build_context_synchronously
        api.showSnackBarErrorPersonalized(context, res.data["message"]);
      }
    } catch (e) {
      // ignore: use_build_context_synchronously
      api.showSnackBarErrorPersonalized(context, e.toString());
    }
  }

  Future<void> _removeArticles(article) async {
    final token = Provider.of<AuthProvider>(context, listen: false).token;
    try {
      final res = await api.deleteProduct(article.productId, token);
      final body = jsonDecode(res.body);
      if (res.statusCode == 200) {
        // ignore: use_build_context_synchronously
        api.showSnackBarSuccessPersonalized(context, body["message"]);
        // ignore: use_build_context_synchronously
        Navigator.pop(context);
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
    PanierProvider cartProvider =
        Provider.of<PanierProvider>(context, listen: false);
    void Function(StocksModel, int) addToCart = cartProvider.addToCart;

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
              expandedHeight: min(AppSizes.responsiveValue(context, 100.0),100),
              pinned: true,
              floating: true,
              leading: IconButton(
                  onPressed: () {
                    drawerKey.currentState!.openDrawer();
                  },
                  icon: Icon(Icons.sort,
                      size: min(AppSizes.responsiveValue(context, 24.0),38),
                      color: Color.fromARGB(255, 255, 115, 1))),
              actions: [
                IconButton(
                    tooltip: "Ajouter de stocks",
                    onPressed: () {
                      _addStokcs(context);
                    },
                    icon: Icon(Icons.add,
                        color: Color.fromARGB(255, 255, 136, 0),
                        size:  min(AppSizes.responsiveValue(context, 24.0),30),)),
                IconButton(
                  tooltip: "Categories",
                  onPressed: () {
                    Navigator.push(
                        context,
                        MaterialPageRoute(
                            builder: (context) => const CategoriesView()));
                  },
                  icon: Icon(
                    Icons.category,
                    size:  min(AppSizes.responsiveValue(context, 24.0),30),
                    color: Color.fromARGB(255, 255, 136, 0),
                  ),
                ),
                IconButton(
                  tooltip: "Fournisseurs",
                  onPressed: () {
                    Navigator.push(
                        context,
                        MaterialPageRoute(
                            builder: (context) => const FournisseurView()));
                  },
                  icon: Icon(Icons.airport_shuttle,
                      color: Color.fromARGB(255, 255, 136, 0),
                      size: min(AppSizes.responsiveValue(context, 24.0),30),),
                ),
                IconButton(
                    tooltip: "Scanner",
                    onPressed: () {
                      Navigator.push(
                          context,
                          MaterialPageRoute(
                              builder: (context) => const MobileScannerView()));
                    },
                    icon: Icon(Icons.qr_code_scanner_sharp,
                        color: Color.fromARGB(255, 255, 136, 0),
                        size:  min(AppSizes.responsiveValue(context, 24.0),30),)),
                Stack(
                  children: [
                    IconButton(
                      onPressed: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => const PanierView(),
                          ),
                        );
                      },
                      icon: Icon(
                        FontAwesomeIcons.cartShopping,
                        size:  min(AppSizes.responsiveValue(context, 24.0),30),
                        color: Color.fromARGB(255, 255, 136, 0),
                      ),
                    ),
                    Consumer<PanierProvider>(
                      builder: (context, provider, child) {
                        return FutureBuilder(
                            future: provider.loadCartFromLocalStorage(),
                            builder: (context, snaptshot) {
                              if (provider.myCart.isNotEmpty) {
                                return Expanded(
                                  child: Positioned(
                                    left: AppSizes.responsiveValue(context, 25.0),
                                    bottom: AppSizes.responsiveValue(context, 25.0),
                                    child: Badge.count(
                                      count: provider.totalArticle,
                                      backgroundColor: Colors.amber,
                                      largeSize: AppSizes.responsiveValue(context, 40.0) / 2,
                                      textStyle: GoogleFonts.roboto(
                                        fontSize: AppSizes.responsiveValue(context, 13.0),
                                        fontWeight: FontWeight.bold,
                                        color: Colors.white,
                                      ),
                                    ),
                                  ),
                                );
                              } else {
                                return const SizedBox.shrink();
                              }
                            });
                      },
                    ),
                  ],
                ),
                SizedBox(width: AppSizes.responsiveValue(context, 20.0),)
              ],
              flexibleSpace: FlexibleSpaceBar(
                title:Text("Stocks",
                    style: GoogleFonts.roboto(
                        fontSize:  min(AppSizes.responsiveValue(context, 16.0),24), color: Colors.white)),
              ),
            ),
            SliverToBoxAdapter(
              child: Container(
                color: const Color(0xff001c30),
                height:  min(AppSizes.responsiveValue(context, 100.0),150),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.start,
                  children: [
                    Container(
                      padding:  EdgeInsets.symmetric(horizontal: AppSizes.responsiveValue(context, 16.0),),
                      constraints:  BoxConstraints(
                        maxWidth:  min(AppSizes.responsiveValue(context, 250.0),480),
                        minHeight:  min(AppSizes.responsiveValue(context, 15.0),20),
                      ),
                      child: Padding(
                        padding: EdgeInsets.all(AppSizes.responsiveValue(context, 8.0)),
                        child: DropdownButtonFormField<String>(
                          isDense: false,
                          dropdownColor: const Color(0xff001c30),
                          // menuMaxHeight:  min(AppSizes.responsiveValue(context, 50.0),80),
                          borderRadius: BorderRadius.circular(10),
                          value: _categorieValue,
                          decoration: InputDecoration(
                            filled: true,
                            fillColor: const Color.fromARGB(255, 255, 136, 0),
                            // Color.fromARGB(255, 82, 119, 175),
                            hintText: "Choisir une categorie",
                            hintStyle: TextStyle(
                                fontFamily: "roboto",
                                fontSize: min(AppSizes.responsiveValue(context, 14.0),24),
                                color: Colors.white),
                            border: const OutlineInputBorder(
                                borderSide: BorderSide.none,
                                borderRadius:
                                    BorderRadius.all(Radius.circular(20))),
                          ),
                          items: _listCategories.map((categorie) {
                            return DropdownMenuItem<String>(
                              value: categorie.name,
                              child: Text(
                                categorie.name,
                                style: GoogleFonts.roboto(
                                    fontSize:  min(AppSizes.responsiveValue(context, 14.0),28),color: Colors.white),
                              ),
                            );
                          }).toList(),
                          onChanged: (value) {
                            setState(() {
                              _categorieValue = value!;
                            });
                          },
                          validator: (value) {
                            if (value == null) {
                              return "La catégorie est requise";
                            }
                            return null;
                          },
                          icon: const Icon(
                            Icons.arrow_drop_down, // Icône de flèche
                            color: Color.fromARGB(
                                255, 255, 255, 255), // Couleur de l'icône
                          ),
                        ),
                      ),
                    ),
                    SizedBox(
                      width: AppSizes.responsiveValue(context, 20.0),
                    ),
                    IconButton(
                        onPressed: () {
                          Navigator.push(
                              context,
                              MaterialPageRoute(
                                  builder: (context) => const SearchPage()));
                        },
                        icon: Icon(Icons.search,
                            color: Color.fromARGB(255, 207, 232, 252),
                            size:  min(AppSizes.responsiveValue(context, 24.0),38),)),
                  ],
                ),
              ),
            ),
            StreamBuilder<List<StocksModel>>(
              stream: _streamController.stream,
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const SliverFillRemaining(
                    child: Center(child: CircularProgressIndicator()),
                  );
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
                            padding: const EdgeInsets.all(0.0),
                            child: SizedBox(
                                width: MediaQuery.of(context).size.width * 0.7,
                                child: Text(
                                  "Erreur de chargement des données. Réessayer en tirant l'ecrans vers le bas !!",
                                  style: GoogleFonts.roboto(
                                      fontSize: AppSizes.fontMedium),
                                ))),
                        SizedBox(width: AppSizes.responsiveValue(context, 40.0),),
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
                    child: Center(child: Text("Aucun produit disponible.")),
                  );
                } else {
                  final articles = snapshot.data!;
                  final filteredArticles = _categorieValue == null
                      ? articles
                      : articles
                          .where((article) =>
                              article.categories == _categorieValue)
                          .toList();

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
                                  height:  min(AppSizes.responsiveValue(context, 50.0),100),
                                  color: Colors.orange,
                                  padding: EdgeInsets.all( min(AppSizes.responsiveValue(context, 5.0),5),),
                                  child: Text(
                                    "Photo",
                                    style: GoogleFonts.roboto(
                                      fontSize:  min(AppSizes.responsiveValue(context, 14.0),20),
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
                                  height:  min(AppSizes.responsiveValue(context, 50),100),
                                  color: Colors.orange,
                                  constraints: BoxConstraints(
                                    maxWidth: MediaQuery.of(context).size.width,
                                  ),
                                  padding: EdgeInsets.all( min(AppSizes.responsiveValue(context, 5.0),5),),
                                  child: Text(
                                    "Name",
                                    style: GoogleFonts.roboto(
                                      fontSize:  min(AppSizes.responsiveValue(context, 14.0),20),
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
                                  height:  min(AppSizes.responsiveValue(context, 50),100),
                                  color: Colors.orange,
                                  constraints: BoxConstraints(
                                    maxWidth: MediaQuery.of(context).size.width,
                                  ),
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
                                  height: min(AppSizes.responsiveValue(context, 50.0),100),
                                  color: Colors.orange,
                                  padding: EdgeInsets.all( min(AppSizes.responsiveValue(context, 5.0),5),),
                                  child: Text(
                                    "Prix d'achat",
                                    style: GoogleFonts.roboto(
                                      fontSize:  min(AppSizes.responsiveValue(context, 14.0),20),
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
                                  height: min(AppSizes.responsiveValue(context, 50.0),100),
                                  color: Colors.orange,
                                  padding: EdgeInsets.all( min(AppSizes.responsiveValue(context, 5.0),5),),
                                  child: Text(
                                    "Prix de vente",
                                    style: GoogleFonts.roboto(
                                      fontSize:  min(AppSizes.responsiveValue(context, 14.0),20),
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
                                  height: min(AppSizes.responsiveValue(context, 50.0),100),
                                  color: Colors.orange,
                                  padding: EdgeInsets.all( min(AppSizes.responsiveValue(context, 5.0),5),),
                                  child: Text(
                                    "Quantités",
                                    style: GoogleFonts.roboto(
                                      fontSize:  min(AppSizes.responsiveValue(context, 14.0),20),
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
                                  height:  min(AppSizes.responsiveValue(context, 50.0),100),
                                  color: Colors.orange,
                                  padding: EdgeInsets.all( min(AppSizes.responsiveValue(context, 5.0),5),),
                                  child: Text(
                                    "Date",
                                    style: GoogleFonts.roboto(
                                      fontSize:  min(AppSizes.responsiveValue(context, 14.0),20),
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
                                  height:  min(AppSizes.responsiveValue(context, 50.0),100),
                                  color: Colors.orange,
                                  padding: EdgeInsets.all( min(AppSizes.responsiveValue(context, 5.0),5),),
                                  child: Text(
                                    "Actions",
                                    style: GoogleFonts.roboto(
                                      fontSize:  min(AppSizes.responsiveValue(context, 14.0),20),
                                      fontWeight: FontWeight.bold,
                                      color: Colors.white,
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          ],
                          rows: filteredArticles.map((article) {
                            return DataRow(
                              cells: [
                                DataCell(
                                  Container(
                                    padding: EdgeInsets.all( min(AppSizes.responsiveValue(context, 5.0),5),),
                                    child: article.image.isEmpty
                                        ? Image.asset(
                                            "assets/images/defaultImg.png",
                                            width:  min(AppSizes.responsiveValue(context, 50.0),150),
                                            height: min(AppSizes.responsiveValue(context, 50.0),150),
                                          )
                                        : Image.network(
                                            article.image,
                                           width:  min(AppSizes.responsiveValue(context, 50.0),150),
                                            height: min(AppSizes.responsiveValue(context, 50.0),150),
                                          ),
                                  ),
                                ),
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
                                    padding:  EdgeInsets.all(min(AppSizes.responsiveValue(context, 5.0),5),),
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
                                    padding:  EdgeInsets.all(min(AppSizes.responsiveValue(context, 5.0),5),),
                                    child: Text(
                                      "${article.prixAchat} XOF",
                                      style: GoogleFonts.roboto(
                                        fontSize: min(AppSizes.responsiveValue(context, 12.0),20),
                                      ),
                                    ),
                                  ),
                                ),
                                DataCell(
                                  Container(
                                    padding:  EdgeInsets.all(min(AppSizes.responsiveValue(context, 5.0),5),),
                                    child: Text(
                                      "${article.prixVente} XOF",
                                      style: GoogleFonts.roboto(
                                        fontSize: min(AppSizes.responsiveValue(context, 12.0),20),
                                      ),
                                    ),
                                  ),
                                ),
                                DataCell(
                                  Container(
                                    padding:  EdgeInsets.all(min(AppSizes.responsiveValue(context, 5.0),5),),
                                    child: Text(
                                      article.stocks.toString(),
                                      style: GoogleFonts.roboto(
                                        fontSize: min(AppSizes.responsiveValue(context, 14.0),20),
                                      ),
                                    ),
                                  ),
                                ),
                                DataCell(
                                  Container(
                                    padding:  EdgeInsets.all(min(AppSizes.responsiveValue(context, 5.0),5),),
                                    child: Text(
                                      DateFormat("dd MMM yyyy")
                                          .format(article.dateAchat),
                                      style: GoogleFonts.roboto(
                                        fontSize: min(AppSizes.responsiveValue(context, 14.0),20),
                                      ),
                                    ),
                                  ),
                                ),
                                DataCell(
                                  Container(
                                    padding:  EdgeInsets.all(min(AppSizes.responsiveValue(context, 5.0),5),),
                                    child: Row(
                                      children: [
                                        if (article.stocks > 0)
                                          IconButton(
                                            icon: const Icon(
                                                Icons.add_shopping_cart_rounded,
                                                color: Colors.blue),
                                            onPressed: () {
                                              // Action pour éditer le produit
                                              addToCart(article, 1);
                                              ScaffoldMessenger.of(context)
                                                  .showSnackBar(SnackBar(
                                                content: Text(
                                                  "Article ajouté",
                                                  style: GoogleFonts.roboto(
                                                      fontSize: min(AppSizes.responsiveValue(context, 16.0),20),),
                                                ),
                                                duration:
                                                    const Duration(seconds: 1),
                                                backgroundColor:
                                                    const Color.fromARGB(
                                                        255, 39, 58, 90),
                                                action: SnackBarAction(
                                                  label: "",
                                                  onPressed: () {
                                                    ScaffoldMessenger.of(
                                                            context)
                                                        .hideCurrentSnackBar();
                                                  },
                                                ),
                                              ));
                                            },
                                          ),
                                        if (article.stocks > 0)
                                          IconButton(
                                            icon: const Icon(Icons.edit,
                                                color: Color.fromARGB(
                                                    255, 53, 146, 30)),
                                            onPressed: () {
                                              // Action pour supprimer le produit
                                              _editStocks(context, article);
                                            },
                                          ),
                                        if (article.stocks == 0)
                                          IconButton(
                                            icon: const Icon(
                                                Icons.highlight_remove_rounded,
                                                color: Color.fromARGB(
                                                    255, 255, 67, 67)),
                                            onPressed: () {
                                              // Action pour éditer le produit
                                              _showAlertDelete(
                                                  context, article);
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

  void _addStokcs(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (BuildContext context) {
        return Container(
          padding: EdgeInsets.all(min(AppSizes.responsiveValue(context, 15.0),25),),
          height: MediaQuery.of(context).size.height * 0.95,
          child: Form(
            key: _globalKey,
            child: SingleChildScrollView(
              child: Column(
                children: [
                  Text("Ajouter vos stocks",
                      style: GoogleFonts.roboto(
                          fontSize:min(AppSizes.responsiveValue(context, 14.0),20),
                          fontWeight: FontWeight.w500)),
                  SizedBox(height: AppSizes.responsiveValue(context, 20),),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      Column(
                        children: [
                          Text("Image du produit",
                              style: GoogleFonts.roboto(
                                  fontSize: min(AppSizes.responsiveValue(context, 14.0),20),)),
                          IconButton(
                            icon: const Icon(Icons.photo_camera_back_outlined,
                                size: 38),
                            onPressed: () {
                              _getImageToGalleriePhone();
                            },
                          ),
                        ],
                      ),
                      if (_articleImage != null)
                        Image.file(File(_articleImage!.path),
                            width: AppSizes.responsiveValue(context, 100), height: AppSizes.responsiveValue(context, 100)),
                    ],
                  ),
                 SizedBox(height: AppSizes.responsiveValue(context, 20),),
                  TextFormField(
                    keyboardType: TextInputType.name,
                    controller: _nameController,
                    decoration:InputDecoration(
                        labelText: "Nom du produit",
                        isDense: true, // Réduit la hauteur
                        contentPadding: EdgeInsets.symmetric(
                            vertical: AppSizes.responsiveValue(context, 10), horizontal: AppSizes.responsiveValue(context, 10)),
                        border: const OutlineInputBorder()),
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return "Le nom du produit est requis";
                      }
                      return null;
                    },
                  ),
                  SizedBox(height:AppSizes.responsiveValue(context, 20)),
                  TextFormField(
                    controller: _prixAchatController,
                    keyboardType: TextInputType.number,
                    decoration: InputDecoration(
                        labelText: "Prix d'achat",
                        isDense: true, // Réduit la hauteur
                        contentPadding: EdgeInsets.symmetric(
                            vertical: AppSizes.responsiveValue(context, 10), horizontal: AppSizes.responsiveValue(context, 10)),
                        border: const OutlineInputBorder()),
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return "La description est requise";
                      }
                      return null;
                    },
                  ),
                  SizedBox(height: AppSizes.responsiveValue(context, 20)),
                  TextFormField(
                    keyboardType: TextInputType.number,
                    controller: _prixVenteController,
                    decoration: InputDecoration(
                        labelText: "Prix de vente",
                        isDense: true, // Réduit la hauteur
                       contentPadding: EdgeInsets.symmetric(
                            vertical: AppSizes.responsiveValue(context, 10), horizontal: AppSizes.responsiveValue(context, 10)),
                        border: const OutlineInputBorder()),
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return "Le prix est requis";
                      } else if (double.tryParse(value) == null) {
                        return "Veuillez entrer un prix valide";
                      }
                      return null;
                    },
                  ),
                  SizedBox(height: AppSizes.responsiveValue(context, 10)),
                  TextFormField(
                    keyboardType: TextInputType.number,
                    controller: _stockController,
                    decoration: InputDecoration(
                        labelText: "Stock du produit",
                        isDense: true, // Réduit la hauteur
                        contentPadding: EdgeInsets.symmetric(
                            vertical: AppSizes.responsiveValue(context, 10), horizontal: AppSizes.responsiveValue(context, 10)),
                        border: const OutlineInputBorder()),
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return "Le stock est requis";
                      } else if (int.tryParse(value) == null) {
                        return "Veuillez entrer un stock valide";
                      }
                      return null;
                    },
                  ),
                  SizedBox(height: AppSizes.responsiveValue(context, 20)),
                  DropdownButtonFormField<String>(
                    dropdownColor: const Color(0xff001c30),
                    isDense: false,
                    menuMaxHeight: AppSizes.responsiveValue(context, 200),
                    borderRadius: BorderRadius.circular(10),
                    value: _categoryController,
                    decoration: const InputDecoration(
                        labelText: "Catégorie du produit",
                        labelStyle: TextStyle(color: Colors.white),
                        fillColor: Color(0xff001c30),
                        filled: true,
                        border: OutlineInputBorder()),
                    items: _listCategories.map((category) {
                      return DropdownMenuItem<String>(
                        value: category.name,
                        child: Text(category.name,
                            style: GoogleFonts.roboto(
                                fontSize: 12, color: Colors.white)),
                      );
                    }).toList(),
                    onChanged: (value) {
                      setState(() {
                        _categoryController = value!;
                      });
                    },
                    validator: (value) {
                      if (value == null) {
                        return "La catégorie est requise";
                      }
                      return null;
                    },
                  ),
                  SizedBox(height: AppSizes.responsiveValue(context, 20)),
                  Padding(
                    padding: EdgeInsets.all(AppSizes.responsiveValue(context, 10)),
                    child: DateTimeFormField(
                      decoration: InputDecoration(
                        hintText: 'Ajouter une date',
                        hintStyle: GoogleFonts.roboto(fontSize: 20),
                        fillColor: Colors.grey[100],
                        filled: true,
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(20),
                          borderSide: BorderSide.none,
                        ),
                        prefixIcon: const Icon(Icons.calendar_month_rounded,
                            color: Color.fromARGB(255, 255, 136, 128),
                            size: 28),
                      ),
                      hideDefaultSuffixIcon: true,
                      mode: DateTimeFieldPickerMode.date,
                      initialValue: DateTime.now(),
                      onChanged: (DateTime? value) {
                        selectedDate = value!;
                      },
                    ),
                  ),
                  SizedBox(height: AppSizes.responsiveValue(context, 20)),
                  ElevatedButton(
                    style: ElevatedButton.styleFrom(
                        backgroundColor: const Color.fromARGB(255, 255, 136, 0),
                        minimumSize: Size( min(AppSizes.responsiveValue(context, 400.0),800), min(AppSizes.responsiveValue(context, 40.0),60),)),
                    onPressed: () {
                      _sendNewStocksToServer();
                      Navigator.pop(context);
                    },
                    child: Text("Ajouter",
                        style: GoogleFonts.roboto(
                            fontSize: min(AppSizes.responsiveValue(context, 14.0),20),
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

  void _editStocks(BuildContext context, article) {
    _nameController.text = article.nom;
    _categoryController = article.categories;
    _prixAchatController.text = article.prixAchat.toString();
    _stockController.text = article.stocks.toString();
    _prixVenteController.text = article.prixVente.toString();
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (BuildContext context) {
        return Container(
          padding: EdgeInsets.all(min(AppSizes.responsiveValue(context, 15.0),20),),
          height: MediaQuery.of(context).size.height * 0.95,
          child: Form(
            key: _globalKey,
            child: SingleChildScrollView(
              child: Column(
                children: [
                  Text("Modifier vos stocks",
                      style: GoogleFonts.roboto(
                          fontSize: min(AppSizes.responsiveValue(context, 14.0),20),
                          fontWeight: FontWeight.w500)),
                  SizedBox(height: AppSizes.responsiveValue(context, 20)),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      Column(
                        children: [
                          Text("Image du produit",
                              style: GoogleFonts.roboto(
                                  fontSize: min(AppSizes.responsiveValue(context, 14.0),20),)),
                          IconButton(
                            icon: const Icon(Icons.photo_camera_back_outlined,
                                size: 38),
                            onPressed: () {
                              _getImageToGalleriePhone();
                            },
                          ),
                        ],
                      ),
                      if (_articleImage != null)
                        Image.file(File(_articleImage!.path),
                            width: min(AppSizes.responsiveValue(context, 100.0),200), height: min(AppSizes.responsiveValue(context, 10.0),200),),
                    ],
                  ),
                  SizedBox(height: AppSizes.responsiveValue(context, 20)),
                  TextFormField(
                    keyboardType: TextInputType.name,
                    controller: _nameController,
                    decoration: const InputDecoration(
                        labelText: "Nom du produit",
                        border: OutlineInputBorder()),
                  ),
                  SizedBox(height: AppSizes.responsiveValue(context, 20)),
                  TextFormField(
                    controller: _prixAchatController,
                    keyboardType: TextInputType.number,
                    decoration: const InputDecoration(
                        labelText: "Prix d'achat",
                        border: OutlineInputBorder()),
                  ),
                  SizedBox(height: AppSizes.responsiveValue(context, 20)),
                  TextFormField(
                    keyboardType: TextInputType.number,
                    controller: _prixVenteController,
                    decoration: const InputDecoration(
                        labelText: "Prix de vente",
                        border: OutlineInputBorder()),
                  ),
                  SizedBox(height: AppSizes.responsiveValue(context, 20)),
                  TextFormField(
                    keyboardType: TextInputType.number,
                    controller: _stockController,
                    decoration: InputDecoration(
                        labelText: "Stock du produit",
                        isDense: true, // Réduit la hauteur
                        contentPadding: EdgeInsets.symmetric(vertical: AppSizes.responsiveValue(context, 8)),
                        border:const OutlineInputBorder()),
                  ),
                  SizedBox(height: AppSizes.responsiveValue(context, 20)),
                  DropdownButtonFormField<String>(
                    value: _categoryController,
                    decoration: const InputDecoration(
                        labelText: "Catégorie du produit",
                        border: OutlineInputBorder()),
                    items: _listCategories.map((category) {
                      return DropdownMenuItem<String>(
                        value: category.name,
                        child: Text(category.name),
                      );
                    }).toList(),
                    onChanged: (value) {
                      setState(() {
                        _categoryController = value;
                      });
                    },
                  ),
                  SizedBox(height:  AppSizes.responsiveValue(context, 20)),
                  ElevatedButton(
                    style: ElevatedButton.styleFrom(
                        backgroundColor: const Color.fromARGB(255, 255, 136, 0),
                        minimumSize: Size( AppSizes.responsiveValue(context, 400),  AppSizes.responsiveValue(context, 40))),
                    onPressed: () {
                      _sendUpdateStockToServer(article);
                      Navigator.pop(context);
                    },
                    child: Text("modifier",
                        style: GoogleFonts.roboto(
                            fontSize: AppSizes.fontMedium,
                            color: Colors.white)),
                  ),
                  const SizedBox(height: 20),
                  ElevatedButton(
                    style: ElevatedButton.styleFrom(
                        backgroundColor: const Color.fromARGB(255, 240, 27, 27),
                        minimumSize: Size( 
                          min(AppSizes.responsiveValue(context, 400.0),800), 
                        min(AppSizes.responsiveValue(context, 40.0),60),)),
                    onPressed: () {
                      _removeArticles(article);
                    },
                    child: Text("Supprimer",
                        style: GoogleFonts.roboto(
                            fontSize: min(AppSizes.responsiveValue(context, 14.0),20),
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

  Future<bool?> _showAlertDelete(BuildContext context, article) {
    return showDialog<bool>(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text("Supprimer"),
          content:
              const Text("Êtes-vous sûr de vouloir supprimer cet article ?"),
          actions: <Widget>[
            TextButton(
              onPressed: () => _removeArticles(article),
              child: const Text("Supprimer"),
            ),
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: const Text("Annuler"),
            ),
          ],
        );
      },
    );
  }
}
