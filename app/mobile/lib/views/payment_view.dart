import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:url_launcher/url_launcher.dart';
import 'dart:async';
import 'dart:developer' as dev;
import '../models/donation.dart';
import '../services/payment_service.dart';
import '../styles/colors.dart';

class PaymentView extends StatefulWidget {
  final int shelterId;
  final int? petId;
  final int? fundraiserId;
  final double? initialAmount;
  final String? title;
  final String? description;

  const PaymentView({
    Key? key,
    required this.shelterId,
    this.petId,
    this.fundraiserId,
    this.initialAmount,
    this.title,
    this.description,
  }) : super(key: key);

  @override
  State<PaymentView> createState() => _PaymentViewState();
}

class _PaymentViewState extends State<PaymentView> {
  final PaymentService _paymentService = PaymentService();
  final TextEditingController _amountController = TextEditingController();
  final TextEditingController _messageController = TextEditingController();
  final TextEditingController _blikController = TextEditingController();

  bool _isLoading = false;
  bool _isProcessingPayment = false;
  PaymentOptionsResponse? _paymentOptions;
  PaymentProviderOption? _selectedProvider;
  PaymentMethodOption? _selectedMethod;
  bool _anonymous = false;

  // Predefined amounts
  final List<double> _quickAmounts = [5, 10, 20, 50, 100];

  @override
  void initState() {
    super.initState();
    if (widget.initialAmount != null) {
      _amountController.text = widget.initialAmount!.toStringAsFixed(0);
    }
  }

  @override
  void dispose() {
    _amountController.dispose();
    _messageController.dispose();
    _blikController.dispose();
    super.dispose();
  }

  Future<void> _createDonationIntent() async {
    final amount = double.tryParse(_amountController.text);
    if (amount == null || amount <= 0) {
      _showError('Wprowadź prawidłową kwotę');
      return;
    }

    setState(() => _isLoading = true);

    try {
      final intent = await _paymentService.createDonationIntent(
        shelterId: widget.shelterId,
        petId: widget.petId,
        fundraiserId: widget.fundraiserId,
        donationType: 'MONEY',
        amount: amount,
        message: _messageController.text.isNotEmpty ? _messageController.text : null,
        anonymous: _anonymous,
      );

      setState(() {
        _paymentOptions = intent;
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
      _showError('Nie udało się utworzyć donacji: $e');
    }
  }

  Future<void> _initializePayment() async {
    if (_selectedProvider == null || _paymentOptions == null) {
      _showError('Wybierz dostawcę płatności');
      return;
    }

    setState(() => _isProcessingPayment = true);

    try {
      final paymentResponse = await _paymentService.initializePayment(
        donationId: _paymentOptions!.donationId,
        sessionToken: _paymentOptions!.sessionToken,
        provider: _selectedProvider!.provider,
      );

      // Handle different payment flows - prefer web checkout over native SDK
      if (paymentResponse.payment.checkoutUrl != null) {
        await _handleWebCheckout(paymentResponse.payment.checkoutUrl!);
      } else if (paymentResponse.uiConfig.hasNativeSDK) {
        await _handleNativeSDKPayment(paymentResponse);
      } else {
        await _pollPaymentStatus();
      }
    } catch (e) {
      setState(() => _isProcessingPayment = false);
      _showError('Nie udało się zainicjować płatności: $e');
    }
  }

  Future<void> _handleNativeSDKPayment(PaymentInitializationResponse response) async {
    // Try to use checkout URL if available, otherwise show error
    if (response.payment.checkoutUrl != null) {
      await _handleWebCheckout(response.payment.checkoutUrl!);
    } else {
      _showError('Płatność nie może być przetworzona - brak URL płatności');
      setState(() => _isProcessingPayment = false);
    }
  }

  Future<void> _handleWebCheckout(String checkoutUrl) async {
    try {
      final Uri uri = Uri.parse(checkoutUrl);
      if (await canLaunchUrl(uri)) {
        await launchUrl(uri, mode: LaunchMode.externalApplication);
        // Start polling for payment status after opening checkout
        await _pollPaymentStatus();
      } else {
        throw Exception('Nie można otworzyć strony płatności');
      }
    } catch (e) {
      setState(() => _isProcessingPayment = false);
      _showError('Nie udało się otworzyć płatności: $e');
    }
  }

  Future<void> _pollPaymentStatus() async {
    if (_paymentOptions == null) return;

    Timer.periodic(const Duration(seconds: 2), (timer) async {
      try {
        final statusResponse = await _paymentService.getPaymentStatus(_paymentOptions!.donationId);

        dev.log('Payment status check: isCompleted=${statusResponse.isCompleted}, latest status=${statusResponse.latestPayment?.status}');

        if (statusResponse.isCompleted) {
          timer.cancel();
          setState(() => _isProcessingPayment = false);
          _showSuccess('Płatność zakończona sukcesem!');
          Navigator.of(context).pop(true);
          return; // Exit early to prevent further execution
        }

        if (statusResponse.latestPayment != null) {
          final paymentStatus = statusResponse.latestPayment!.status;
          if (paymentStatus == 'FAILED' || paymentStatus == 'CANCELLED') {
            timer.cancel();
            setState(() => _isProcessingPayment = false);
            _showError('Płatność nieudana: ${statusResponse.latestPayment!.failureReason ?? 'Nieznany błąd'}');
            return; // Exit early to prevent further execution
          }

          if (paymentStatus == 'SUCCEEDED') {
            timer.cancel();
            setState(() => _isProcessingPayment = false);
            _showSuccess('Płatność zakończona sukcesem!');
            Navigator.of(context).pop(true);
            return; // Exit early to prevent further execution
          }
        }

        // Stop polling after 5 minutes
        if (timer.tick > 150) {
          timer.cancel();
          setState(() => _isProcessingPayment = false);
          _showError('Przekroczono limit czasu oczekiwania na płatność');
        }
      } catch (e, stackTrace) {
        dev.log('Error polling payment status: $e');
        dev.log('Stack trace: $stackTrace');
        // Continue polling even if there's an error, but limit attempts
        if (timer.tick > 10) { // Stop after 10 failed attempts
          timer.cancel();
          setState(() => _isProcessingPayment = false);
          _showError('Błąd podczas sprawdzania statusu płatności: $e');
        }
      }
    });
  }

  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.red,
      ),
    );
  }

  void _showSuccess(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.green,
      ),
    );
  }

  void _showInfo(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.orange,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          widget.title ?? 'Wsparcie schroniska',
          style: GoogleFonts.poppins(
            fontWeight: FontWeight.w600,
            color: Colors.white,
          ),
        ),
        backgroundColor: AppColors.primaryColor,
        elevation: 0,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _paymentOptions == null
          ? _buildDonationForm()
          : _buildPaymentSelection(),
    );
  }

  Widget _buildDonationForm() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (widget.description != null) ...[
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppColors.primaryColor.withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                widget.description!,
                style: GoogleFonts.poppins(
                  fontSize: 14,
                  color: Colors.grey[700],
                  height: 1.4,
                ),
              ),
            ),
            const SizedBox(height: 24),
          ],

          Text(
            'Kwota donacji',
            style: GoogleFonts.poppins(
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 12),

          // Quick amount buttons
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: _quickAmounts.map((amount) {
              return GestureDetector(
                onTap: () {
                  _amountController.text = amount.toStringAsFixed(0);
                },
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                  decoration: BoxDecoration(
                    border: Border.all(color: AppColors.primaryColor),
                    borderRadius: BorderRadius.circular(25),
                    color: _amountController.text == amount.toStringAsFixed(0)
                        ? AppColors.primaryColor
                        : Colors.transparent,
                  ),
                  child: Text(
                    '${amount.toInt()} PLN',
                    style: GoogleFonts.poppins(
                      fontWeight: FontWeight.w600,
                      color: _amountController.text == amount.toStringAsFixed(0)
                          ? Colors.white
                          : AppColors.primaryColor,
                    ),
                  ),
                ),
              );
            }).toList(),
          ),

          const SizedBox(height: 16),

          // Custom amount input
          TextField(
            controller: _amountController,
            keyboardType: TextInputType.number,
            inputFormatters: [FilteringTextInputFormatter.digitsOnly],
            decoration: InputDecoration(
              labelText: 'Inna kwota (PLN)',
              labelStyle: GoogleFonts.poppins(),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(color: AppColors.primaryColor),
              ),
            ),
          ),

          const SizedBox(height: 24),

          Text(
            'Wiadomość (opcjonalnie)',
            style: GoogleFonts.poppins(
              fontSize: 16,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 8),

          TextField(
            controller: _messageController,
            maxLines: 3,
            decoration: InputDecoration(
              hintText: 'Dodaj wiadomość dla schroniska...',
              hintStyle: GoogleFonts.poppins(),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(color: AppColors.primaryColor),
              ),
            ),
          ),

          const SizedBox(height: 16),

          CheckboxListTile(
            title: Text(
              'Donacja anonimowa',
              style: GoogleFonts.poppins(),
            ),
            value: _anonymous,
            onChanged: (value) {
              setState(() {
                _anonymous = value ?? false;
              });
            },
            activeColor: AppColors.primaryColor,
          ),

          const SizedBox(height: 32),

          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: _createDonationIntent,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primaryColor,
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: Text(
                'Przejdź do płatności',
                style: GoogleFonts.poppins(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPaymentSelection() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Donation summary
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.grey[100],
              borderRadius: BorderRadius.circular(12),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Podsumowanie donacji',
                  style: GoogleFonts.poppins(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 8),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Kwota:',
                      style: GoogleFonts.poppins(),
                    ),
                    Text(
                      '${_paymentOptions!.donation.amount.toStringAsFixed(2)} PLN',
                      style: GoogleFonts.poppins(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
                if (_paymentOptions!.donation.message != null) ...[
                  const SizedBox(height: 4),
                  Text(
                    'Wiadomość: ${_paymentOptions!.donation.message}',
                    style: GoogleFonts.poppins(
                      fontSize: 12,
                      color: Colors.grey[600],
                    ),
                  ),
                ],
              ],
            ),
          ),

          const SizedBox(height: 24),

          Text(
            'Wybierz metodę płatności',
            style: GoogleFonts.poppins(
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 16),

          // Payment providers
          ...(_paymentOptions?.availableProviders ?? []).map((provider) {
            return _buildSimpleProviderCard(provider);
          }).toList(),

          const SizedBox(height: 32),

          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: _selectedProvider != null && !_isProcessingPayment
                  ? _initializePayment
                  : null,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primaryColor,
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: _isProcessingPayment
                  ? const SizedBox(
                height: 20,
                width: 20,
                child: CircularProgressIndicator(
                  color: Colors.white,
                  strokeWidth: 2,
                ),
              )
                  : Text(
                'Zapłać ${_paymentOptions!.donation.amount.toStringAsFixed(2)} PLN',
                style: GoogleFonts.poppins(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSimpleProviderCard(PaymentProviderOption provider) {
    final isSelected = _selectedProvider?.provider == provider.provider;

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        border: Border.all(
          color: isSelected ? AppColors.primaryColor : Colors.grey[300]!,
          width: isSelected ? 2 : 1,
        ),
        borderRadius: BorderRadius.circular(12),
      ),
      child: ListTile(
        title: Row(
          children: [
            Icon(
              provider.provider == 'PAYU' ? Icons.payment : Icons.credit_card,
              color: isSelected ? AppColors.primaryColor : Colors.grey[600],
            ),
            const SizedBox(width: 12),
            Text(
              provider.displayName,
              style: GoogleFonts.poppins(
                fontWeight: FontWeight.w600,
                color: isSelected ? AppColors.primaryColor : Colors.black,
              ),
            ),
            if (provider.recommended) ...[
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: Colors.green,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  'Polecane',
                  style: GoogleFonts.poppins(
                    fontSize: 10,
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ],
        ),
        subtitle: Text(
          'Opłata: ${provider.fees.feeAmount.toStringAsFixed(2)} PLN (${provider.fees.feePercentage.toStringAsFixed(1)}%)',
          style: GoogleFonts.poppins(fontSize: 12),
        ),
        trailing: Icon(
          isSelected ? Icons.radio_button_checked : Icons.radio_button_unchecked,
          color: isSelected ? AppColors.primaryColor : Colors.grey,
        ),
        onTap: () {
          setState(() {
            _selectedProvider = provider;
          });
        },
      ),
    );
  }
}