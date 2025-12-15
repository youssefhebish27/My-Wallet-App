import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';

class SubscriptionsScreen extends StatefulWidget {
  const SubscriptionsScreen({super.key});

  @override
  State<SubscriptionsScreen> createState() => _SubscriptionsScreenState();
}

class _SubscriptionsScreenState extends State<SubscriptionsScreen> {
  final _myBox = Hive.box('expense_database');

  List<Map<String, dynamic>> _subscriptions = [];

  final _nameController = TextEditingController();
  final _amountController = TextEditingController();
  String _selectedCycle = 'Monthly';
  DateTime? _nextBillDate;

  @override
  void initState() {
    super.initState();
    _loadSubs();
  }

  void _loadSubs() {
    final data = _myBox.get('user_subs');
    if (data != null) {
      setState(() {
        _subscriptions = List<Map<String, dynamic>>.from(
          (data as List).map((e) => Map<String, dynamic>.from(e)),
        );
      });
    }
  }

  void _saveSubs() {
    _myBox.put('user_subs', _subscriptions);
  }

  double get _totalMonthly {
    double total = 0;
    for (var sub in _subscriptions) {
      double amount = (sub['amount'] as num).toDouble();
      if (sub['cycle'] == 'Yearly') {
        total += amount / 12;
      } else {
        total += amount;
      }
    }
    return total;
  }

  Color _getBrandColor(String name) {
    String lowerName = name.toLowerCase();
    if (lowerName.contains('netflix')) return const Color(0xFFE50914);
    if (lowerName.contains('spotify')) return const Color(0xFF1DB954);
    if (lowerName.contains('youtube')) return const Color(0xFFFF0000);
    if (lowerName.contains('shahid')) return const Color(0xFF182C58);
    if (lowerName.contains('bein')) return const Color(0xFF581C87);
    if (lowerName.contains('prime') || lowerName.contains('amazon'))
      return const Color(0xFF00A8E1);
    if (lowerName.contains('disney')) return const Color(0xFF113CCF);
    if (lowerName.contains('apple') || lowerName.contains('icloud'))
      return const Color(0xFF333333);
    if (lowerName.contains('vodafone')) return const Color(0xFFE60000);
    if (lowerName.contains('orange')) return const Color(0xFFFF7900);
    if (lowerName.contains('etisalat')) return const Color(0xFF7AC142);
    if (lowerName.contains('we') || lowerName.contains('telecom'))
      return const Color(0xFF5C2D91);
    return Colors.grey[800]!;
  }

  IconData _getBrandIcon(String name) {
    String lowerName = name.toLowerCase();
    if (lowerName.contains('netflix') ||
        lowerName.contains('shahid') ||
        lowerName.contains('disney') ||
        lowerName.contains('youtube'))
      return Icons.movie_filter;
    if (lowerName.contains('spotify') ||
        lowerName.contains('music') ||
        lowerName.contains('anghami'))
      return Icons.music_note;
    if (lowerName.contains('bein') || lowerName.contains('sport'))
      return Icons.sports_soccer;
    if (lowerName.contains('vodafone') ||
        lowerName.contains('orange') ||
        lowerName.contains('we'))
      return Icons.wifi;
    return Icons.card_membership;
  }

  void _addSubscription() {
    if (_nameController.text.isEmpty ||
        _amountController.text.isEmpty ||
        _nextBillDate == null)
      return;

    setState(() {
      _subscriptions.add({
        'name': _nameController.text,
        'amount': double.tryParse(_amountController.text) ?? 0.0,
        'cycle': _selectedCycle,
        'date': _nextBillDate!.toIso8601String(),
      });
    });

    _saveSubs();
    Navigator.pop(context);
    _nameController.clear();
    _amountController.clear();
    _nextBillDate = null;
    _selectedCycle = 'Monthly';
  }

  void _deleteSub(int index) {
    setState(() {
      _subscriptions.removeAt(index);
    });
    _saveSubs();
  }

  void _openAddDialog() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: const Color(0xFF1E1E1E),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(25)),
      ),
      builder: (ctx) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            return Padding(
              padding: EdgeInsets.only(
                top: 25,
                left: 20,
                right: 20,
                bottom: MediaQuery.of(ctx).viewInsets.bottom + 20,
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'New Subscription',
                    style: TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFFBB86FC),
                    ),
                  ),
                  const SizedBox(height: 20),

                  TextField(
                    controller: _nameController,
                    style: const TextStyle(color: Colors.white),
                    decoration: InputDecoration(
                      labelText: 'Service Name (e.g. Netflix, BeIN)',
                      filled: true,
                      fillColor: const Color(0xFF2C2C2C),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(15),
                      ),
                      prefixIcon: const Icon(
                        Icons.subscriptions,
                        color: Color(0xFF03DAC6),
                      ),
                    ),
                  ),
                  const SizedBox(height: 15),

                  Row(
                    children: [
                      Expanded(
                        child: TextField(
                          controller: _amountController,
                          keyboardType: TextInputType.number,
                          style: const TextStyle(color: Colors.white),
                          decoration: InputDecoration(
                            labelText: 'Cost',
                            suffixText: 'EGP', // إضافة العملة هنا
                            filled: true,
                            fillColor: const Color(0xFF2C2C2C),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(15),
                            ),
                            prefixIcon: const Icon(
                              Icons.money,
                              color: Color(0xFF03DAC6),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 15),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10),
                        decoration: BoxDecoration(
                          color: const Color(0xFF2C2C2C),
                          borderRadius: BorderRadius.circular(15),
                        ),
                        child: DropdownButtonHideUnderline(
                          child: DropdownButton<String>(
                            value: _selectedCycle,
                            dropdownColor: const Color(0xFF2C2C2C),
                            style: const TextStyle(color: Colors.white),
                            items: ['Monthly', 'Yearly'].map((String value) {
                              return DropdownMenuItem<String>(
                                value: value,
                                child: Text(value),
                              );
                            }).toList(),
                            onChanged: (newValue) {
                              setModalState(() {
                                _selectedCycle = newValue!;
                              });
                            },
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 15),

                  GestureDetector(
                    onTap: () async {
                      final picked = await showDatePicker(
                        context: context,
                        initialDate: DateTime.now(),
                        firstDate: DateTime.now(),
                        lastDate: DateTime(2030),
                        builder: (context, child) => Theme(
                          data: ThemeData.dark().copyWith(
                            colorScheme: const ColorScheme.dark(
                              primary: Color(0xFFBB86FC),
                              onPrimary: Colors.black,
                              surface: Color(0xFF1E1E1E),
                            ),
                          ),
                          child: child!,
                        ),
                      );
                      if (picked != null) {
                        setModalState(() => _nextBillDate = picked);
                      }
                    },
                    child: Container(
                      height: 55,
                      width: double.infinity,
                      padding: const EdgeInsets.symmetric(horizontal: 15),
                      decoration: BoxDecoration(
                        color: const Color(0xFF2C2C2C),
                        borderRadius: BorderRadius.circular(15),
                        border: Border.all(
                          color: _nextBillDate == null
                              ? Colors.transparent
                              : const Color(0xFFBB86FC),
                        ),
                      ),
                      child: Row(
                        children: [
                          Icon(
                            Icons.calendar_today,
                            color: _nextBillDate == null
                                ? Colors.grey
                                : const Color(0xFFBB86FC),
                          ),
                          const SizedBox(width: 10),
                          Text(
                            _nextBillDate == null
                                ? 'Select Next Billing Date'
                                : '${_nextBillDate!.day}/${_nextBillDate!.month}/${_nextBillDate!.year}',
                            style: TextStyle(
                              color: _nextBillDate == null
                                  ? Colors.grey
                                  : Colors.white,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),

                  const SizedBox(height: 25),
                  SizedBox(
                    width: double.infinity,
                    height: 50,
                    child: ElevatedButton(
                      onPressed: _addSubscription,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFFBB86FC),
                      ),
                      child: const Text(
                        'Add Subscription',
                        style: TextStyle(
                          color: Colors.black,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
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
        title: const Text('My Subscriptions'),
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      body: Column(
        children: [
          // ملخص المصاريف (بالجنيه المصري)
          Container(
            width: double.infinity,
            margin: const EdgeInsets.all(20),
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0xFF2E3192), Color(0xFF1BFFFF)],
              ),
              borderRadius: BorderRadius.circular(20),
              boxShadow: [
                BoxShadow(
                  color: const Color(0xFF2E3192).withOpacity(0.4),
                  blurRadius: 10,
                  offset: const Offset(0, 5),
                ),
              ],
            ),
            child: Column(
              children: [
                const Text(
                  "Monthly Commitments",
                  style: TextStyle(
                    color: Colors.black54,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 5),
                // هنا التغيير: عرض EGP بدلاً من $
                Text(
                  "${_totalMonthly.toStringAsFixed(2)} EGP",
                  style: const TextStyle(
                    fontSize: 32,
                    fontWeight: FontWeight.bold,
                    color: Colors.black87,
                  ),
                ),
                const Text(
                  "/ month",
                  style: TextStyle(color: Colors.black54, fontSize: 12),
                ),
              ],
            ),
          ),

          Expanded(
            child: _subscriptions.isEmpty
                ? Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: const [
                        Icon(
                          Icons.subscriptions_outlined,
                          size: 70,
                          color: Colors.grey,
                        ),
                        SizedBox(height: 10),
                        Text(
                          'No subscriptions active.',
                          style: TextStyle(color: Colors.grey),
                        ),
                      ],
                    ),
                  )
                : ListView.builder(
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    itemCount: _subscriptions.length,
                    itemBuilder: (ctx, index) {
                      final sub = _subscriptions[index];
                      final date = DateTime.parse(sub['date']);
                      final brandColor = _getBrandColor(sub['name']);
                      final daysLeft = date.difference(DateTime.now()).inDays;

                      return Dismissible(
                        key: Key(UniqueKey().toString()),
                        direction: DismissDirection.endToStart,
                        onDismissed: (_) => _deleteSub(index),
                        background: Container(
                          alignment: Alignment.centerRight,
                          padding: const EdgeInsets.only(right: 20),
                          color: Colors.red,
                          child: const Icon(Icons.delete, color: Colors.white),
                        ),
                        child: Container(
                          margin: const EdgeInsets.only(bottom: 15),
                          decoration: BoxDecoration(
                            color: const Color(0xFF2C2C2C),
                            borderRadius: BorderRadius.circular(15),
                            border: Border(
                              left: BorderSide(color: brandColor, width: 5),
                            ),
                          ),
                          child: ListTile(
                            contentPadding: const EdgeInsets.symmetric(
                              horizontal: 15,
                              vertical: 8,
                            ),
                            leading: Container(
                              padding: const EdgeInsets.all(10),
                              decoration: BoxDecoration(
                                color: brandColor.withOpacity(0.2),
                                shape: BoxShape.circle,
                              ),
                              child: Icon(
                                _getBrandIcon(sub['name']),
                                color: brandColor,
                              ),
                            ),
                            title: Text(
                              sub['name'],
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                                color: Colors.white,
                                fontSize: 16,
                              ),
                            ),
                            subtitle: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const SizedBox(height: 5),
                                // هنا التغيير: عرض EGP في القائمة
                                Text(
                                  '${sub['amount']} EGP / ${sub['cycle']}',
                                  style: const TextStyle(color: Colors.white70),
                                ),
                                Text(
                                  'Next bill: ${date.day}/${date.month} (${daysLeft > 0 ? "$daysLeft days left" : "Due soon!"})',
                                  style: TextStyle(
                                    color: daysLeft < 3
                                        ? Colors.redAccent
                                        : Colors.grey,
                                    fontSize: 12,
                                  ),
                                ),
                              ],
                            ),
                            trailing: IconButton(
                              icon: const Icon(
                                Icons.arrow_forward_ios,
                                size: 16,
                                color: Colors.grey,
                              ),
                              onPressed: () {},
                            ),
                          ),
                        ),
                      );
                    },
                  ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _openAddDialog,
        backgroundColor: const Color(0xFFBB86FC),
        child: const Icon(Icons.add, color: Colors.black),
      ),
    );
  }
}
