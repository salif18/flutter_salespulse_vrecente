class VentesModel {
  String venteId;
  String userId;
  String productId;
  // String image;
  String nom;
  String categories;
  int prixAchat;
  int prixVente;
  int stocks;
  int qty;
  DateTime dateVente;

  VentesModel(
   
      { 
      required this.venteId,
      required this.userId,
      required this.productId,
      // required this.image,
      required this.nom,
      required this.categories,
      required this.prixAchat,
      required this.prixVente,
      required this.stocks,
      required this.qty,
      required this.dateVente
      });

  factory VentesModel.fromJson(Map<String, dynamic> json) {
    return VentesModel(
        venteId: json["_id"],
        productId: json["productId"],
        userId: json["userId"],
        // image: json["image"],
        nom: json["nom"],
        categories: json["categories"],
        prixAchat: json["prix_achat"],
        prixVente: json["prix_vente"],
        stocks: json["stocks"],
        qty: json["qty"],
        dateVente: DateTime.parse(json["date_vente"]));
  }

  Map<String, dynamic> toJson() {
    
    return {
      "_id": venteId,
      "productId": productId,
      "userId": userId,
      // "image": image,
      "nom": nom,
      "categories": categories,
      "prix_achat": prixAchat,
      "prix_vente": prixVente,
      "stocks": stocks,
      "qty":qty,
      "date_vente": dateVente.toIso8601String()
    };
    
  }
}
