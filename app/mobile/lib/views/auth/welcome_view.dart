import 'package:flutter/material.dart';
import 'package:animations/animations.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../styles/colors.dart';
import '../../widgets/top_header.dart';
import 'login_view.dart';
import 'register_view.dart';
import '../../widgets/buttons/primary_button.dart';

class WelcomeView extends StatefulWidget {
  const WelcomeView({super.key});

  @override
  State<WelcomeView> createState() => _WelcomeViewState();
}

class _WelcomeViewState extends State<WelcomeView> {
  bool? showLogin;
  bool? oldShowLogin;

  @override
  void setState(VoidCallback fn) {
    oldShowLogin = showLogin;
    super.setState(fn);
  }

  void switchToLogin() => setState(() => showLogin = true);
  void switchToRegister() => setState(() => showLogin = false);
  void backToWelcome() => setState(() => showLogin = null);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.backgroundColor,
      body: Column(
        children: [
          const TopHeader(),
          Expanded(
            child: LayoutBuilder(
              builder: (context, constraints) {
                return SizedBox(
                  width: constraints.maxWidth,
                  height: constraints.maxHeight,
                  child: PageTransitionSwitcher(
                    duration: const Duration(milliseconds: 550),
                    reverse: _isReverseAnimation(),
                    transitionBuilder: (child, animation, secondaryAnimation) {
                      if (_goingBetweenWelcomeAndAuth()) {
                        return _horizontalSlideTransition(
                          child: child,
                          animation: animation,
                          secondaryAnimation: secondaryAnimation,
                        );
                      } else {
                        return _fadeSlideTransition(
                          child: child,
                          animation: animation,
                          secondaryAnimation: secondaryAnimation,
                        );
                      }
                    },
                    child: _buildContent(),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }


  bool _isReverseAnimation() {
    return (showLogin == null && oldShowLogin != null);
  }

  bool _goingBetweenWelcomeAndAuth() {
    final fromWelcomeToAuth = (oldShowLogin == null && showLogin != null);
    final fromAuthToWelcome = (oldShowLogin != null && showLogin == null);
    return fromWelcomeToAuth || fromAuthToWelcome;
  }

  Widget _horizontalSlideTransition({
    required Widget child,
    required Animation<double> animation,
    required Animation<double> secondaryAnimation,
  }) {
    final goingForward = (oldShowLogin == null && showLogin != null);
    final beginOffset = goingForward ? const Offset(1, 0) : const Offset(-1, 0);
    final slideTween = Tween<Offset>(begin: beginOffset, end: Offset.zero)
        .chain(CurveTween(curve: Curves.easeInOut));
    final offsetAnimation = animation.drive(slideTween);

    final fadeTween = Tween<double>(begin: 0.6, end: 1.0)
        .chain(CurveTween(curve: Curves.easeInOut));
    final fadeAnimation = animation.drive(fadeTween);

    return AnimatedBuilder(
      animation: animation,
      builder: (context, _) {
        return Transform.translate(
          offset: offsetAnimation.value * MediaQuery.of(context).size.width,
          child: Opacity(
            opacity: fadeAnimation.value,
            child: child,
          ),
        );
      },
    );
  }

  Widget _fadeSlideTransition({
    required Widget child,
    required Animation<double> animation,
    required Animation<double> secondaryAnimation,
  }) {
    final fadeIn = Tween<double>(begin: 0, end: 1)
        .animate(CurvedAnimation(parent: animation, curve: Curves.easeInOut));
    final fadeOut = Tween<double>(begin: 1, end: 0)
        .animate(CurvedAnimation(parent: secondaryAnimation, curve: Curves.easeInOut));

    final slideIn = Tween<Offset>(begin: const Offset(0, 0.08), end: Offset.zero)
        .animate(CurvedAnimation(parent: animation, curve: Curves.easeOutCubic));
    final slideOut = Tween<Offset>(begin: Offset.zero, end: const Offset(0, 0.08))
        .animate(CurvedAnimation(parent: secondaryAnimation, curve: Curves.easeInCubic));

    return AnimatedBuilder(
      animation: animation,
      builder: (context, _) {
        final isReversing = animation.status == AnimationStatus.reverse
            || secondaryAnimation.status == AnimationStatus.forward;

        final opacity = isReversing ? fadeOut.value : fadeIn.value;
        final offset = isReversing ? slideOut.value : slideIn.value;

        return Transform.translate(
          offset: offset * MediaQuery.of(context).size.height,
          child: Opacity(
            opacity: opacity,
            child: child,
          ),
        );
      },
    );
  }


  Widget _buildContent() {
    if (showLogin == true) {
      return LoginView(
        key: const ValueKey('login'),
        onSwitch: switchToRegister,
        onBack: backToWelcome,
      );
    } else if (showLogin == false) {
      return RegisterView(
        key: const ValueKey('register'),
        onSwitch: switchToLogin,
        onBack: backToWelcome,
      );
    } else {
      return _buildWelcome();
    }
  }

  Widget _buildWelcome() {
    return SingleChildScrollView(
      key: const ValueKey('welcome'),
      padding: const EdgeInsets.symmetric(horizontal: 30, vertical: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: AnimateList(
          interval: 150.ms,
          effects: [
            FadeEffect(duration: 400.ms),
            SlideEffect(begin: const Offset(0, 0.1), curve: Curves.easeOutCubic),
          ],
          children: [
            Text(
              'Dołącz do Petify już teraz.',
              textAlign: TextAlign.center,
              style: GoogleFonts.poppins(
                fontSize: 22,
                fontWeight: FontWeight.bold,
                color: AppColors.textColor,
              ),
            ),

            const SizedBox(height: 15),

            RichText(
              textAlign: TextAlign.center,
              text: TextSpan(
                style: GoogleFonts.poppins(fontSize: 16, color: AppColors.textColor),
                children: const [
                  TextSpan(text: 'Setki zwierząt czekają na '),
                  TextSpan(
                    text: 'Twoją',
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                  TextSpan(text: ' pomoc.\nRazem możemy zmienić ich los.'),
                ],
              ),
            ).animate().fadeIn(delay: 100.ms),

            const SizedBox(height: 15),

            Text(
              'Jeden gest może zmienić całe ich życie!',
              textAlign: TextAlign.center,
              style: GoogleFonts.poppins(
                fontSize: 17,
                fontWeight: FontWeight.bold,
                color: AppColors.primaryColor,
              ),
            ).animate().fadeIn(delay: 200.ms),

            const SizedBox(height: 40),

            PrimaryButton(
              text: 'Zarejestruj się',
              onPressed: switchToRegister,
            ).animate().scale(
              delay: 400.ms, duration: 500.ms, curve: Curves.easeOutBack,
            ),

            const SizedBox(height: 15),

            TextButton(
              onPressed: switchToLogin,
              child: Text(
                'Masz już konto? Zaloguj się',
                style: GoogleFonts.poppins(
                  color: AppColors.primaryColor,
                  fontSize: 16,
                ),
              ),
            ).animate().fadeIn(delay: 500.ms),

            const SizedBox(height: 20),

            ElevatedButton.icon(
              icon: const Icon(Icons.g_mobiledata, size: 30),
              label: const Text('Kontynuuj z Google'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.white,
                foregroundColor: Colors.black87,
                minimumSize: const Size(double.infinity, 50),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                  side: const BorderSide(color: Colors.grey),
                ),
              ),
              onPressed: () {},
            ).animate().fade(delay: 600.ms).slideY(begin: 0.1),
          ],
        ),
      ),
    );
  }
}
