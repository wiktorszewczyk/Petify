import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:google_fonts/google_fonts.dart';
import '../styles/colors.dart';
import '../models/shelter.dart';
import '../models/donation.dart';
import '../services/payment_service.dart';
import 'payment_view.dart';

class ShelterDonationSheet extends StatefulWidget {
  final Shelter shelter;

  const ShelterDonationSheet({
    Key? key,
    required this.shelter,
  }) : super(key: key);

  static Future<bool?> show(BuildContext context, Shelter shelter) {
    return showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => ShelterDonationSheet(shelter: shelter),
    );
  }

  @override
  State<ShelterDonationSheet> createState() => _ShelterDonationSheetState();
}

class _ShelterDonationSheetState extends State<ShelterDonationSheet> {
  final PaymentService _paymentService = PaymentService();
  final TextEditingController _customAmountController = TextEditingController();
  bool _isLoading = false;
  double? _selectedAmount;
  bool _isCustomAmount = false;
  FundraiserResponse? _mainFundraiser;

  final List<Map<String, dynamic>> _donationOptions = [
    {
      'amount': 5.0,
      'icon': Icons.attach_money,
      'label': '5 zł',
    },
    {
      'amount': 10.0,
      'icon': Icons.favorite,
      'label': '10 zł',
    },
    {
      'amount': 20.0,
      'icon': Icons.favorite_border,
      'label': '20 zł',
    },
    {
      'amount': 50.0,
      'icon': Icons.pets,
      'label': '50 zł',
    },
    {
      'amount': 100.0,
      'icon': Icons.card_giftcard,
      'label': '100 zł',
    },
    {
      'amount': null,
      'icon': Icons.edit,
      'label': 'Inna kwota',
    },
  ];

  @override
  void initState() {
    super.initState();
    _loadMainFundraiser();
  }

  @override
  void dispose() {
    _customAmountController.dispose();
    super.dispose();
  }

  Future<void> _loadMainFundraiser() async {
    try {
      final fundraiser = await _paymentService.getShelterMainFundraiser(widget.shelter.id);
      if (mounted) {
        setState(() {
          _mainFundraiser = fundraiser;
        });
      }
    } catch (e) {
      print('Błąd podczas ładowania głównej zbiórki: $e');
    }
  }

  void _selectAmount(double? amount) {
    setState(() {
      _selectedAmount = amount;
      _isCustomAmount = amount == null;
      if (!_isCustomAmount) {
        _customAmountController.clear();
      } else {
        FocusScope.of(context).requestFocus();
      }
    });
  }

  Future<void> _proceedToPayment() async {
    double? donationAmount;

    if (_isCustomAmount) {
      try {
        final customAmount = double.parse(_customAmountController.text.replaceAll(',', '.'));
        if (customAmount <= 0) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Kwota musi być większa od zera')),
          );
          return;
        }
        donationAmount = customAmount;
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Wprowadź prawidłową kwotę')),
        );
        return;
      }
    } else if (_selectedAmount != null) {
      donationAmount = _selectedAmount;
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Wybierz kwotę wsparcia')),
      );
      return;
    }

    if (_mainFundraiser == null || !_mainFundraiser!.canAcceptDonations) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Schronisko nie ma aktywnej zbiórki')),
      );
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      final result = await Navigator.of(context).push(
        MaterialPageRoute(
          builder: (context) => PaymentView(
            shelterId: widget.shelter.id,
            shelter: widget.shelter,
            fundraiserId: _mainFundraiser!.id,
            initialAmount: donationAmount!,
            title: 'Wspieraj: ${_mainFundraiser!.title}',
            description: _mainFundraiser!.description,
          ),
        ),
      );

      if (mounted) {
        setState(() {
          _isLoading = false;
        });

        // Jeśli płatność była udana, zamknij sheet i zwróć sukces
        if (result == true) {
          Navigator.of(context).pop(true);
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Wystąpił błąd: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      constraints: BoxConstraints(
        maxHeight: MediaQuery.of(context).size.height * 0.85,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          _buildHeader(),
          if (_isLoading)
            const Padding(
              padding: EdgeInsets.all(32.0),
              child: CircularProgressIndicator(
                valueColor: AlwaysStoppedAnimation<Color>(AppColors.primaryColor),
              ),
            )
          else
            Flexible(
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    _buildShelterDetails(),
                    _buildDonationOptions(),
                    if (_isCustomAmount) _buildCustomAmountInput(),
                    _buildActionButtons(),
                    _buildDisclaimerText(),
                    SizedBox(height: MediaQuery.of(context).viewInsets.bottom + 16),
                  ],
                ),
              ),
            ),
        ],
      ),
    ).animate().slideY(
      begin: 1,
      end: 0,
      duration: 400.ms,
      curve: Curves.easeOutQuart,
    );
  }

  Widget _buildHeader() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            spreadRadius: 1,
            blurRadius: 5,
          ),
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          const SizedBox(width: 32),
          Text(
            'Wsparcie finansowe',
            style: GoogleFonts.poppins(
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          IconButton(
            onPressed: () => Navigator.of(context).pop(),
            icon: const Icon(Icons.close),
            tooltip: 'Zamknij',
          ),
        ],
      ),
    );
  }

  Widget _buildShelterDetails() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
      child: Row(
        children: [
          Container(
            width: 60,
            height: 60,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              image: DecorationImage(
                image: widget.shelter.finalImageUrl.startsWith('http')
                    ? NetworkImage(widget.shelter.finalImageUrl)
                    : AssetImage(widget.shelter.finalImageUrl) as ImageProvider,
                fit: BoxFit.cover,
              ),
              border: Border.all(color: AppColors.primaryColor, width: 2),
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  widget.shelter.name,
                  style: GoogleFonts.poppins(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Text(
                  widget.shelter.address.toString(),
                  style: GoogleFonts.poppins(
                    fontSize: 14,
                    color: Colors.grey[600],
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDonationOptions() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Wybierz kwotę wsparcia:',
            style: GoogleFonts.poppins(
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 16),
          GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2,
              childAspectRatio: 2.0,
              crossAxisSpacing: 12,
              mainAxisSpacing: 12,
            ),
            itemCount: _donationOptions.length,
            itemBuilder: (context, index) {
              final option = _donationOptions[index];
              final isCustomOption = option['amount'] == null;
              final isSelected = isCustomOption
                  ? _isCustomAmount
                  : _selectedAmount == option['amount'];

              return GestureDetector(
                onTap: () => _selectAmount(option['amount']),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  decoration: BoxDecoration(
                    color: isSelected ? AppColors.primaryColor.withOpacity(0.2) : Colors.grey[100],
                    borderRadius: BorderRadius.circular(16),
                    border: isSelected
                        ? Border.all(color: AppColors.primaryColor, width: 2)
                        : Border.all(color: Colors.grey[300]!, width: 1),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.start,
                    children: [
                      Icon(
                        option['icon'],
                        size: 32,
                        color: isSelected ? AppColors.primaryColor : Colors.grey[600],
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          option['label'],
                          style: GoogleFonts.poppins(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                      if (isSelected)
                        const Icon(
                          Icons.check_circle,
                          color: AppColors.primaryColor,
                          size: 24,
                        ),
                    ],
                  ),
                ).animate().fadeIn(duration: 200.ms, delay: (50 * index).ms),
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildCustomAmountInput() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.grey[100],
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AppColors.primaryColor),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Wpisz kwotę:',
              style: GoogleFonts.poppins(
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _customAmountController,
              keyboardType: TextInputType.numberWithOptions(decimal: true),
              inputFormatters: [
                FilteringTextInputFormatter.allow(RegExp(r'^\d+[,.]?\d{0,2}')),
              ],
              decoration: InputDecoration(
                hintText: 'np. 30',
                suffixText: 'zł',
                suffixStyle: GoogleFonts.poppins(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(color: Colors.grey[300]!),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: const BorderSide(color: AppColors.primaryColor, width: 2),
                ),
                contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
              ),
              style: GoogleFonts.poppins(
                fontSize: 16,
                fontWeight: FontWeight.w500,
              ),
              autofocus: true,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildActionButtons() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
      child: SizedBox(
        width: double.infinity,
        child: ElevatedButton(
          onPressed: _proceedToPayment,
          style: ElevatedButton.styleFrom(
            backgroundColor: AppColors.primaryColor,
            foregroundColor: Colors.black,
            padding: const EdgeInsets.symmetric(vertical: 14),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
          ),
          child: Text(
            'Przejdź do płatności',
            style: GoogleFonts.poppins(
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildDisclaimerText() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
      child: Text(
        'Petify pełni rolę pośrednika w przekazywaniu dotacji dla schronisk. '
            'Wszystkie środki po potrąceniu kosztów operacyjnych są '
            'przekazywane bezpośrednio na konto schroniska. '
            'Petify nie ponosi odpowiedzialności za sposób spożytkowania środków przez schronisko.',
        style: GoogleFonts.poppins(
          fontSize: 10,
          color: Colors.grey[600],
        ),
        textAlign: TextAlign.center,
      ),
    );
  }
}