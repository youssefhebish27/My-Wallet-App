import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'chart_widget.dart';
import 'login_screen.dart';
import 'budget_screen.dart';
import 'profile_screen.dart';
import 'cards_screen.dart';
import 'subscriptions_screen.dart';
import 'goals_screen.dart';
import 'converter_screen.dart';
import 'gold_screen.dart';
import 'stats_screen.dart'; // إضافة ملف التحليلات الجديد

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  final _myBox = Hive.box('expense_database');
  final _auth = FirebaseAuth.instance;
  final _firestore = FirebaseFirestore.instance;

  final _titleController = TextEditingController();
  final _amountController = TextEditingController();

  // متغيرات البحث والفلترة
  final _searchController = TextEditingController();
  String _filterCategory = 'All';

  DateTime _selectedDate = DateTime.now();
  String _selectedCategory = 'Food';
  final List<String> _categories = [
    'Food',
    'Transport',
    'Shopping',
    'Entertainment',
    'Health',
    'Bills',
    'Other',
  ];

  final Map<String, List<String>> _quickSuggestions = {
    'Food': [
      'Coffee ☕',
      'McDonald\'s 🍔',
      'Groceries 🛒',
      'Restaurant 🍽️',
      'Snacks 🍫',
      'Delivery 🛵',
    ],
    'Transport': [
      'Uber 🚗',
      'InDrive 🚙',
      'DiDi 🚘',
      'Metro 🚇',
      'Bus 🚌',
      'Gas ⛽',
      'Car Care 🔧',
    ],
    'Shopping': [
      'Clothes 👕',
      'Supermarket 🛍️',
      'Electronics 📱',
      'Home Decor 🏠',
      'Shoes 👟',
    ],
    'Entertainment': [
      'Cinema 🍿',
      'Netflix 📺',
      'Outing 🎡',
      'Games 🎮',
      'Cafe 🪑',
    ],
    'Health': ['Pharmacy 💊', 'Doctor 🩺', 'Gym 💪', 'Dentist 🦷'],
    'Bills': [
      'Mobile 📱',
      'Internet 🌐',
      'Electricity ⚡',
      'Water 💧',
      'Rent 🏠',
    ],
    'Other': ['Gift 🎁', 'Charity 🤝', 'Loan 💸', 'Lost 🛑'],
  };

  String _userName = '';
  String _userEmail = '';
  String? _userImage;
  double _budgetLimit = 0.0;

  @override
  void initState() {
    super.initState();
    _loadLocalData();
    _searchController.addListener(() {
      setState(() {});
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _loadLocalData() {
    setState(() {
      _userName = _myBox.get('user_name') ?? 'User';
      _userEmail = _auth.currentUser?.email ?? _myBox.get('user_email') ?? '';
      _userImage = _myBox.get('user_image');
      _budgetLimit = _myBox.get('budget_limit') ?? 0.0;
    });
  }

  ImageProvider? _getDrawerImage() {
    if (_userImage == null) return null;
    if (_userImage!.startsWith('http')) return NetworkImage(_userImage!);
    return MemoryImage(base64Decode(_userImage!));
  }

  void _saveTransaction({String? docId}) async {
    final enteredTitle = _titleController.text;
    final enteredAmount = double.tryParse(_amountController.text);

    if (enteredTitle.isEmpty || enteredAmount == null || enteredAmount <= 0)
      return;

    final user = _auth.currentUser;
    if (user != null) {
      if (docId == null) {
        await _firestore
            .collection('users')
            .doc(user.uid)
            .collection('transactions')
            .add({
              'title': enteredTitle,
              'amount': enteredAmount,
              'date': _selectedDate.toIso8601String(),
              'category': _selectedCategory,
              'createdAt': Timestamp.now(),
            });
      } else {
        await _firestore
            .collection('users')
            .doc(user.uid)
            .collection('transactions')
            .doc(docId)
            .update({
              'title': enteredTitle,
              'amount': enteredAmount,
              'date': _selectedDate.toIso8601String(),
              'category': _selectedCategory,
            });
      }
    }
    Navigator.of(context).pop();
    _clearInputs();
  }

  void _deleteTransaction(String docId) async {
    final user = _auth.currentUser;
    if (user != null) {
      await _firestore
          .collection('users')
          .doc(user.uid)
          .collection('transactions')
          .doc(docId)
          .delete();
    }
  }

  void _clearInputs() {
    _titleController.clear();
    _amountController.clear();
    _selectedDate = DateTime.now();
    _selectedCategory = 'Food';
  }

  Map<String, double> _calculateChartData(List<QueryDocumentSnapshot> docs) {
    Map<String, double> data = {};
    for (var doc in docs) {
      String cat = doc['category'] ?? 'Other';
      double amount = (doc['amount'] as num).toDouble();
      data[cat] = (data[cat] ?? 0) + amount;
    }
    return data;
  }

  IconData _getCategoryIcon(String categoryName) {
    switch (categoryName) {
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

  Color _getCategoryColor(String categoryName) {
    switch (categoryName) {
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

  // نافذة الإضافة والتعديل
  void _openTransactionOverlay({QueryDocumentSnapshot? existingDoc}) {
    if (existingDoc != null) {
      _titleController.text = existingDoc['title'];
      _amountController.text = existingDoc['amount'].toString();
      _selectedDate = DateTime.parse(existingDoc['date']);
      _selectedCategory = existingDoc['category'];
    } else {
      _clearInputs();
    }

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: const Color(0xFF1E1E1E),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(25)),
      ),
      builder: (ctx) {
        return StatefulBuilder(
          builder: (BuildContext context, StateSetter setModalState) {
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
                  Center(
                    child: Text(
                      existingDoc == null ? 'Add Expense' : 'Edit Expense',
                      style: const TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFFBB86FC),
                      ),
                    ),
                  ),
                  const SizedBox(height: 25),
                  const Text(
                    "Category",
                    style: TextStyle(color: Colors.grey, fontSize: 12),
                  ),
                  const SizedBox(height: 5),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 15),
                    decoration: BoxDecoration(
                      color: const Color(0xFF2C2C2C),
                      borderRadius: BorderRadius.circular(15),
                    ),
                    child: DropdownButtonHideUnderline(
                      child: DropdownButton<String>(
                        value: _selectedCategory,
                        isExpanded: true,
                        dropdownColor: const Color(0xFF2C2C2C),
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 16,
                        ),
                        items: _categories.map((String category) {
                          return DropdownMenuItem(
                            value: category,
                            child: Row(
                              children: [
                                Icon(
                                  _getCategoryIcon(category),
                                  color: _getCategoryColor(category),
                                  size: 20,
                                ),
                                const SizedBox(width: 10),
                                Text(category),
                              ],
                            ),
                          );
                        }).toList(),
                        onChanged: (newValue) =>
                            setModalState(() => _selectedCategory = newValue!),
                      ),
                    ),
                  ),
                  const SizedBox(height: 15),
                  SizedBox(
                    height: 40,
                    child: ListView(
                      scrollDirection: Axis.horizontal,
                      children: (_quickSuggestions[_selectedCategory] ?? [])
                          .map((suggestion) {
                            return Padding(
                              padding: const EdgeInsets.only(right: 10),
                              child: ActionChip(
                                label: Text(
                                  suggestion,
                                  style: const TextStyle(color: Colors.white),
                                ),
                                backgroundColor: const Color(0xFF333333),
                                side: BorderSide.none,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(20),
                                ),
                                onPressed: () {
                                  _titleController.text = suggestion.split(
                                    ' ',
                                  )[0];
                                },
                              ),
                            );
                          })
                          .toList(),
                    ),
                  ),
                  const SizedBox(height: 15),
                  Row(
                    children: [
                      Expanded(
                        flex: 2,
                        child: TextField(
                          controller: _titleController,
                          style: const TextStyle(color: Colors.white),
                          decoration: InputDecoration(
                            labelText: 'Description',
                            hintText: 'e.g. Starbucks',
                            hintStyle: TextStyle(color: Colors.grey[600]),
                            filled: true,
                            fillColor: const Color(0xFF2C2C2C),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(15),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        flex: 1,
                        child: TextField(
                          controller: _amountController,
                          keyboardType: TextInputType.number,
                          style: const TextStyle(color: Colors.white),
                          decoration: InputDecoration(
                            labelText: 'Amount',
                            filled: true,
                            fillColor: const Color(0xFF2C2C2C),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(15),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),
                  const Text(
                    "Date",
                    style: TextStyle(color: Colors.grey, fontSize: 12),
                  ),
                  const SizedBox(height: 10),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: _buildDateButton(
                          "Today",
                          DateTime.now(),
                          setModalState,
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: _buildDateButton(
                          "Yesterday",
                          DateTime.now().subtract(const Duration(days: 1)),
                          setModalState,
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: GestureDetector(
                          onTap: () async {
                            final picked = await showDatePicker(
                              context: context,
                              initialDate: _selectedDate,
                              firstDate: DateTime(2020),
                              lastDate: DateTime.now(),
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
                            if (picked != null)
                              setModalState(() => _selectedDate = picked);
                          },
                          child: Container(
                            height: 45,
                            alignment: Alignment.center,
                            decoration: BoxDecoration(
                              color: const Color(0xFF2C2C2C),
                              borderRadius: BorderRadius.circular(10),
                              border: Border.all(
                                color:
                                    _selectedDate.day != DateTime.now().day &&
                                        _selectedDate.day !=
                                            DateTime.now()
                                                .subtract(
                                                  const Duration(days: 1),
                                                )
                                                .day
                                    ? const Color(0xFFBB86FC)
                                    : Colors.transparent,
                              ),
                            ),
                            child: const Icon(
                              Icons.calendar_month,
                              color: Colors.white70,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                  Padding(
                    padding: const EdgeInsets.only(top: 8),
                    child: Text(
                      "Selected: ${_selectedDate.day}/${_selectedDate.month}/${_selectedDate.year}",
                      style: const TextStyle(
                        color: Color(0xFFBB86FC),
                        fontSize: 12,
                      ),
                    ),
                  ),
                  const SizedBox(height: 30),
                  SizedBox(
                    width: double.infinity,
                    height: 50,
                    child: ElevatedButton(
                      onPressed: () => _saveTransaction(docId: existingDoc?.id),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFFBB86FC),
                      ),
                      child: Text(
                        existingDoc == null
                            ? 'Add Transaction'
                            : 'Update Transaction',
                        style: const TextStyle(
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

  Widget _buildDateButton(
    String label,
    DateTime date,
    StateSetter setModalState,
  ) {
    bool isSelected =
        _selectedDate.day == date.day &&
        _selectedDate.month == date.month &&
        _selectedDate.year == date.year;
    return GestureDetector(
      onTap: () {
        setModalState(() => _selectedDate = date);
      },
      child: Container(
        height: 45,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: isSelected ? const Color(0xFFBB86FC) : const Color(0xFF2C2C2C),
          borderRadius: BorderRadius.circular(10),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: isSelected ? Colors.black : Colors.white,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
    );
  }

  Widget _buildQuickAction(
    IconData icon,
    String label,
    Color color,
    VoidCallback onTap,
  ) {
    return GestureDetector(
      onTap: onTap,
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(15),
            decoration: BoxDecoration(
              color: const Color(0xFF2C2C2C),
              shape: BoxShape.circle,
              boxShadow: [BoxShadow(color: Colors.black54, blurRadius: 5)],
            ),
            child: Icon(icon, color: color, size: 28),
          ),
          const SizedBox(height: 8),
          Text(
            label,
            style: const TextStyle(color: Colors.white70, fontSize: 12),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final user = _auth.currentUser;

    return StreamBuilder<QuerySnapshot>(
      stream: _firestore
          .collection('users')
          .doc(user?.uid)
          .collection('transactions')
          .orderBy('createdAt', descending: true)
          .snapshots(),
      builder: (context, snapshot) {
        final allDocs = snapshot.data?.docs ?? [];
        final totalSpent = allDocs.fold(
          0.0,
          (sum, doc) => sum + (doc['amount'] as num).toDouble(),
        );
        double budgetProgress = _budgetLimit == 0
            ? 0
            : (totalSpent / _budgetLimit);
        if (budgetProgress > 1) budgetProgress = 1;

        final filteredDocs = allDocs.where((doc) {
          final data = doc.data() as Map<String, dynamic>;
          final title = data['title'].toString().toLowerCase();
          final category = data['category'].toString();
          final searchQuery = _searchController.text.toLowerCase();
          bool matchesSearch = title.contains(searchQuery);
          bool matchesCategory =
              _filterCategory == 'All' || category == _filterCategory;
          return matchesSearch && matchesCategory;
        }).toList();

        return Scaffold(
          appBar: AppBar(
            title: const Text(
              'My Wallet',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            centerTitle: true,
            backgroundColor: Colors.transparent,
            elevation: 0,
            actions: [
              Builder(
                builder: (context) => IconButton(
                  icon: const Icon(Icons.menu, color: Colors.white),
                  onPressed: () => Scaffold.of(context).openEndDrawer(),
                ),
              ),
            ],
          ),
          endDrawer: Drawer(
            backgroundColor: const Color(0xFF1E1E1E),
            child: ListView(
              padding: EdgeInsets.zero,
              children: [
                UserAccountsDrawerHeader(
                  decoration: const BoxDecoration(
                    gradient: LinearGradient(
                      colors: [Color(0xFF6200EA), Color(0xFFB00020)],
                    ),
                  ),
                  accountName: Text(
                    _userName,
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 18,
                    ),
                  ),
                  accountEmail: Text(
                    _userEmail,
                    style: const TextStyle(color: Colors.white70),
                  ),
                  currentAccountPicture: CircleAvatar(
                    backgroundColor: Colors.white,
                    backgroundImage: _getDrawerImage(),
                    child: _userImage == null
                        ? const Icon(
                            Icons.person,
                            size: 40,
                            color: Color(0xFF6200EA),
                          )
                        : null,
                  ),
                ),
                ListTile(
                  leading: const Icon(
                    Icons.dashboard,
                    color: Color(0xFFBB86FC),
                  ),
                  title: const Text(
                    'Dashboard',
                    style: TextStyle(color: Colors.white),
                  ),
                  onTap: () => Navigator.pop(context),
                ),

                // --- الزر الجديد للتحليلات ---
                ListTile(
                  leading: const Icon(
                    Icons.bar_chart,
                    color: Colors.pinkAccent,
                  ),
                  title: const Text(
                    'Weekly Analytics 📊',
                    style: TextStyle(color: Colors.white),
                  ),
                  onTap: () {
                    Navigator.pop(context);
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => const StatsScreen(),
                      ),
                    );
                  },
                ),

                // ---------------------------
                ListTile(
                  leading: const Icon(
                    Icons.account_balance_wallet,
                    color: Color(0xFF03DAC6),
                  ),
                  title: const Text(
                    'My Budget Plan',
                    style: TextStyle(color: Colors.white),
                  ),
                  onTap: () {
                    Navigator.pop(context);
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) =>
                            BudgetScreen(totalSpent: totalSpent),
                      ),
                    );
                  },
                ),
                ListTile(
                  leading: const Icon(
                    Icons.credit_card,
                    color: Colors.blueAccent,
                  ),
                  title: const Text(
                    'My Cards / Wallet',
                    style: TextStyle(color: Colors.white),
                  ),
                  onTap: () {
                    Navigator.pop(context);
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => const CardsScreen(),
                      ),
                    );
                  },
                ),
                ListTile(
                  leading: const Icon(
                    Icons.subscriptions,
                    color: Colors.purpleAccent,
                  ),
                  title: const Text(
                    'My Subscriptions',
                    style: TextStyle(color: Colors.white),
                  ),
                  onTap: () {
                    Navigator.pop(context);
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => const SubscriptionsScreen(),
                      ),
                    );
                  },
                ),
                ListTile(
                  leading: const Icon(Icons.flag, color: Colors.greenAccent),
                  title: const Text(
                    'Saving Goals 🎯',
                    style: TextStyle(color: Colors.white),
                  ),
                  onTap: () {
                    Navigator.pop(context);
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => const GoalsScreen(),
                      ),
                    );
                  },
                ),
                ListTile(
                  leading: const Icon(
                    Icons.currency_exchange,
                    color: Colors.amberAccent,
                  ),
                  title: const Text(
                    'Currency Converter',
                    style: TextStyle(color: Colors.white),
                  ),
                  onTap: () {
                    Navigator.pop(context);
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => const ConverterScreen(),
                      ),
                    );
                  },
                ),
                ListTile(
                  leading: const Icon(
                    Icons.balance,
                    color: Colors.yellowAccent,
                  ),
                  title: const Text(
                    'Gold & Metals',
                    style: TextStyle(color: Colors.white),
                  ),
                  onTap: () {
                    Navigator.pop(context);
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => const GoldScreen(),
                      ),
                    );
                  },
                ),
                ListTile(
                  leading: const Icon(
                    Icons.settings,
                    color: Colors.orangeAccent,
                  ),
                  title: const Text(
                    'Profile Settings',
                    style: TextStyle(color: Colors.white),
                  ),
                  onTap: () {
                    Navigator.pop(context);
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => const ProfileScreen(),
                      ),
                    ).then((_) => _loadLocalData());
                  },
                ),
                const Divider(color: Colors.grey),
                ListTile(
                  leading: const Icon(Icons.logout, color: Colors.grey),
                  title: const Text(
                    'Logout',
                    style: TextStyle(color: Colors.white),
                  ),
                  onTap: () async {
                    await _auth.signOut();
                    Navigator.pushReplacement(
                      context,
                      MaterialPageRoute(
                        builder: (context) => const LoginScreen(),
                      ),
                    );
                  },
                ),
              ],
            ),
          ),

          body: snapshot.connectionState == ConnectionState.waiting
              ? const Center(
                  child: CircularProgressIndicator(color: Color(0xFFBB86FC)),
                )
              : CustomScrollView(
                  slivers: [
                    SliverToBoxAdapter(
                      child: Column(
                        children: [
                          if (allDocs.isEmpty && totalSpent == 0)
                            Container(
                              width: double.infinity,
                              margin: const EdgeInsets.all(20),
                              padding: const EdgeInsets.all(25),
                              decoration: BoxDecoration(
                                gradient: const LinearGradient(
                                  colors: [
                                    Color(0xFF6200EA),
                                    Color(0xFFB00020),
                                  ],
                                  begin: Alignment.topLeft,
                                  end: Alignment.bottomRight,
                                ),
                                borderRadius: BorderRadius.circular(25),
                              ),
                              child: Column(
                                children: [
                                  const Text(
                                    'Total Spent',
                                    style: TextStyle(color: Colors.white70),
                                  ),
                                  Text(
                                    '\$${totalSpent.toStringAsFixed(2)}',
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontSize: 30,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ],
                              ),
                            ),

                          if (allDocs.isNotEmpty || totalSpent > 0)
                            Padding(
                              padding: const EdgeInsets.all(10.0),
                              child: ChartWidget(
                                dataMap: _calculateChartData(allDocs),
                              ),
                            ),

                          if (allDocs.isNotEmpty)
                            Text(
                              'Total: \$${totalSpent.toStringAsFixed(2)}',
                              style: const TextStyle(
                                fontSize: 20,
                                fontWeight: FontWeight.bold,
                                color: Colors.white,
                              ),
                            ),

                          const SizedBox(height: 15),

                          Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 20),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.spaceAround,
                              children: [
                                _buildQuickAction(
                                  Icons.flag,
                                  'Goals',
                                  Colors.greenAccent,
                                  () => Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (context) => const GoalsScreen(),
                                    ),
                                  ),
                                ),
                                _buildQuickAction(
                                  Icons.credit_card,
                                  'Cards',
                                  Colors.blueAccent,
                                  () => Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (context) => const CardsScreen(),
                                    ),
                                  ),
                                ),
                                _buildQuickAction(
                                  Icons.balance,
                                  'Gold',
                                  Colors.yellowAccent,
                                  () => Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (context) => const GoldScreen(),
                                    ),
                                  ),
                                ),
                                _buildQuickAction(
                                  Icons.currency_exchange,
                                  'Convert',
                                  Colors.amberAccent,
                                  () => Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (context) =>
                                          const ConverterScreen(),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),

                          const SizedBox(height: 15),

                          Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 20),
                            child: TextField(
                              controller: _searchController,
                              style: const TextStyle(color: Colors.white),
                              decoration: InputDecoration(
                                hintText: 'Search expenses...',
                                hintStyle: TextStyle(color: Colors.grey[600]),
                                prefixIcon: const Icon(
                                  Icons.search,
                                  color: Color(0xFFBB86FC),
                                ),
                                filled: true,
                                fillColor: const Color(0xFF2C2C2C),
                                contentPadding: const EdgeInsets.symmetric(
                                  vertical: 0,
                                  horizontal: 20,
                                ),
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(30),
                                  borderSide: BorderSide.none,
                                ),
                              ),
                            ),
                          ),

                          const SizedBox(height: 10),

                          SizedBox(
                            height: 40,
                            child: ListView(
                              scrollDirection: Axis.horizontal,
                              padding: const EdgeInsets.symmetric(
                                horizontal: 20,
                              ),
                              children: ['All', ..._categories].map((cat) {
                                final isSelected = _filterCategory == cat;
                                return Padding(
                                  padding: const EdgeInsets.only(right: 8),
                                  child: ChoiceChip(
                                    label: Text(cat),
                                    selected: isSelected,
                                    onSelected: (selected) {
                                      setState(
                                        () => _filterCategory = selected
                                            ? cat
                                            : 'All',
                                      );
                                    },
                                    selectedColor: const Color(0xFFBB86FC),
                                    backgroundColor: const Color(0xFF2C2C2C),
                                    labelStyle: TextStyle(
                                      color: isSelected
                                          ? Colors.black
                                          : Colors.white,
                                    ),
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(20),
                                      side: BorderSide.none,
                                    ),
                                  ),
                                );
                              }).toList(),
                            ),
                          ),

                          const SizedBox(height: 10),

                          if (_budgetLimit > 0)
                            Padding(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 25,
                                vertical: 5,
                              ),
                              child: Column(
                                children: [
                                  Row(
                                    mainAxisAlignment:
                                        MainAxisAlignment.spaceBetween,
                                    children: [
                                      const Text(
                                        "Budget Status",
                                        style: TextStyle(
                                          color: Colors.grey,
                                          fontSize: 12,
                                        ),
                                      ),
                                      Text(
                                        "${(budgetProgress * 100).toStringAsFixed(0)}%",
                                        style: TextStyle(
                                          color: budgetProgress > 0.8
                                              ? Colors.red
                                              : Colors.green,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 5),
                                  LinearProgressIndicator(
                                    value: budgetProgress,
                                    minHeight: 6,
                                    backgroundColor: Colors.white10,
                                    color: budgetProgress > 0.8
                                        ? Colors.red
                                        : Colors.green,
                                    borderRadius: BorderRadius.circular(5),
                                  ),
                                ],
                              ),
                            ),

                          Padding(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 25,
                              vertical: 10,
                            ),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text(
                                  _searchController.text.isNotEmpty
                                      ? 'Search Results'
                                      : 'Recent',
                                  style: const TextStyle(
                                    fontSize: 18,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                const Icon(Icons.sort, color: Colors.grey),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),

                    filteredDocs.isEmpty
                        ? SliverToBoxAdapter(
                            child: Container(
                              height: 200,
                              alignment: Alignment.center,
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(
                                    allDocs.isEmpty
                                        ? Icons.cloud_upload
                                        : Icons.search_off,
                                    size: 80,
                                    color: Colors.grey,
                                  ),
                                  const SizedBox(height: 10),
                                  Text(
                                    allDocs.isEmpty
                                        ? 'Start adding expenses!'
                                        : 'No results found.',
                                    style: const TextStyle(color: Colors.grey),
                                  ),
                                ],
                              ),
                            ),
                          )
                        : SliverList(
                            delegate: SliverChildBuilderDelegate((
                              context,
                              index,
                            ) {
                              final doc = filteredDocs[index];
                              final date = DateTime.parse(doc['date']);
                              final category = doc['category'] ?? 'Other';
                              return Card(
                                color: const Color(0xFF1E1E1E),
                                margin: const EdgeInsets.symmetric(
                                  vertical: 6,
                                  horizontal: 20,
                                ),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(15),
                                ),
                                elevation: 2,
                                child: ListTile(
                                  leading: CircleAvatar(
                                    radius: 25,
                                    backgroundColor: _getCategoryColor(
                                      category,
                                    ).withOpacity(0.2),
                                    child: Icon(
                                      _getCategoryIcon(category),
                                      color: _getCategoryColor(category),
                                    ),
                                  ),
                                  title: Text(
                                    doc['title'],
                                    style: const TextStyle(
                                      fontWeight: FontWeight.bold,
                                      fontSize: 16,
                                    ),
                                  ),
                                  subtitle: Text(
                                    '${date.day}/${date.month} • $category',
                                    style: const TextStyle(
                                      color: Colors.grey,
                                      fontSize: 12,
                                    ),
                                  ),
                                  trailing: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Text(
                                        '\$${(doc['amount'] as num).toStringAsFixed(0)}',
                                        style: const TextStyle(
                                          fontWeight: FontWeight.bold,
                                          fontSize: 16,
                                          color: Colors.white,
                                        ),
                                      ),
                                      IconButton(
                                        icon: const Icon(
                                          Icons.edit,
                                          size: 20,
                                          color: Colors.blueAccent,
                                        ),
                                        onPressed: () =>
                                            _openTransactionOverlay(
                                              existingDoc: doc,
                                            ),
                                      ),
                                      IconButton(
                                        icon: const Icon(
                                          Icons.delete_outline,
                                          size: 20,
                                          color: Colors.redAccent,
                                        ),
                                        onPressed: () =>
                                            _deleteTransaction(doc.id),
                                      ),
                                    ],
                                  ),
                                ),
                              );
                            }, childCount: filteredDocs.length),
                          ),

                    const SliverToBoxAdapter(child: SizedBox(height: 80)),
                  ],
                ),

          floatingActionButton: FloatingActionButton(
            onPressed: () => _openTransactionOverlay(),
            backgroundColor: const Color(0xFFBB86FC),
            child: const Icon(Icons.add, color: Colors.black),
          ),
        );
      },
    );
  }
}
