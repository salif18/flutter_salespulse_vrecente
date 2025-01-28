class StocksModel {
  String productId;
  String cloudinaryId;
  String userId;
  String image;
  String nom;
  String categories;
  int prixAchat;
  int prixVente;
  int stocks;
  DateTime dateAchat;

  StocksModel(
      {required this.productId,
      required this.cloudinaryId,
      required this.userId,
      required this.image,
      required this.nom,
      required this.categories,
      required this.prixAchat,
      required this.prixVente,
      required this.stocks,
      required this.dateAchat});

  factory StocksModel.fromJson(Map<String, dynamic> json) {
    return StocksModel(
        productId: json["_id"],
        cloudinaryId: json["cloudinaryId"],
        userId: json["userId"],
        image: json["image"],
        nom: json["nom"],
        categories: json["categories"],
        prixAchat: json["prix_achat"],
        prixVente: json["prix_vente"],
        stocks: json["stocks"],
        dateAchat: DateTime.parse(json["date_achat"]));
  }

  Map<String, dynamic> toJson() {
    return {
      "_id": productId,
      "cloudinaryId":cloudinaryId,
      "userId": userId,
      "image": image,
      "nom": nom,
      "categories": categories,
      "prix_achat": prixAchat,
      "prix_vente": prixVente,
      "stocks": stocks,
      "date_achat": dateAchat.toIso8601String()
    };
  }
}
