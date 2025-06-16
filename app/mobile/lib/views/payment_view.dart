import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:url_launcher/url_launcher.dart';
import 'dart:async';
import 'dart:developer' as dev;
import '../models/donation.dart';
import '../models/shelter.dart';
import '../services/payment_service.dart';
import '../styles/colors.dart';
import '../services/web_payment_service.dart';

class PaymentView extends StatefulWidget {
  final int shelterId;
  final int? petId;
  final int? fundraiserId;
  final double? initialAmount;
  final String? title;
  final String? description;
  final Shelter? shelter;
  final MaterialDonationItem? materialItem;
  final int? quantity;

  const PaymentView({
    Key? key,
    required this.shelterId,
    this.petId,
    this.fundraiserId,
    this.initialAmount,
    this.title,
    this.description,
    this.shelter,
    this.materialItem,
    this.quantity,
  }) : super(key: key);

  @override
  State<PaymentView> createState() => _PaymentViewState();
}

class _PaymentViewState extends State<PaymentView> {
  final PaymentService _paymentService = PaymentService();
  final WebPaymentService _webPaymentService = WebPaymentService();
  final TextEditingController _amountController = TextEditingController();
  final TextEditingController _messageController = TextEditingController();
  final TextEditingController _blikController = TextEditingController();

  bool _isLoading = false;
  bool _isProcessingPayment = false;
  PaymentOptionsResponse? _paymentOptions;
  PaymentProviderOption? _selectedProvider;
  PaymentMethodOption? _selectedMethod;
  bool _anonymous = false;

  final List<Map<String, dynamic>> _quickAmounts = [
    {'amount': 5.0, 'icon': 'assets/icons/donation_5.png'},
    {'amount': 10.0, 'icon': 'assets/icons/donation_10.png'},
    {'amount': 20.0, 'icon': 'assets/icons/donation_20.png'},
    {'amount': 50.0, 'icon': 'assets/icons/donation_50.png'},
    {'amount': 100.0, 'icon': 'assets/icons/donation_100.png'},
    {
      'amount': null,
      'icon': 'assets/icons/donation_custom.png',
      'label': 'Dowolna kwota'
    },
  ];
  double? _selectedQuickAmount;
  bool _useCustomAmount = false;

  @override
  void initState() {
    super.initState();
    if (widget.materialItem != null) {
      final amount = widget.materialItem!.price * (widget.quantity ?? 1);
      _amountController.text = amount.toStringAsFixed(0);
      _selectedQuickAmount = amount;
      _useCustomAmount = false;
    } else if (widget.initialAmount != null) {
      _amountController.text = widget.initialAmount!.toStringAsFixed(0);
      final preset = _quickAmounts
          .where((e) => e['amount'] != null)
          .any((e) => (e['amount'] as num).toDouble() == widget.initialAmount);
      if (preset) {
        _selectedQuickAmount = widget.initialAmount;
      } else {
        _useCustomAmount = true;
      }
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
        donationType: widget.materialItem != null ? 'MATERIAL' : 'MONEY',
        amount: widget.materialItem != null ? null : amount,
        message: _messageController.text.isNotEmpty ? _messageController.text : null,
        anonymous: _anonymous,
        itemName: widget.materialItem?.apiName,
        unitPrice: widget.materialItem?.price,
        quantity: widget.quantity,
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
        await _handleWebViewPayment(paymentResponse.payment.checkoutUrl!);
      } else {
        await _pollPaymentStatus();
      }
    } catch (e) {
      setState(() => _isProcessingPayment = false);
      _showError('Nie udało się zainicjować płatności: $e');
    }
  }

  Future<void> _handleWebViewPayment(String checkoutUrl) async {
    try {
      dev.log('Opening payment in WebView: $checkoutUrl');

      _showInfo('Otwieranie płatności...');

      final result = await _webPaymentService.processPayment(
        context: context,
        paymentUrl: checkoutUrl,
        successUrl: 'success',
        cancelUrl: 'cancel',
      );

      dev.log('WebView payment result: ${result?.status}');

      if (result != null) {
        setState(() => _isProcessingPayment = false);

        switch (result.status) {
          case WebPaymentStatus.success:
            await _showPaymentResultDialog(
              success: true,
              title: 'Płatność zakończona sukcesem!',
              message: 'Dziękujemy za przekazane wsparcie dla schroniska. Twoja donacja pomoże zwierzakom znaleźć nowy dom.',
            );
            if (mounted) Navigator.of(context).pop(true);
            break;
          case WebPaymentStatus.cancelled:
            await _showPaymentResultDialog(
              success: false,
              title: 'Płatność anulowana',
              message: 'Płatność została anulowana. Możesz spróbować ponownie w dowolnym momencie.',
            );
            break;
          case WebPaymentStatus.error:
            await _showPaymentResultDialog(
              success: false,
              title: 'Błąd płatności',
              message: 'Wystąpił błąd podczas przetwarzania płatności. Spróbuj ponownie lub wybierz inną metodę płatności.',
            );
            break;
        }
      } else {
        // Jeśli result is null, spróbuj sprawdzić status przez polling
        _showInfo('Sprawdzanie statusu płatności...');
        await _pollPaymentStatus();
      }

    } catch (e) {
      dev.log('WebView payment failed: $e');
      setState(() => _isProcessingPayment = false);

      // Fallback do zewnętrznej przeglądarki
      _showInfo('Przekierowanie do przeglądarki...');
      await _handleWebCheckout(checkoutUrl);
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
          await _showPaymentResultDialog(
            success: true,
            title: 'Płatność zakończona sukcesem!',
            message: 'Dziękujemy za przekazane wsparcie dla schroniska. Twoja donacja pomoże zwierzakom znaleźć nowy dom.',
          );
          if (mounted) Navigator.of(context).pop(true);
          return; // Exit early to prevent further execution
        }

        if (statusResponse.latestPayment != null) {
          final paymentStatus = statusResponse.latestPayment!.status;
          if (paymentStatus == 'FAILED' || paymentStatus == 'CANCELLED') {
            timer.cancel();
            setState(() => _isProcessingPayment = false);
            await _showPaymentResultDialog(
              success: false,
              title: paymentStatus == 'CANCELLED' ? 'Płatność anulowana' : 'Płatność nieudana',
              message: statusResponse.latestPayment!.failureReason ?? 'Wystąpił problem podczas przetwarzania płatności. Spróbuj ponownie.',
            );
            return; // Exit early to prevent further execution
          }

          if (paymentStatus == 'SUCCEEDED') {
            timer.cancel();
            setState(() => _isProcessingPayment = false);
            await _showPaymentResultDialog(
              success: true,
              title: 'Płatność zakończona sukcesem!',
              message: 'Dziękujemy za przekazane wsparcie dla schroniska. Twoja donacja pomoże zwierzakom znaleźć nowy dom.',
            );
            if (mounted) Navigator.of(context).pop(true);
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

  Future<void> _showPaymentResultDialog({
    required bool success,
    required String title,
    required String message,
  }) async {
    return showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          title: Row(
            children: [
              Icon(
                success ? Icons.check_circle : Icons.error,
                color: success ? Colors.green : Colors.red,
                size: 32,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  title,
                  style: GoogleFonts.poppins(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: success ? Colors.green : Colors.red,
                  ),
                ),
              ),
            ],
          ),
          content: Text(
            message,
            style: GoogleFonts.poppins(
              fontSize: 14,
              height: 1.4,
            ),
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
              },
              child: Text(
                'OK',
                style: GoogleFonts.poppins(
                  fontWeight: FontWeight.w600,
                  color: AppColors.primaryColor,
                ),
              ),
            ),
          ],
        );
      },
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
          if (widget.shelter != null) ...[
            Row(
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(30),
                  child: widget.shelter!.finalImageUrl.startsWith('http')
                      ? Image.network(widget.shelter!.finalImageUrl,
                      width: 60, height: 60, fit: BoxFit.cover)
                      : Image.asset(widget.shelter!.finalImageUrl,
                      width: 60, height: 60, fit: BoxFit.cover),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    widget.shelter!.name,
                    style: GoogleFonts.poppins(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),
          ],
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

          if (widget.materialItem == null) ...[
            Text(
              'Kwota donacji',
              style: GoogleFonts.poppins(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 12),

            // Quick amount buttons
            GridView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                childAspectRatio: 2.2,
                crossAxisSpacing: 12,
                mainAxisSpacing: 12,
              ),
              itemCount: _quickAmounts.length,
              itemBuilder: (context, index) {
                final opt = _quickAmounts[index];
                final amountValue = (opt['amount'] as num?)?.toDouble();
                final isCustom = amountValue == null;
                final isSelected =
                isCustom ? _useCustomAmount : _selectedQuickAmount == amountValue;

                return GestureDetector(
                  onTap: () {
                    setState(() {
                      if (isCustom) {
                        _selectedQuickAmount = null;
                        _useCustomAmount = true;
                        _amountController.clear();
                      } else {
                        _useCustomAmount = false;
                        _selectedQuickAmount = amountValue;
                        _amountController.text = amountValue!.toStringAsFixed(0);
                      }
                    });
                  },
                  child: Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      border: Border.all(
                        color:
                        isSelected ? AppColors.primaryColor : Colors.grey[300]!,
                        width: isSelected ? 2 : 1,
                      ),
                      color: isSelected
                          ? AppColors.primaryColor.withOpacity(0.1)
                          : Colors.grey[100],
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Row(
                      children: [
                        Image.asset(
                          opt['icon'],
                          width: 32,
                          height: 32,
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            isCustom
                                ? (opt['label'] ?? 'Dowolna kwota')
                                : '${amountValue!.toInt()} PLN',
                            style: GoogleFonts.poppins(
                              fontWeight: FontWeight.w600,
                              color: AppColors.primaryColor,
                            ),
                          ),
                        ),
                        if (isSelected)
                          const Icon(Icons.check_circle,
                              color: AppColors.primaryColor, size: 20),
                      ],
                    ),
                  ),
                );
              },
            ),

            if (_useCustomAmount) ...[
              const SizedBox(height: 16),

              // Custom amount input
              TextField(
                controller: _amountController,
                keyboardType: TextInputType.number,
                inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                onChanged: (_) => setState(() => _selectedQuickAmount = null),
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
            ],
          ] else ...[
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.grey[100],
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                children: [
                  Image.asset(
                    widget.materialItem!.iconPath,
                    width: 40,
                    height: 40,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      '${widget.materialItem!.name} x${widget.quantity ?? 1}',
                      style: GoogleFonts.poppins(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                  Text(
                    '${_amountController.text} PLN',
                    style: GoogleFonts.poppins(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),
          ],

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

          if (_selectedProvider != null) ...[
            const SizedBox(height: 16),
            Text(
              'Schronisko otrzyma: '
                  '${(_selectedProvider!.fees.netAmount).toStringAsFixed(2)} PLN',
              style: GoogleFonts.poppins(
                fontWeight: FontWeight.w600,
                color: AppColors.primaryColor,
              ),
            ),
          ],

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
            Image.asset(
              provider.provider == 'PAYU'
                  ? 'assets/icons/payu.png'
                  : 'assets/icons/stripe.png',
              width: 40,
              height: 40,
              color: isSelected ? AppColors.primaryColor : null,
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