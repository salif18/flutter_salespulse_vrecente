
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:salespulse/models/stocks_model.dart';
import 'package:salespulse/providers/auth_provider.dart';
import 'package:salespulse/services/stocks_api.dart';
import 'package:salespulse/utils/app_size.dart';
import 'package:salespulse/views/search/widgets/card_search.dart';
import 'package:shared_preferences/shared_preferences.dart';

class SearchPage extends StatefulWidget {
  const SearchPage({super.key});

  @override
  State<SearchPage> createState() => _SearchPageState();
}

class _SearchPageState extends State<SearchPage> {
  ServicesStocks api = ServicesStocks();
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  List<StocksModel> articles = [];
  TextEditingController searchValue = TextEditingController();
  List<StocksModel> resultOfSearch = [];
  List<String> recentSearches = [];

  @override
  void initState() {
    super.initState();
    _getProducts();
    _loadRecentSearches();

    // Ajouter un écouteur pour le champ de recherche
    searchValue.addListener(() {
      setState(() {
        if (searchValue.text.isEmpty) {
          resultOfSearch = [];
        } else {
          resultOfSearch = articles
              .where((item) => item.nom
                  .toLowerCase()
                  .contains(searchValue.text.toLowerCase()) ||
                  item.categories
                  .toLowerCase()
                  .contains(searchValue.text.toLowerCase()) ||
                  item.stocks.toString() == searchValue.text ||
                  item.prixVente.toString() == searchValue.text 
                )
              .toList();
        }
      });
    });
  }

  @override
  void dispose() {
    searchValue.dispose();
    super.dispose();
  }

  void _loadRecentSearches() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    setState(() {
      recentSearches = prefs.getStringList('recentSearches') ?? [];
    });
  }

  void _saveRecentSearches() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    await prefs.setStringList('recentSearches', recentSearches);
  }

  void addRecentSearch(String search) {
    if (!recentSearches.contains(search)) {
      setState(() {
        recentSearches.add(search);
        if (recentSearches.length > 5) {
          recentSearches.removeAt(0); // Garder seulement les 5 recherches les plus récentes
        }
        _saveRecentSearches();
      });
    }
  }

  void _handleSearch(String value) {
    if (value.isNotEmpty) {
      addRecentSearch(value);
    }
    setState(() {
      resultOfSearch = articles
          .where((item) => item.nom
              .toLowerCase()
              .contains(value.toLowerCase()))
          .toList();
    });
  }

void _removeRecenteSearch(String search){
   setState(() {
     recentSearches.remove(search);
     _saveRecentSearches();
   });
}

Future<void> _getProducts() async {
  final token = Provider.of<AuthProvider>(context, listen: false).token;
    final userId = Provider.of<AuthProvider>(context, listen: false).userId;
    try {
      final res = await api.getAllProducts(token, userId);
      final body = res.data;
      if(res.statusCode == 200){
        setState(() {
            articles =
        (body["produits"] as List).map((json)=> StocksModel.fromJson(json)).toList();
        });
    
      }
    } catch (e) {
      // articles.addError("");
    }
  }
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: CustomScrollView(
        slivers: [
          SliverAppBar(
             backgroundColor: const Color(0xff001c30),
            expandedHeight: 80,
            pinned: true,
            floating: true,
            leading: IconButton(onPressed: ()=> Navigator.pop(context),
             icon:const Icon(Icons.arrow_back_ios_new_rounded, size:AppSizes.iconLarge, color:Colors.white)),
            flexibleSpace: FlexibleSpaceBar(
              title: Text("Recherche",style: GoogleFonts.roboto(fontSize: AppSizes.fontLarge, color:Colors.white),)
            ),
          ),
          SliverToBoxAdapter(
            child: Container(
              padding: const EdgeInsets.all(10),
              child: Form(
                        key: _formKey,
                        child: TextFormField(
              controller: searchValue,
              decoration: InputDecoration(
                filled: true,
                fillColor: Colors.grey[100],
                prefixIcon: const Icon(Icons.search, size: AppSizes.iconLarge),
                hintText: "Que cherches-tu ?",
                hintStyle: GoogleFonts.roboto(fontSize: AppSizes.fontSmall),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(20),
                  borderSide: BorderSide.none,
                ),
              ),
              onFieldSubmitted: _handleSearch,
                        ),
                      ),
            ),
          ),
          SliverToBoxAdapter(
          child: Column(
            children: searchValue.text.isEmpty
                ? recentSearches.reversed.map((search) {
                    return ListTile(
                      trailing: IconButton(onPressed: (){
                        _removeRecenteSearch(search);
                      }, icon: Icon(Icons.highlight_remove_rounded, size:AppSizes.iconLarge, color:Colors.grey[400])),
                      title: Row(
                        children: [const Icon(Icons.history,size:AppSizes.iconLarge),
                        const SizedBox(width: 10),
                          Text(search,style:GoogleFonts.roboto(fontSize:AppSizes.fontMedium,fontWeight: FontWeight.normal)),
                        ],
                      ),
                      onTap: () {
                        searchValue.text = search;
                        searchValue.selection = TextSelection.fromPosition(
                          TextPosition(offset: searchValue.text.length),
                        );
                        _handleSearch(search);
                      },
                    );
                  }).toList()
                : resultOfSearch.isEmpty
                    ? [Padding(
                      padding: const EdgeInsets.all(15),
                      child: Text('Aucun résultat trouvé',style:GoogleFonts.roboto(fontSize:AppSizes.fontLarge,)),
                    )]
                    : resultOfSearch.map((item) {
                        return ResultSearch(item: item);
                      }).toList(),
          ),
        ),]
      ),
    );
  }
}