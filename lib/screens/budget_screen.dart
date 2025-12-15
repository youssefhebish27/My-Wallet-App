import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';

class BudgetScreen extends StatefulWidget {
  // نستقبل إجمالي المصاريف من الصفحة الرئيسية
  final double totalSpent;
  const BudgetScreen({super.key, required this.totalSpent});

  @override
  State<BudgetScreen> createState() => _BudgetScreenState();
}

class _BudgetScreenState extends State<BudgetScreen> {
  final _myBox = Hive.box('expense_database');
  final _budgetController = TextEditingController();

  double _budgetLimit = 0.0;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  void _loadData() {
    _budgetLimit = _myBox.get('budget_limit') ?? 0.0;
    _budgetController.text = _budgetLimit == 0
        ? ''
        : _budgetLimit.toStringAsFixed(0);
    setState(() {});
  }

  void _saveBudget() {
    final amount = double.tryParse(_budgetController.text);
    if (amount != null && amount > 0) {
      _myBox.put('budget_limit', amount);
      setState(() {
        _budgetLimit = amount;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Budget Plan Saved!'),
          backgroundColor: Colors.green,
        ),
      );
      FocusScope.of(context).unfocus();
    }
  }

  void _resetBudget() {
    _myBox.delete('budget_limit');
    setState(() {
      _budgetLimit = 0.0;
      _budgetController.clear();
    });
  }

  @override
  Widget build(BuildContext context) {
    // نستخدم widget.totalSpent القادمة من الفايربيز
    double progress = _budgetLimit == 0
        ? 0
        : (widget.totalSpent / _budgetLimit);
    Color statusColor = progress < 0.5
        ? Colors.green
        : (progress < 0.85 ? Colors.orange : Colors.red);

    // نصوص الحالة
    String statusText;
    if (_budgetLimit == 0) {
      statusText = "No budget set yet.";
    } else if (progress < 0.5) {
      statusText = "Excellent! Keep it up 👍";
    } else if (progress < 0.85) {
      statusText = "Careful! You're halfway ⚠️";
    } else {
      statusText = "Alert! Overspending 🚨";
    }

    double displayProgress = progress > 1 ? 1 : progress;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Budget Plan'),
        backgroundColor: Colors.transparent,
        elevation: 0,
        actions: [
          if (_budgetLimit > 0)
            IconButton(
              icon: const Icon(Icons.refresh, color: Colors.redAccent),
              onPressed: _resetBudget,
            ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(25.0),
        child: Column(
          children: [
            Stack(
              alignment: Alignment.center,
              children: [
                SizedBox(
                  height: 200,
                  width: 200,
                  child: CircularProgressIndicator(
                    value: displayProgress,
                    strokeWidth: 15,
                    backgroundColor: Colors.white10,
                    valueColor: AlwaysStoppedAnimation<Color>(statusColor),
                  ),
                ),
                Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      "${(progress * 100).toStringAsFixed(0)}%",
                      style: TextStyle(
                        fontSize: 40,
                        fontWeight: FontWeight.bold,
                        color: statusColor,
                      ),
                    ),
                    const Text("Used", style: TextStyle(color: Colors.grey)),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 30),
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: const Color(0xFF2C2C2C),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: statusColor.withOpacity(0.3)),
              ),
              child: Column(
                children: [
                  Text(
                    statusText,
                    style: TextStyle(
                      color: statusColor,
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                  ),
                  const SizedBox(height: 20),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      _buildInfo(
                        "Spent",
                        "\$${widget.totalSpent.toStringAsFixed(0)}",
                        Colors.white,
                      ),
                      Container(width: 1, height: 40, color: Colors.grey),
                      _buildInfo(
                        "Remaining",
                        "\$${(_budgetLimit - widget.totalSpent).toStringAsFixed(0)}",
                        statusColor,
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 40),
            const Align(
              alignment: Alignment.centerLeft,
              child: Text(
                "Update Plan",
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
            ),
            const SizedBox(height: 15),
            TextField(
              controller: _budgetController,
              keyboardType: TextInputType.number,
              style: const TextStyle(color: Colors.white),
              decoration: InputDecoration(
                prefixIcon: const Icon(
                  Icons.savings_outlined,
                  color: Color(0xFFBB86FC),
                ),
                labelText: 'Monthly Limit',
                filled: true,
                fillColor: const Color(0xFF1E1E1E),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(15),
                ),
              ),
            ),
            const SizedBox(height: 20),
            SizedBox(
              width: double.infinity,
              height: 50,
              child: ElevatedButton(
                onPressed: _saveBudget,
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFFBB86FC),
                  foregroundColor: Colors.black,
                ),
                child: const Text(
                  "Save Budget",
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInfo(String label, String value, Color color) {
    return Column(
      children: [
        Text(label, style: const TextStyle(color: Colors.grey, fontSize: 12)),
        const SizedBox(height: 5),
        Text(
          value,
          style: TextStyle(
            fontSize: 22,
            fontWeight: FontWeight.bold,
            color: color,
          ),
        ),
      ],
    );
  }
}
