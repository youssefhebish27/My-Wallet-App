import 'package:flutter/material.dart';

class GoldScreen extends StatefulWidget {
  const GoldScreen({super.key});

  @override
  State<GoldScreen> createState() => _GoldScreenState();
}

class _GoldScreenState extends State<GoldScreen> {
  final _priceController = TextEditingController(); // سعر الجرام
  final _budgetController = TextEditingController(); // ميزانيتك

  double _gramsResult = 0.0;
  String _selectedMetal = 'Gold 21K';

  // القائمة بناءً على الصورة
  final List<String> _metalTypes = [
    'Gold 24K',
    'Gold 22K',
    'Gold 21K',
    'Gold 18K',
    'Gold 12K',
  ];

  @override
  void initState() {
    super.initState();
    _updateDefaultPrice(); // تحديث السعر عند فتح الصفحة
  }

  // دالة لتحديث السعر تلقائياً بناءً على الصورة التي أرسلتها
  void _updateDefaultPrice() {
    double price = 0.0;
    switch (_selectedMetal) {
      case 'Gold 24K':
        price = 6560.0;
        break; // تقديري بناءً على النسبة
      case 'Gold 22K':
        price = 6013.0;
        break; // من الصورة
      case 'Gold 21K':
        price = 5740.0;
        break; // من الصورة
      case 'Gold 18K':
        price = 4920.0;
        break; // من الصورة
      case 'Gold 12K':
        price = 3280.0;
        break; // من الصورة
    }
    _priceController.text = price.toStringAsFixed(0);
    _calculate();
  }

  void _calculate() {
    double pricePerGram = double.tryParse(_priceController.text) ?? 0.0;
    double myBudget = double.tryParse(_budgetController.text) ?? 0.0;

    setState(() {
      if (pricePerGram > 0) {
        _gramsResult = myBudget / pricePerGram;
      } else {
        _gramsResult = 0.0;
      }
    });
  }

  Color _getMetalColor() {
    if (_selectedMetal.contains('Gold')) return const Color(0xFFFFD700);
    return const Color(0xFFC0C0C0);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Gold Calculator 🪙'),
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(25),
        child: Column(
          children: [
            // كارت النتيجة
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(25),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    const Color(0xFF1E1E1E),
                    _getMetalColor().withOpacity(0.2),
                  ],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(25),
                border: Border.all(color: _getMetalColor().withOpacity(0.5)),
              ),
              child: Column(
                children: [
                  Icon(Icons.scale, size: 50, color: _getMetalColor()),
                  const SizedBox(height: 10),
                  const Text(
                    "You can buy approx:",
                    style: TextStyle(color: Colors.grey),
                  ),
                  const SizedBox(height: 5),
                  Text(
                    "${_gramsResult.toStringAsFixed(2)} grams",
                    style: TextStyle(
                      color: _getMetalColor(),
                      fontSize: 35,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 30),

            // القائمة المنسدلة
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 15),
              decoration: BoxDecoration(
                color: const Color(0xFF2C2C2C),
                borderRadius: BorderRadius.circular(15),
              ),
              child: DropdownButtonHideUnderline(
                child: DropdownButton<String>(
                  value: _selectedMetal,
                  isExpanded: true,
                  dropdownColor: const Color(0xFF2C2C2C),
                  style: const TextStyle(color: Colors.white, fontSize: 16),
                  items: _metalTypes
                      .map(
                        (String value) =>
                            DropdownMenuItem(value: value, child: Text(value)),
                      )
                      .toList(),
                  onChanged: (newValue) {
                    setState(() {
                      _selectedMetal = newValue!;
                      _updateDefaultPrice(); // تحديث السعر تلقائياً عند تغيير العيار
                    });
                  },
                ),
              ),
            ),

            const SizedBox(height: 20),

            // 1. سعر الجرام (يملأ تلقائياً)
            TextField(
              controller: _priceController,
              keyboardType: TextInputType.number,
              style: const TextStyle(color: Colors.white),
              decoration: InputDecoration(
                labelText: "Price Per Gram (Auto-filled)",
                suffixText: "EGP",
                prefixIcon: const Icon(
                  Icons.price_check,
                  color: Color(0xFFBB86FC),
                ),
                filled: true,
                fillColor: const Color(0xFF1E1E1E),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(15),
                ),
              ),
              onChanged: (_) => _calculate(),
            ),

            const SizedBox(height: 20),

            // 2. ميزانيتك
            TextField(
              controller: _budgetController,
              keyboardType: TextInputType.number,
              style: const TextStyle(color: Colors.white),
              decoration: InputDecoration(
                labelText: "Your Total Budget",
                suffixText: "EGP",
                prefixIcon: const Icon(Icons.wallet, color: Color(0xFF03DAC6)),
                filled: true,
                fillColor: const Color(0xFF1E1E1E),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(15),
                ),
              ),
              onChanged: (_) => _calculate(),
            ),
          ],
        ),
      ),
    );
  }
}
