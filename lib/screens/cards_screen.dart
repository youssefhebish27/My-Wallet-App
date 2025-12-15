import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';

class CardsScreen extends StatefulWidget {
  const CardsScreen({super.key});

  @override
  State<CardsScreen> createState() => _CardsScreenState();
}

class _CardsScreenState extends State<CardsScreen> {
  final _myBox = Hive.box('expense_database');
  List<Map<String, dynamic>> _myCards = [];

  final _bankNameController = TextEditingController();
  final _balanceController = TextEditingController();
  final _cardNumberController = TextEditingController();

  // متغير للتحكم في ظهور خانة الرقم
  bool _isWallet = false;

  @override
  void initState() {
    super.initState();
    _loadCards();
  }

  void _loadCards() {
    final data = _myBox.get('user_cards');
    if (data != null) {
      setState(() {
        _myCards = List<Map<String, dynamic>>.from(
          (data as List).map((e) => Map<String, dynamic>.from(e)),
        );
      });
    }
  }

  void _saveCards() => _myBox.put('user_cards', _myCards);

  Color _getBankColor(String bankName) {
    String name = bankName.toLowerCase();
    if (name.contains('cib')) return const Color(0xFF003399);
    if (name.contains('vodafone') || name.contains('cash'))
      return const Color(0xFFE60000);
    if (name.contains('orange')) return const Color(0xFFFF7900);
    if (name.contains('etisalat')) return const Color(0xFF138535);
    if (name.contains('we') || name.contains('telecom'))
      return const Color(0xFF5C2D91);
    if (name.contains('instapay')) return const Color(0xFF4A148C);
    if (name.contains('nbe') || name.contains('ahly'))
      return const Color(0xFF007A33);
    if (name.contains('qnb')) return const Color(0xFF97005A);
    return const Color(0xFF333333);
  }

  void _addCard() {
    if (_bankNameController.text.isEmpty || _balanceController.text.isEmpty)
      return;
    setState(() {
      _myCards.add({
        'bankName': _bankNameController.text,
        'balance': double.tryParse(_balanceController.text) ?? 0.0,
        // لو محفظة، نخلي الرقم فارغ
        'cardNumber': _isWallet
            ? ''
            : (_cardNumberController.text.isEmpty
                  ? '0000'
                  : _cardNumberController.text),
      });
    });
    _saveCards();
    Navigator.pop(context);
    _bankNameController.clear();
    _balanceController.clear();
    _cardNumberController.clear();
    _isWallet = false;
  }

  void _openAddCardDialog() {
    showDialog(
      context: context,
      builder: (ctx) {
        return StatefulBuilder(
          builder: (context, setStateDialog) {
            return AlertDialog(
              backgroundColor: const Color(0xFF2C2C2C),
              title: const Text(
                'Add New Card/Wallet',
                style: TextStyle(color: Colors.white),
              ),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextField(
                    controller: _bankNameController,
                    style: const TextStyle(color: Colors.white),
                    decoration: InputDecoration(
                      labelText: 'Name (e.g. CIB, Vodafone)',
                      filled: true,
                      fillColor: const Color(0xFF1E1E1E),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                    onChanged: (val) {
                      // منطق ذكي: لو كتب فودافون أو كاش، نخفي الرقم تلقائي
                      String v = val.toLowerCase();
                      bool isW =
                          v.contains('vodafone') ||
                          v.contains('cash') ||
                          v.contains('etisalat') ||
                          v.contains('orange') ||
                          v.contains('we') ||
                          v.contains('instapay');
                      if (isW != _isWallet)
                        setStateDialog(() => _isWallet = isW);
                    },
                  ),
                  const SizedBox(height: 10),
                  TextField(
                    controller: _balanceController,
                    keyboardType: TextInputType.number,
                    style: const TextStyle(color: Colors.white),
                    decoration: InputDecoration(
                      labelText: 'Balance',
                      prefixIcon: const Icon(
                        Icons.attach_money,
                        color: Colors.green,
                      ),
                      filled: true,
                      fillColor: const Color(0xFF1E1E1E),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                  ),
                  // إخفاء خانة الرقم إذا كانت محفظة
                  if (!_isWallet) ...[
                    const SizedBox(height: 10),
                    TextField(
                      controller: _cardNumberController,
                      keyboardType: TextInputType.number,
                      maxLength: 4,
                      style: const TextStyle(color: Colors.white),
                      decoration: InputDecoration(
                        labelText: 'Last 4 Digits (Visa Only)',
                        hintText: 'xxxx',
                        filled: true,
                        fillColor: const Color(0xFF1E1E1E),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                      ),
                    ),
                  ],
                ],
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(ctx),
                  child: const Text('Cancel'),
                ),
                ElevatedButton(
                  onPressed: _addCard,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFFBB86FC),
                  ),
                  child: const Text(
                    'Add',
                    style: TextStyle(color: Colors.black),
                  ),
                ),
              ],
            );
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('My Cards'),
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      body: ListView.builder(
        padding: const EdgeInsets.all(20),
        itemCount: _myCards.length,
        itemBuilder: (ctx, index) {
          final card = _myCards[index];
          final cardColor = _getBankColor(card['bankName']);
          // هل يوجد رقم كارت للعرض؟
          bool showNumber =
              card['cardNumber'] != null &&
              card['cardNumber'].toString().isNotEmpty;

          return Dismissible(
            key: Key(UniqueKey().toString()),
            onDismissed: (_) {
              setState(() => _myCards.removeAt(index));
              _saveCards();
            },
            background: Container(
              color: Colors.red,
              child: const Icon(Icons.delete),
            ),
            child: Container(
              height: 200,
              margin: const EdgeInsets.only(bottom: 20),
              padding: const EdgeInsets.all(25),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [cardColor, cardColor.withOpacity(0.7)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(25),
                boxShadow: [
                  BoxShadow(
                    color: cardColor.withOpacity(0.4),
                    blurRadius: 10,
                    offset: const Offset(0, 5),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        card['bankName'],
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Icon(
                        showNumber ? Icons.credit_card : Icons.phone_android,
                        color: Colors.white70,
                        size: 30,
                      ),
                    ],
                  ),
                  // عرض الشريحة والرقم فقط للفيزا
                  if (showNumber) ...[
                    Container(
                      width: 50,
                      height: 35,
                      decoration: BoxDecoration(
                        color: const Color(0xFFD4AF37).withOpacity(0.8),
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                    Text(
                      "**** **** **** ${card['cardNumber']}",
                      style: const TextStyle(
                        color: Colors.white70,
                        fontSize: 18,
                        letterSpacing: 3,
                      ),
                    ),
                  ] else
                    // لو محفظة نعرض أيقونة محفظة كبيرة
                    const Center(
                      child: Icon(
                        Icons.account_balance_wallet,
                        size: 50,
                        color: Colors.white24,
                      ),
                    ),

                  Text(
                    "\$${(card['balance'] as double).toStringAsFixed(2)}",
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _openAddCardDialog,
        backgroundColor: const Color(0xFFBB86FC),
        child: const Icon(Icons.add, color: Colors.black),
      ),
    );
  }
}
