import 'package:flutter/material.dart';

class ConverterScreen extends StatefulWidget {
  const ConverterScreen({super.key});

  @override
  State<ConverterScreen> createState() => _ConverterScreenState();
}

class _ConverterScreenState extends State<ConverterScreen> {
  final _amountController = TextEditingController();
  double _result = 0.0;

  // --- تحديث الأسعار (اليوم) ---
  double usdToEgp = 47.31;
  double eurToEgp = 55.57;
  double eurToUsd = 1.17; // تقريبي (55.57 / 47.31)

  String _fromCurrency = 'USD';
  String _toCurrency = 'EGP';

  final List<String> _currencies = ['USD', 'EGP', 'EUR'];

  String _getFlag(String code) {
    if (code == 'USD') return '🇺🇸';
    if (code == 'EGP') return '🇪🇬';
    if (code == 'EUR') return '🇪🇺';
    return '🏳️';
  }

  void _convert() {
    if (_amountController.text.isEmpty) {
      setState(() => _result = 0.0);
      return;
    }
    double amount = double.tryParse(_amountController.text) ?? 0.0;
    double rate = 1.0;

    // منطق التحويل
    if (_fromCurrency == 'USD' && _toCurrency == 'EGP')
      rate = usdToEgp;
    else if (_fromCurrency == 'EGP' && _toCurrency == 'USD')
      rate = 1 / usdToEgp;
    else if (_fromCurrency == 'EUR' && _toCurrency == 'EGP')
      rate = eurToEgp;
    else if (_fromCurrency == 'EGP' && _toCurrency == 'EUR')
      rate = 1 / eurToEgp;
    else if (_fromCurrency == 'EUR' && _toCurrency == 'USD')
      rate = eurToUsd;
    else if (_fromCurrency == 'USD' && _toCurrency == 'EUR')
      rate = 1 / eurToUsd;
    else if (_fromCurrency == _toCurrency)
      rate = 1.0;

    setState(() {
      _result = amount * rate;
    });
  }

  void _swapCurrencies() {
    setState(() {
      String temp = _fromCurrency;
      _fromCurrency = _toCurrency;
      _toCurrency = temp;
      _convert();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      resizeToAvoidBottomInset: false,
      appBar: AppBar(
        title: const Text('Converter 💱'),
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      body: Padding(
        padding: const EdgeInsets.all(25),
        child: Column(
          children: [
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(vertical: 30, horizontal: 20),
              decoration: BoxDecoration(
                color: const Color(0xFF2C2C2C),
                borderRadius: BorderRadius.circular(25),
                border: Border.all(color: Colors.white10),
              ),
              child: Column(
                children: [
                  const Text(
                    "Converted Amount",
                    style: TextStyle(color: Colors.grey, fontSize: 14),
                  ),
                  const SizedBox(height: 10),
                  FittedBox(
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          _result == 0 ? "0.00" : _result.toStringAsFixed(2),
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 45,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(width: 10),
                        Text(
                          _toCurrency,
                          style: const TextStyle(
                            color: Color(0xFF03DAC6),
                            fontSize: 20,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 40),

            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                _buildCurrencyDropdown(_fromCurrency, (val) {
                  setState(() {
                    _fromCurrency = val!;
                    _convert();
                  });
                }),
                IconButton(
                  onPressed: _swapCurrencies,
                  icon: Container(
                    padding: const EdgeInsets.all(8),
                    decoration: const BoxDecoration(
                      color: Color(0xFFBB86FC),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(Icons.swap_horiz, color: Colors.black),
                  ),
                ),
                _buildCurrencyDropdown(_toCurrency, (val) {
                  setState(() {
                    _toCurrency = val!;
                    _convert();
                  });
                }),
              ],
            ),

            const SizedBox(height: 40),

            TextField(
              controller: _amountController,
              keyboardType: TextInputType.number,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 24,
                fontWeight: FontWeight.bold,
              ),
              textAlign: TextAlign.center,
              decoration: InputDecoration(
                hintText: '0',
                hintStyle: TextStyle(color: Colors.grey[700]),
                filled: true,
                fillColor: const Color(0xFF1E1E1E),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(20),
                  borderSide: BorderSide.none,
                ),
                prefixIcon: const Icon(
                  Icons.attach_money,
                  color: Colors.transparent,
                ),
                suffixIcon: const Icon(Icons.edit, color: Colors.grey),
              ),
              onChanged: (val) => _convert(),
            ),

            const Spacer(),

            Container(
              padding: const EdgeInsets.all(15),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.05),
                borderRadius: BorderRadius.circular(15),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  Text(
                    "1 USD ≈ $usdToEgp EGP",
                    style: const TextStyle(color: Colors.white54, fontSize: 12),
                  ),
                  Text(
                    "1 EUR ≈ $eurToEgp EGP",
                    style: const TextStyle(color: Colors.white54, fontSize: 12),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCurrencyDropdown(
    String currentValue,
    Function(String?) onChanged,
  ) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
      decoration: BoxDecoration(
        color: const Color(0xFF1E1E1E),
        borderRadius: BorderRadius.circular(15),
        border: Border.all(color: Colors.white10),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          value: currentValue,
          dropdownColor: const Color(0xFF2C2C2C),
          icon: const Icon(Icons.arrow_drop_down, color: Colors.white70),
          items: _currencies.map((String value) {
            return DropdownMenuItem<String>(
              value: value,
              child: Row(
                children: [
                  Text(_getFlag(value), style: const TextStyle(fontSize: 20)),
                  const SizedBox(width: 8),
                  Text(
                    value,
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            );
          }).toList(),
          onChanged: onChanged,
        ),
      ),
    );
  }
}
