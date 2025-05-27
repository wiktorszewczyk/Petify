import 'package:flutter/material.dart';
import 'package:flutter_stripe/flutter_stripe.dart';
import 'package:google_fonts/google_fonts.dart';
import '../styles/colors.dart';

class PaymentView extends StatefulWidget {
  final String clientSecret;
  final double amount;
  final String currency;
  final String shelterId;
  final String shelterName;
  final String? petId;
  final String? petName;

  const PaymentView({
    Key? key,
    required this.clientSecret,
    required this.amount,
    required this.currency,
    required this.shelterId,
    required this.shelterName,
    this.petId,
    this.petName
}) : super(key: key);

  @override
  State<PaymentView> createState() => _PaymentViewState();
}

class _PaymentViewState extends State<PaymentView> {
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _initPaymentSheet();
  }

  Future<void> _initPaymentSheet() async {
    try {
      await Stripe.instance.initPaymentSheet(
        paymentSheetParameters: SetupPaymentSheetParameters(
          paymentIntentClientSecret: widget.clientSecret,
          merchantDisplayName: 'Petify',
        ),
      );
      setState(() => _loading = false);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Błąd inicjalizacji płatności: $e')),
        );
        Navigator.of(context).pop();
      }
    }
  }

  Future<void> _presentPaymentSheet() async {
    try {
      await Stripe.instance.presentPaymentSheet();
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Płatność zakończona sukcesem!'),
          backgroundColor: Colors.green,
        ),
      );
      Navigator.of(context).pop();
    } on StripeException catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Płatność przerwana: ${e.error.localizedMessage}')),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Nieoczekiwany błąd: $e')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final titleName = widget.petName ?? widget.shelterName;
    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Płatność za wsparcie $titleName',
          style: GoogleFonts.poppins(),
        ),
        backgroundColor: AppColors.primaryColor,
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              'Do zapłaty:',
              style: GoogleFonts.poppins(fontSize: 18),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(
              '${widget.amount.toStringAsFixed(2)} ${widget.currency.toUpperCase()}',
              style: GoogleFonts.poppins(
                fontSize: 32,
                fontWeight: FontWeight.bold,
              ),
              textAlign: TextAlign.center,
            ),
            const Spacer(),
            ElevatedButton(
              onPressed: _presentPaymentSheet,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primaryColor,
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: Text(
                'Zapłać teraz',
                style: GoogleFonts.poppins(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}