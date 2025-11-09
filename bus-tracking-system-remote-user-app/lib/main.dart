import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'screens/splash_screen.dart'; // شاشة التحميل
import 'repositories/transport_repository.dart';
import 'services/tracking_service.dart';

Future<void> main() async {
  await dotenv.load(fileName: '.env');
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        Provider<TrackingService>(
          create: (_) => TrackingService(),
          dispose: (_, service) => service.dispose(),
        ),
        Provider<TransportRepository>(
          create: (ctx) =>
              TrackingTransportRepository(ctx.read<TrackingService>()),
          dispose: (_, repo) => repo.dispose(),
        ),
      ],
      child: MaterialApp(
        title: 'Bus Tracking App',
        theme: ThemeData(primarySwatch: Colors.blue),
        home: const SplashScreen(), // شاشة التحميل أولاً
      ),
    );
  }
}
