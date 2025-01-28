import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:salespulse/providers/auth_provider.dart';
import 'package:salespulse/utils/app_size.dart';
import 'package:salespulse/views/auth/login_view.dart';
import 'package:salespulse/views/dashbord/dashboard.dart';
import 'package:salespulse/views/depenses/depense_view.dart';
import 'package:salespulse/views/rapports/rapports.dart';
import 'package:salespulse/views/stocks/stocks.dart';
import 'package:salespulse/views/ventes/ventes.dart';
import 'package:curved_navigation_bar/curved_navigation_bar.dart';

class Routes extends StatefulWidget {
  const Routes({super.key});

  @override
  State<Routes> createState() => _RoutesState();
}

class _RoutesState extends State<Routes> {
  int _currentIndex = 0;

  @override
  Widget build(BuildContext context) {
    return Scaffold(body: Consumer<AuthProvider>(
      builder: (context, provider, child) {
        // Si le token est présent, afficher les vues de l'application
        if (provider.token.isNotEmpty) {
          return <Widget>[
            const DashboardView(),
            const StocksView(),
            const VenteView(),
            const RapportView(),
            const DepensesView(),
            const DashboardView()
          ][_currentIndex];
        } else {
          // Si pas de token, afficher la page de connexion
          return const LoginView();
        }
      },
    ), bottomNavigationBar:
        Consumer<AuthProvider>(builder: (context, provider, child) {
      if (provider.token.isNotEmpty) {
        return _buildBottomNavigation();
      } else {
        // Si pas de token, ne rien afficher
        return const SizedBox.shrink();
      }
    }));
  }

  Widget _buildBottomNavigation() {
    return SizedBox(
      height: 80,
      child: CurvedNavigationBar(
        index: _currentIndex,
        onTap: (index) {
          setState(() {
            _currentIndex = index;
          });
        },
        letIndexChange: (index) => true,
        color: const Color(0xff001c30),
        buttonBackgroundColor: const Color.fromARGB( 255, 255, 136, 0), //const Color.fromARGB(255, 126, 61, 248),
        backgroundColor: Colors.transparent,
        animationCurve: Curves.easeInOut,
        animationDuration: const Duration(milliseconds: 600),
        items: const [
          Icon(Icons.stacked_bar_chart_rounded , size:AppSizes.iconLarge, color: Colors.white),
          Icon(Icons.view_in_ar_outlined , size:AppSizes.iconLarge, color: Colors.white),
          Icon(Icons.clean_hands_rounded , size:AppSizes.iconLarge, color: Colors.white),
          Icon(Icons.library_books_sharp , size:AppSizes.iconLarge, color: Colors.white),
          Icon(Icons.balance_sharp , size:AppSizes.iconLarge, color: Colors.white),
        ],
      ),
    );
  }
}
