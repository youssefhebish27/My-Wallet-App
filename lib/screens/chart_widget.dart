import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';

class ChartWidget extends StatefulWidget {
  final Map<String, double> dataMap;

  const ChartWidget({super.key, required this.dataMap});

  @override
  State<ChartWidget> createState() => _ChartWidgetState();
}

class _ChartWidgetState extends State<ChartWidget> {
  int touchedIndex = -1; // لمعرفة أي قسم تم لمسه

  // دالة الألوان عشان تكون نفس ألوان القائمة
  Color _getColor(String category) {
    switch (category) {
      case 'Food':
        return Colors.orangeAccent;
      case 'Transport':
        return Colors.blueAccent;
      case 'Shopping':
        return Colors.pinkAccent;
      case 'Entertainment':
        return Colors.purpleAccent;
      case 'Health':
        return Colors.greenAccent;
      case 'Bills':
        return Colors.redAccent;
      default:
        return Colors.grey;
    }
  }

  @override
  Widget build(BuildContext context) {
    // تجهيز البيانات
    List<PieChartSectionData> sections = [];
    int index = 0;

    // حساب الإجمالي للنسبة المئوية
    double total = widget.dataMap.values.fold(0, (sum, item) => sum + item);

    widget.dataMap.forEach((key, value) {
      final isTouched = index == touchedIndex;
      // السحر هنا: لو ملموس، نصف القطر بيكبر (60)، لو لأ بيفضل عادي (50)
      final radius = isTouched ? 60.0 : 50.0;
      final fontSize = isTouched ? 25.0 : 16.0;
      final widgetValue = value;

      sections.add(
        PieChartSectionData(
          color: _getColor(key),
          value: widgetValue,
          title: isTouched
              ? '${(value / total * 100).toStringAsFixed(0)}%'
              : '', // يظهر النسبة فقط عند اللمس
          radius: radius,
          titleStyle: TextStyle(
            fontSize: fontSize,
            fontWeight: FontWeight.bold,
            color: Colors.white,
            shadows: [const Shadow(color: Colors.black, blurRadius: 2)],
          ),
          badgeWidget: isTouched
              ? _buildBadge(key, value)
              : null, // يظهر أيقونة واسم عند اللمس
          badgePositionPercentageOffset: .98,
        ),
      );
      index++;
    });

    return SizedBox(
      height: 250, // ارتفاع الشارت
      child: Stack(
        alignment: Alignment.center,
        children: [
          // النص في المنتصف (يعرض الإجمالي أو القسم المختار)
          Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text(
                "Total Spent",
                style: TextStyle(color: Colors.grey, fontSize: 12),
              ),
              Text(
                touchedIndex == -1
                    ? "\$${total.toStringAsFixed(0)}" // لو مش لامس حاجة يعرض الإجمالي
                    : widget.dataMap.keys.elementAt(
                        touchedIndex,
                      ), // لو لامس يعرض اسم القسم
                style: TextStyle(
                  color: Colors.white,
                  fontSize: touchedIndex == -1 ? 28 : 22,
                  fontWeight: FontWeight.bold,
                ),
              ),
              if (touchedIndex != -1)
                Text(
                  "\$${widget.dataMap.values.elementAt(touchedIndex).toStringAsFixed(0)}",
                  style: const TextStyle(
                    color: Color(0xFFBB86FC),
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
            ],
          ),

          // الرسم البياني نفسه
          PieChart(
            PieChartData(
              pieTouchData: PieTouchData(
                touchCallback: (FlTouchEvent event, pieTouchResponse) {
                  setState(() {
                    if (!event.isInterestedForInteractions ||
                        pieTouchResponse == null ||
                        pieTouchResponse.touchedSection == null) {
                      touchedIndex = -1;
                      return;
                    }
                    touchedIndex =
                        pieTouchResponse.touchedSection!.touchedSectionIndex;
                  });
                },
              ),
              borderData: FlBorderData(show: false),
              sectionsSpace: 2, // مسافة بيضاء صغيرة بين الأقسام
              centerSpaceRadius: 70, // وسع الدائرة الفاضية في النص
              sections: sections,
            ),
          ),
        ],
      ),
    );
  }

  // تصميم التاج (Badge) اللي بيظهر لما تلمس
  Widget _buildBadge(String category, double amount) {
    return Container(
      padding: const EdgeInsets.all(5),
      decoration: BoxDecoration(
        color: Colors.white,
        shape: BoxShape.circle,
        boxShadow: [
          BoxShadow(color: Colors.black.withOpacity(0.5), blurRadius: 5),
        ],
      ),
      child: Icon(_getIcon(category), color: _getColor(category), size: 20),
    );
  }

  IconData _getIcon(String category) {
    switch (category) {
      case 'Food':
        return Icons.fastfood;
      case 'Transport':
        return Icons.directions_car;
      case 'Shopping':
        return Icons.shopping_bag;
      case 'Entertainment':
        return Icons.movie;
      case 'Health':
        return Icons.medical_services;
      case 'Bills':
        return Icons.receipt_long;
      default:
        return Icons.category;
    }
  }
}
