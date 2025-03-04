// ignore_for_file: must_be_immutable

import 'dart:math';

import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:salespulse/models/chart_model.dart';
import 'package:salespulse/models/stats_week_model.dart';
import 'package:salespulse/utils/app_size.dart';


class BarChartWidget extends StatefulWidget {
 final List<StatsWeekModel> data ;
  const BarChartWidget({super.key, required this.data});

  @override
  State<BarChartWidget> createState() => _BarChartWidgetState();
}

class _BarChartWidgetState extends State<BarChartWidget> {
  @override
  Widget build(BuildContext context) {
    //convertir data au format ModelbarData
   List<ModelBarData> modelBarData = widget.data
    .map((e) => ModelBarData(
        x: int.parse(e.date?.split("-")[1] ?? '0'),
        y: e.total?.toDouble() ?? 0.0))
    .toList();


    return Padding(
      padding: EdgeInsets.all(min(AppSizes.responsiveValue(context, 8.0),16)),
      child: AspectRatio(
          aspectRatio: 2.6,
          child: Container(
            padding: EdgeInsets.all(AppSizes.responsiveValue(context, 20.0)),
            decoration: BoxDecoration(
                color: const Color(0xFF292D4E),
                borderRadius: BorderRadius.circular(20)),
            child: BarChart(
                swapAnimationDuration: const Duration(milliseconds: 800),
                swapAnimationCurve: Curves.linear,
                BarChartData(
                    minY: 0,
                    // maxY: 400000,
                    gridData: const FlGridData(show: false),
                    borderData: FlBorderData(show: false),
                    titlesData: myTitlesData(),
                    barTouchData: myBarTouchData(modelBarData),
                    barGroups: modelBarData
                        .asMap()
                        .entries
                        .map((item) => BarChartGroupData(x: item.key, barRods: [
                              BarChartRodData(
                                  toY: item.value.y,
                                  gradient:const LinearGradient(
                                    colors:[Colors.amber,Colors.red],
                                    begin: Alignment.topCenter,
                                    end: Alignment.bottomCenter
                                    ),
                                  // width: 22,
                                  backDrawRodData: BackgroundBarChartRodData(
                                      show: true,
                                      toY: 400000,
                                      color: Colors.black.withOpacity(0.4)),
                                  borderRadius: const BorderRadius.only(
                                      topLeft: Radius.circular(10),
                                      topRight: Radius.circular(10))),
                            ]))
                        .toList())),
          )),
    );
  }

  //definir les differentes titres
  FlTitlesData myTitlesData() {
    return FlTitlesData(
        show: true,
        topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
        leftTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
        rightTitles:
            const AxisTitles(sideTitles: SideTitles(showTitles: false)),
        bottomTitles: AxisTitles(
            sideTitles: SideTitles(
                showTitles: true,
                reservedSize: 30,
                getTitlesWidget: getBottomTitles)));
  }

  //lors de appui sur la barre afficher les valeur
  BarTouchData myBarTouchData(List<ModelBarData> modelBarData) {
    return BarTouchData(touchTooltipData:
        BarTouchTooltipData(
         // tooltipBgColor: Colors.transparent,
          tooltipMargin: -10,
          getTooltipItem: (group, groupIndex, rod, rodIndex) {
      String weekDay;
      switch (group.x) {
        case 0:
          weekDay = "Lundi";
          break;
        case 1:
          weekDay = "Mardi";
          break;
        case 2:
          weekDay = "Mercredi";
          break;
        case 3:
          weekDay = "Jeudi";
          break;
        case 4:
          weekDay = "Vendredi";
          break;
        case 5:
          weekDay = "Samedi";
          break;
        case 6:
          weekDay = "Dimanche";
          break;
        default:
          weekDay = "";
      }
      String montant;
      montant = "${modelBarData[group.x].y}";
      return BarTooltipItem(
          "$weekDay\n",
          TextStyle(
              fontSize: AppSizes.responsiveValue(context, 20.0), fontWeight: FontWeight.w500, color: Colors.white),
          children: [
            TextSpan(text: montant, style: TextStyle(fontSize: AppSizes.responsiveValue(context, 16.0),color:Colors.amber))
          ]);
    }));
  }

  // definir les titre de laxe des abscisses
  Widget getBottomTitles(double value, TitleMeta meta) {
    Widget text;
    switch (value.toInt()) {
      case 0:
        text = Text("Lun",
            style: GoogleFonts.roboto(
                fontSize: min(AppSizes.responsiveValue(context, 14.0),20),
                fontWeight: FontWeight.w400,
                color: const Color(0xFFD5CEDD)));
        break;
      case 1:
        text = Text("Mar",
            style: GoogleFonts.roboto(
                fontSize: min(AppSizes.responsiveValue(context, 14.0),20),
                fontWeight: FontWeight.w400,
                color: const Color(0xFFD5CEDD)));
        break;
      case 2:
        text = Text("Mer",
            style: GoogleFonts.roboto(
                fontSize: min(AppSizes.responsiveValue(context, 14.0),20),
                fontWeight: FontWeight.w400,
                color: const Color(0xFFD5CEDD)));
        break;
      case 3:
        text = Text("Jeu",
            style: GoogleFonts.roboto(
                fontSize: min(AppSizes.responsiveValue(context, 14.0),20),
                fontWeight: FontWeight.w400,
                color: const Color(0xFFD5CEDD)));
        break;
      case 4:
        text = Text("Ven",
            style: GoogleFonts.roboto(
                fontSize: min(AppSizes.responsiveValue(context, 14.0),20),
                fontWeight: FontWeight.w400,
                color: const Color(0xFFD5CEDD)));
        break;
      case 5:
        text = Text("Sam",
            style: GoogleFonts.roboto(
                fontSize:min(AppSizes.responsiveValue(context, 14.0),20),
                fontWeight: FontWeight.w400,
                color: const Color(0xFFD5CEDD)));
        break;
      case 6:
        text = Text("Dim",
            style: GoogleFonts.roboto(
                fontSize:min(AppSizes.responsiveValue(context, 14.0),20),
                fontWeight: FontWeight.w400,
                color: const Color(0xFFD5CEDD)));
        break;
      default:
        text = const Text('');
    }
    return SideTitleWidget(axisSide: meta.axisSide, child: text);
  }
}