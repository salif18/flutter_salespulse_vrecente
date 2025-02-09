import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:line_icons/line_icons.dart';
import 'package:provider/provider.dart';
import 'package:salespulse/providers/auth_provider.dart';
import 'package:salespulse/utils/app_size.dart';
import 'package:salespulse/views/auth/update_password.dart';
import 'package:salespulse/views/customscroll/usage_customscroll_view.dart';
import 'package:auto_size_text/auto_size_text.dart';
import 'package:salespulse/views/profil/update_profil.dart';

class DrawerWidget extends StatefulWidget {
  const DrawerWidget({super.key});

  @override
  State<DrawerWidget> createState() => _DrawerWidgetState();
}

class _DrawerWidgetState extends State<DrawerWidget> {
  @override
  Widget build(BuildContext context) {
    // Utiliser Consumer pour récupérer les données du panier
    final store = Provider.of<AuthProvider>(context, listen: false).societeName;
    final number =
        Provider.of<AuthProvider>(context, listen: false).societeNumber;
    return Drawer(
        backgroundColor: const Color(0xff001c30),
        child: LayoutBuilder(builder: (context, constraints) {
          return ListView(
            children: [
              DrawerHeader(
                  decoration: const BoxDecoration(
                    color: Color(0xff001c30),
                    border: Border(
                      bottom: BorderSide(width: 2, color: Colors.orange)
                    )
                    ),
                  child: SizedBox(
                      width: AppSizes.responsiveValue(context, 80.0),
                      height: AppSizes.responsiveValue(context, 80.0),
                      child: Center(
                          child: Column(
                        crossAxisAlignment: CrossAxisAlignment.center,
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            store,
                            style: GoogleFonts.roboto(
                                fontSize: AppSizes.fontLarge,
                                fontWeight: FontWeight.w800,
                                color: Colors.orange),
                          ),
                          Text(
                            number,
                            style: GoogleFonts.roboto(
                                fontSize: AppSizes.fontMedium,
                                color:
                                    const Color.fromARGB(255, 231, 231, 231)),
                          ),
                        ],
                      )))),
              Container(
                  color: const Color.fromARGB(255, 238, 238, 238),
                  child: Column(children: [
                    Padding(
                      padding: EdgeInsets.all(AppSizes.responsiveValue(context, 8.0),),
                      child: Container(
                         margin: EdgeInsets.only(top: AppSizes.responsiveValue(context, 25.0),),
                        width: constraints.maxWidth,
                        decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(10),
                            color: const Color.fromARGB(255, 255, 255, 255)),
                        child: Column(
                          children: [
                            ListTile(
                              onTap: () {
                                Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                        builder: (context) =>
                                            const UpdateProfil()));
                              },
                              title: Row(
                                children: [
                                  Container(
                                   height: AppSizes.responsiveValue(context, 27.0),   
                                   width: AppSizes.responsiveValue(context, 27.0),
                                    decoration: BoxDecoration(
                                      borderRadius: BorderRadius.circular(5),
                                      color: const Color.fromARGB(255, 10, 165, 226),
                                    ),
                                    child: const Icon(LineIcons.userEdit,
                                        size: AppSizes.iconLarge,
                                        color: Color.fromARGB(255, 255, 255, 255)),
                                  ),
                                  const SizedBox(width: 20),
                                  AutoSizeText(
                                    "Modifier profil",
                                    minFontSize: 14,
                                    overflow: TextOverflow.ellipsis,
                                    style: GoogleFonts.roboto(
                                        fontSize: AppSizes.fontLarge,
                                        color: const Color.fromARGB(255, 20, 20, 20)),
                                  )
                                ],
                              ),
                            ),
                            ListTile(
                              onTap: () {
                                Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                        builder: (context) =>
                                            const UpdatePassword()));
                              },
                              title: Row(
                                children: [
                                  Container(
                                   height: 27,   
                                   width: 27,
                                    decoration: BoxDecoration(
                                      borderRadius: BorderRadius.circular(5),
                                      color: const Color.fromARGB(255, 7, 185, 75),
                                    ),
                                    
                                    child: const Icon(LineIcons.edit,
                                        size: AppSizes.iconLarge,
                                        color: Color.fromARGB(255, 255, 255, 255)),
                                  ),
                                  const SizedBox(width: 20),
                                  AutoSizeText(
                                    "Modifier password",
                                    minFontSize: 14,
                                    overflow: TextOverflow.ellipsis,
                                    style: GoogleFonts.roboto(
                                        fontSize: AppSizes.fontLarge,
                                        color: const Color.fromARGB(
                                            255, 20, 20, 20)),
                                  )
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.all(8.0),
                      child: Container(
                        width: constraints.maxWidth,
                        decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(10),
                            color: const Color.fromARGB(255, 255, 255, 255)),
                        child: Column(
                          children: [
                            ListTile(
                              onTap: () {
                                Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                        builder: (context) =>
                                            const ViewCustomScroll()));
                              },
                              title: Row(
                                children: [
                                  Container(
                                   height: 27,   
                                   width: 27,
                                    decoration: BoxDecoration(
                                      borderRadius: BorderRadius.circular(5),
                                      color: const Color.fromARGB(255, 255, 180, 17),
                                    ),
                                    
                                    child: const Icon(LineIcons.removeUser,
                                        size: AppSizes.iconLarge,
                                        color: Color.fromARGB(255, 255, 255, 255)),
                                  ),
                                  const SizedBox(width: 20),
                                  AutoSizeText(
                                    "Supprimer",
                                    minFontSize: 14,
                                    overflow: TextOverflow.ellipsis,
                                    style: GoogleFonts.roboto(
                                        fontSize: AppSizes.fontLarge,
                                        color: const Color.fromARGB(
                                            255, 20, 20, 20)),
                                  )
                                ],
                              ),
                            ),
                            Consumer<AuthProvider>(
                                builder: (context, provider, child) {
                              return ListTile(
                                onTap: () {
                                  provider.logoutButton();
                                },
                                title: Row(
                                  children: [
                                    Container(
                                     height: 27,   
                                     width: 27,
                                    decoration: BoxDecoration(
                                      borderRadius: BorderRadius.circular(5),
                                      color: const Color.fromARGB(255, 165, 10, 226),
                                    ),
                                    
                                      child: const Icon(LineIcons.alternateSignOut,
                                          size: AppSizes.iconLarge,
                                          color: Color.fromARGB(255, 255, 255, 255)),
                                    ),
                                    const SizedBox(width: 20),
                                    AutoSizeText(
                                      "Se deconnecter",
                                      style: GoogleFonts.roboto(
                                          fontSize: AppSizes.fontLarge,
                                          color: const Color.fromARGB(
                                              255, 20, 20, 20)),
                                    )
                                  ],
                                ),
                              );
                            }),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 100),
                    Padding(
                      padding: const EdgeInsets.all(8),
                      child: Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.start,
                          children: [
                            Text(
                              "Developper par Salif Moctar Konaté ",
                              style: GoogleFonts.roboto(
                                  fontSize: AppSizes.fontMedium,
                                  color: const Color.fromARGB(255, 17, 17, 17)),
                            ),
                             Text(
                              "from devSoft ",
                              style: GoogleFonts.roboto(
                                  fontSize: AppSizes.fontMedium,
                                  color: const Color.fromARGB(255, 17, 17, 17)),
                            ),
                            Text("v 1.0.0",
                                style: GoogleFonts.roboto(
                                    fontSize: AppSizes.fontSmall,
                                    color: Colors.grey))
                          ],
                        ),
                      ),
                    )
                  ]))
            ],
          );
        }));
  }
}
