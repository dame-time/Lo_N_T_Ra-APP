import 'package:flutter/material.dart';
import 'package:lo_n_t_ra/controller/permission_checker.dart';
import 'package:lo_n_t_ra/view/login/device_search.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  final PermissionChecker permissionChecker = PermissionChecker();

  @override
  void initState() {
    super.initState();
    _loadNextPageAfterDelay();
    permissionChecker.checkPermissions(context);
  }

  void _loadNextPageAfterDelay() async {
    await Future.delayed(const Duration(seconds: 3));
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (context) => const DeviceSearchScreen()),
    );
  }

  @override
  Widget build(BuildContext context) {
    final double loadingSize = MediaQuery.of(context).size.width * 0.29;
    final double logoSize = MediaQuery.of(context).size.width * 0.3;

    return Scaffold(
      body: Stack(
        alignment: Alignment.center,
        children: [
          Center(
            child: SizedBox(
              width: loadingSize * 0.45,
              height: loadingSize * 0.45,
              child: CircularProgressIndicator(
                strokeWidth: loadingSize * 0.1,
                valueColor: const AlwaysStoppedAnimation<Color>(Colors.green),
              ),
            ),
          ),
          Center(
            child: SizedBox(
              width: logoSize,
              height: logoSize,
              child: Image.asset('assets/logo.png'),
            ),
          ),
        ],
      ),
    );
  }
}
