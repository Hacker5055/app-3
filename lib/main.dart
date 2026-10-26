import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'app/theme.dart';
import 'state/audit_controller.dart';
import 'ui/audit_dashboard.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  // Amoled system chrome: pure black bars, light icons.
  SystemChrome.setSystemUIOverlayStyle(const SystemUiOverlayStyle(
    statusBarColor: Colors.black,
    statusBarIconBrightness: Brightness.light,
    systemNavigationBarColor: Colors.black,
    systemNavigationBarIconBrightness: Brightness.light,
  ));
  runApp(const FootprintGuardApp());
}

class FootprintGuardApp extends StatefulWidget {
  const FootprintGuardApp({super.key});

  @override
  State<FootprintGuardApp> createState() => _FootprintGuardAppState();
}

class _FootprintGuardAppState extends State<FootprintGuardApp> {
  final AuditController _controller = AuditController();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, _) {
        return MaterialApp(
          title: 'Footprint Guard',
          debugShowCheckedModeBanner: false,
          theme: FGTheme.dark(arabic: _controller.arabic),
          builder: (context, child) => Directionality(
            textDirection:
                _controller.arabic ? TextDirection.rtl : TextDirection.ltr,
            child: child ?? const SizedBox.shrink(),
          ),
          home: AuditDashboard(controller: _controller),
        );
      },
    );
  }
}
