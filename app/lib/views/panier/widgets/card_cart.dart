import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:salespulse/models/cart_item_model.dart';
import 'package:salespulse/providers/panier_provider.dart';
import 'package:salespulse/utils/app_size.dart';

class MyCard extends StatefulWidget {
  final CartItemModel item;
  const MyCard({super.key, required this.item});

  @override
  State<MyCard> createState() => _MyCardState();
}

class _MyCardState extends State<MyCard> {
  @override
  Widget build(BuildContext context) {
    return Container(
      width: MediaQuery.of(context).size.width,
      height: 100,
      padding: const EdgeInsets.all(8.0),
      decoration: BoxDecoration(borderRadius: BorderRadius.circular(10),
      color: Colors.grey[200],
      border :const Border(
                      bottom: BorderSide(
                        color: Color.fromARGB(255, 255, 255, 255),
                        width: 1,
                        style: BorderStyle.solid,
                      ),
                    ),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Container(
            height: 80,
            width: 80,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(20),
              image: 
                  DecorationImage(
                      image: NetworkImage(widget.item.image),
                      fit: BoxFit.contain,
                    )
                  , // Vous pouvez ajouter une image par défaut ici
            ),
          ),
          Expanded(
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                SizedBox(
                  width: 100,
                  child: Column(
                    
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        widget.item.nom,
                        style: GoogleFonts.roboto(
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                          color: const Color(0xff121212),
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                      Text(
                        widget.item.prixVente.toString(),
                        style: GoogleFonts.roboto(
                          fontSize: 14,
                          color: const Color(0xff121212),
                        ),
                      )
                    ],
                  ),
                ),
                Container(
                  height: 40,
                  decoration: BoxDecoration(
                    color: const Color(0xFF1D1A30),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                      color: const Color(0xFF1D1A30),
                    ),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Container(
                        width: 50,
                        alignment: Alignment.center,
                        child: TextButton(
                          onPressed: () {
                            if (widget.item.qty < widget.item.stocks) {
                              Provider.of<PanierProvider>(context, listen: false)
                                  .increment(widget.item);
                            } else {
                              _alertStock(context);
                            }
                          },
                          child: Text(
                            "+",
                            style: GoogleFonts.roboto(
                              color: Colors.white,
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ),
                      Container(
                        width: 50,
                        alignment: Alignment.center,
                        child: Text(
                          widget.item.qty.toString(),
                          style: GoogleFonts.roboto(
                            color: Colors.white,
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                      if (widget.item.qty > 1)
                        Container(
                          alignment: Alignment.center,
                          width: 50,
                          child: TextButton(
                            onPressed: () {
                              Provider.of<PanierProvider>(context, listen: false)
                                  .decrement(widget.item);
                            },
                            child: Text(
                              "-",
                              style: GoogleFonts.roboto(
                                color: Colors.white,
                                fontSize: 20,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ),
                    ],
                  ),
                )
              ],
            ),
          ),
        ],
      ),
    );
  }

  // Méthode pour afficher une alerte de stock insuffisant
  void _alertStock(BuildContext context) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(
        "Stock insuffisant",
        style: GoogleFonts.roboto(fontSize: AppSizes.fontMedium),
      ),
      duration: const Duration(milliseconds: 800),
      backgroundColor: const Color.fromARGB(255, 39, 58, 90),
      action: SnackBarAction(
        label: "",
        onPressed: () {
          ScaffoldMessenger.of(context).hideCurrentSnackBar();
        },
      ),
    ));
  }
}
