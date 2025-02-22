import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../state/payment_provider.dart';
import '../core/configs/theme/app_colors.dart';
import '../core/widgets/app_button.dart';

class PaymentScreen extends StatefulWidget {
  const PaymentScreen({super.key});

  @override
  State<PaymentScreen> createState() => _PaymentScreenState();
}

class _PaymentScreenState extends State<PaymentScreen> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController fundController = TextEditingController();

  Future<void> _handleAddFunds() async {
    if (_formKey.currentState!.validate()) {
      final amount = double.parse(fundController.text);
      final paymentProvider = Provider.of<PaymentProvider>(context, listen: false);
      await paymentProvider.addFunds(amount);
      if (mounted && paymentProvider.error == null) {
        fundController.clear();
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      onWillPop: () async {
        // Go back to the Home screen if possible, otherwise pushReplacement
        if (Navigator.of(context).canPop()) {
          Navigator.of(context).pop();
        } else {
          Navigator.of(context).pushReplacementNamed('/home');
        }
        return false;
      },
      child: Scaffold(
        appBar: AppBar(
          leading: IconButton(
            icon: const Icon(Icons.arrow_back),
            onPressed: () {
              if (Navigator.of(context).canPop()) {
                Navigator.of(context).pop();
              } else {
                Navigator.of(context).pushReplacementNamed('/home');
              }
            },
          ),
          title: const Text('Wallet & Payments'),
        ),
        body: Consumer<PaymentProvider>(
          builder: (context, paymentProvider, child) {
            if (paymentProvider.isLoading) {
              return const Center(child: CircularProgressIndicator());
            }
            if (paymentProvider.error != null) {
              return Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text('Error: ${paymentProvider.error}', style: const TextStyle(color: Colors.red)),
                    ElevatedButton(
                      onPressed: () => paymentProvider.fetchWalletBalance(),
                      child: const Text('Retry'),
                    ),
                  ],
                ),
              );
            }
            return RawScrollbar(
              thumbVisibility: true,
              thickness: 6,
              radius: const Radius.circular(3),
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(16.0),
                child: Form(
                  key: _formKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Card(
                        child: Padding(
                          padding: const EdgeInsets.all(16.0),
                          child: Column(
                            children: [
                              const Text(
                                'Current Balance',
                                style: TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
                              ),
                              const SizedBox(height: 8),
                              Text(
                                '\$${paymentProvider.walletBalance.toStringAsFixed(2)}',
                                style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                                  color: AppColors.primary,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(height: 24),
                      TextFormField(
                        controller: fundController,
                        decoration: const InputDecoration(
                          labelText: 'Amount to Add',
                          prefixIcon: Icon(Icons.attach_money),
                          border: OutlineInputBorder(),
                        ),
                        keyboardType: TextInputType.numberWithOptions(decimal: true),
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'Please enter an amount';
                          }
                          final amount = double.tryParse(value);
                          if (amount == null) {
                            return 'Please enter a valid number';
                          }
                          if (amount <= 0) {
                            return 'Amount must be greater than 0';
                          }
                          if (amount > 1000) {
                            return 'Amount cannot exceed \$1,000';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 16),
                      AppButton(
                        text: 'Add Funds',
                        onPressed: paymentProvider.isProcessing ? () {} : _handleAddFunds,
                        isLoading: paymentProvider.isProcessing,
                      ),
                      const SizedBox(height: 32),
                      const Text(
                        'Transaction History',
                        style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 16),
                      if (paymentProvider.transactions.isEmpty)
                        const Center(
                          child: Padding(
                            padding: EdgeInsets.symmetric(vertical: 32.0),
                            child: Text(
                              'No transactions yet',
                              style: TextStyle(color: AppColors.textSecondary, fontSize: 16),
                            ),
                          ),
                        )
                      else
                        ...paymentProvider.transactions.map((transaction) => Card(
                              margin: const EdgeInsets.only(bottom: 8),
                              child: ListTile(
                                leading: Icon(
                                  transaction['type'] == 'Add'
                                      ? Icons.add_circle_outline
                                      : Icons.remove_circle_outline,
                                  color: transaction['type'] == 'Add' ? Colors.green : Colors.red,
                                ),
                                title: Text(
                                  transaction['type'] == 'Add' ? 'Added Funds' : 'Payment for Trip',
                                ),
                                subtitle: Text(transaction['date'] ?? ''),
                                trailing: Text(
                                  '${transaction['type'] == 'Add' ? '+' : '-'}\$${(transaction['amount'] as num).toStringAsFixed(2)}',
                                  style: TextStyle(
                                    color: transaction['type'] == 'Add' ? Colors.green : Colors.red,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                            )).toList(),
                    ],
                  ),
                ),
              ),
            );
          },
        ),
      ),
    );
  }

  @override
  void dispose() {
    fundController.dispose();
    super.dispose();
  }
}
