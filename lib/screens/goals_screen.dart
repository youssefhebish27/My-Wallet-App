import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';

class GoalsScreen extends StatefulWidget {
  const GoalsScreen({super.key});

  @override
  State<GoalsScreen> createState() => _GoalsScreenState();
}

class _GoalsScreenState extends State<GoalsScreen> {
  final _myBox = Hive.box('expense_database');
  List<Map<String, dynamic>> _goals = [];

  final _titleController = TextEditingController();
  final _targetController = TextEditingController();
  final _savedController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _loadGoals();
  }

  void _loadGoals() {
    final data = _myBox.get('saving_goals');
    if (data != null) {
      setState(() {
        _goals = List<Map<String, dynamic>>.from(
          (data as List).map((e) => Map<String, dynamic>.from(e)),
        );
      });
    }
  }

  void _saveGoals() {
    _myBox.put('saving_goals', _goals);
  }

  void _addGoal() {
    if (_titleController.text.isEmpty || _targetController.text.isEmpty) return;
    setState(() {
      _goals.add({
        'title': _titleController.text,
        'target': double.tryParse(_targetController.text) ?? 0.0,
        'saved': 0.0,
      });
    });
    _saveGoals();
    Navigator.pop(context);
    _titleController.clear();
    _targetController.clear();
  }

  void _addMoney(int index) {
    if (_savedController.text.isEmpty) return;
    double amountToAdd = double.tryParse(_savedController.text) ?? 0.0;

    setState(() {
      double currentSaved = (_goals[index]['saved'] as num).toDouble();
      _goals[index]['saved'] = currentSaved + amountToAdd;
    });
    _saveGoals();
    Navigator.pop(context);
    _savedController.clear();
  }

  void _deleteGoal(int index) {
    setState(() {
      _goals.removeAt(index);
    });
    _saveGoals();
  }

  void _openAddMoneyDialog(int index) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: const Color(0xFF2C2C2C),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text(
          'Add Savings 💰',
          style: TextStyle(color: Colors.white),
        ),
        content: TextField(
          controller: _savedController,
          keyboardType: TextInputType.number,
          style: const TextStyle(color: Colors.white),
          decoration: InputDecoration(
            labelText: 'Amount Saved',
            prefixIcon: const Icon(
              Icons.arrow_upward,
              color: Colors.greenAccent,
            ),
            filled: true,
            fillColor: const Color(0xFF1E1E1E),
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(15)),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel', style: TextStyle(color: Colors.grey)),
          ),
          ElevatedButton(
            onPressed: () => _addMoney(index),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF03DAC6),
              foregroundColor: Colors.black,
            ),
            child: const Text(
              'Deposit',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
          ),
        ],
      ),
    );
  }

  void _openNewGoalDialog() {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: const Color(0xFF2C2C2C),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text('New Dream ✨', style: TextStyle(color: Colors.white)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: _titleController,
              style: const TextStyle(color: Colors.white),
              decoration: InputDecoration(
                labelText: 'Goal Name (e.g. New Car)',
                prefixIcon: const Icon(Icons.flag, color: Color(0xFFBB86FC)),
                filled: true,
                fillColor: const Color(0xFF1E1E1E),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(15),
                ),
              ),
            ),
            const SizedBox(height: 15),
            TextField(
              controller: _targetController,
              keyboardType: TextInputType.number,
              style: const TextStyle(color: Colors.white),
              decoration: InputDecoration(
                labelText: 'Target Amount',
                prefixIcon: const Icon(
                  Icons.track_changes,
                  color: Color(0xFFBB86FC),
                ),
                filled: true,
                fillColor: const Color(0xFF1E1E1E),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(15),
                ),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel', style: TextStyle(color: Colors.grey)),
          ),
          ElevatedButton(
            onPressed: _addGoal,
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFBB86FC),
              foregroundColor: Colors.black,
            ),
            child: const Text(
              'Set Goal',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'My Dreams 🎯',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      body: _goals.isEmpty
          ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.rocket_launch,
                    size: 80,
                    color: Colors.grey.withOpacity(0.5),
                  ),
                  const SizedBox(height: 20),
                  const Text(
                    'No goals yet. Start dreaming!',
                    style: TextStyle(color: Colors.grey, fontSize: 16),
                  ),
                ],
              ),
            )
          : ListView.builder(
              padding: const EdgeInsets.all(20),
              itemCount: _goals.length,
              itemBuilder: (ctx, index) {
                final goal = _goals[index];
                double saved = (goal['saved'] as num).toDouble();
                double target = (goal['target'] as num).toDouble();
                double progress = target == 0 ? 0 : (saved / target);
                bool isCompleted = progress >= 1.0;
                if (progress > 1) progress = 1;

                return Container(
                  margin: const EdgeInsets.only(bottom: 25),
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    // خلفية متدرجة جميلة
                    gradient: LinearGradient(
                      colors: isCompleted
                          ? [
                              const Color(0xFF00C853),
                              const Color(0xFF64DD17),
                            ] // أخضر عند الاكتمال
                          : [
                              const Color(0xFF4A148C),
                              const Color(0xFF7B1FA2),
                            ], // بنفسجي للعادي
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.circular(25),
                    boxShadow: [
                      BoxShadow(
                        color: isCompleted
                            ? Colors.green.withOpacity(0.4)
                            : Colors.purple.withOpacity(0.4),
                        blurRadius: 10,
                        offset: const Offset(0, 5),
                      ),
                    ],
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Expanded(
                            child: Text(
                              goal['title'],
                              style: const TextStyle(
                                fontSize: 22,
                                fontWeight: FontWeight.bold,
                                color: Colors.white,
                              ),
                            ),
                          ),
                          // زر الحذف
                          GestureDetector(
                            onTap: () => _deleteGoal(index),
                            child: Container(
                              padding: const EdgeInsets.all(8),
                              decoration: BoxDecoration(
                                color: Colors.white24,
                                borderRadius: BorderRadius.circular(10),
                              ),
                              child: const Icon(
                                Icons.delete_outline,
                                color: Colors.white,
                                size: 20,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 20),

                      // شريط التقدم المخصص (Custom Progress Bar)
                      Stack(
                        children: [
                          Container(
                            height: 12,
                            width: double.infinity,
                            decoration: BoxDecoration(
                              color: Colors.black26,
                              borderRadius: BorderRadius.circular(10),
                            ),
                          ),
                          // انيميشن للشريط
                          TweenAnimationBuilder<double>(
                            duration: const Duration(seconds: 1),
                            curve: Curves.easeOutExpo,
                            tween: Tween<double>(begin: 0, end: progress),
                            builder: (context, value, _) => Container(
                              height: 12,
                              width:
                                  MediaQuery.of(context).size.width *
                                  0.8 *
                                  value, // العرض بناءً على التقدم
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(10),
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.white.withOpacity(0.5),
                                    blurRadius: 5,
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ],
                      ),

                      const SizedBox(height: 15),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            "\$${saved.toStringAsFixed(0)} / \$${target.toStringAsFixed(0)}",
                            style: const TextStyle(
                              color: Colors.white70,
                              fontSize: 16,
                            ),
                          ),
                          Text(
                            "${(progress * 100).toStringAsFixed(0)}%",
                            style: const TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                              fontSize: 18,
                            ),
                          ),
                        ],
                      ),

                      const SizedBox(height: 20),

                      // زر الإضافة أو رسالة التهنئة
                      if (!isCompleted)
                        SizedBox(
                          width: double.infinity,
                          child: ElevatedButton(
                            onPressed: () => _openAddMoneyDialog(index),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.white,
                              foregroundColor: Colors.purple,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(15),
                              ),
                              elevation: 0,
                            ),
                            child: const Text(
                              "+ Add Money",
                              style: TextStyle(fontWeight: FontWeight.bold),
                            ),
                          ),
                        )
                      else
                        Center(
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 15,
                              vertical: 8,
                            ),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: const [
                                Icon(
                                  Icons.check_circle,
                                  color: Colors.green,
                                  size: 20,
                                ),
                                SizedBox(width: 8),
                                Text(
                                  "GOAL COMPLETED! 🎉",
                                  style: TextStyle(
                                    color: Colors.green,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                    ],
                  ),
                );
              },
            ),
      floatingActionButton: FloatingActionButton(
        onPressed: _openNewGoalDialog,
        backgroundColor: const Color(0xFF03DAC6),
        child: const Icon(Icons.add, color: Colors.black),
      ),
    );
  }
}
