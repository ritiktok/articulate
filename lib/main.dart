import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:uuid/uuid.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'dart:async';
import 'constants/themes.dart';
import 'constants/config.dart';
import 'data/repositories/supabase_canvas_repository.dart';
import 'data/repositories/drift_canvas_repository.dart';
import 'data/repositories/hybrid_canvas_repository.dart';
import 'data/repositories/shared_preferences_repository.dart';
import 'data/database/database.dart';
import 'features/canvas/canvas.dart';
import 'dart:math';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await dotenv.load(fileName: ".env");

  try {
    await Supabase.initialize(
      url: Config.supabaseUrl,
      anonKey: Config.supabaseAnonKey,
    );
  } catch (e) {
    if (kDebugMode) {
      print('Failed to initialize Supabase: $e');
    }
  }

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiRepositoryProvider(
      providers: [
        RepositoryProvider<HybridCanvasRepository>(
          create: (context) {
            final remoteRepository = SupabaseCanvasRepository(
              Supabase.instance.client,
            );

            final database = CanvasDatabase();
            final localRepository = DriftCanvasRepository(database);
            final hybridRepository = HybridCanvasRepository(
              remoteRepository: remoteRepository,
              localRepository: localRepository,
            );
            return hybridRepository;
          },
        ),
      ],
      child: FutureBuilder<SharedPreferencesProvider>(
        future: SharedPreferencesRepository.create(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const MaterialApp(
              home: Scaffold(body: Center(child: CircularProgressIndicator())),
            );
          }

          if (snapshot.hasError) {
            return MaterialApp(
              home: Scaffold(
                body: Center(child: Text('Error: ${snapshot.error}')),
              ),
            );
          }

          final sharedPrefsProvider = snapshot.data!;

          return MultiRepositoryProvider(
            providers: [
              RepositoryProvider<SharedPreferencesProvider>.value(
                value: sharedPrefsProvider,
              ),
            ],
            child: MaterialApp(
              title: Config.appName,
              theme: AppThemes.lightTheme,
              home: const HomePage(),
            ),
          );
        },
      ),
    );
  }
}

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  final _sessionIdController = TextEditingController();
  final _titleController = TextEditingController();
  String? _userId;
  bool _isLoading = true;
  bool _isOnline = true;
  StreamSubscription<bool>? _connectivitySubscription;

  @override
  void initState() {
    super.initState();
    _loadUserId();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      _initializeConnectivity();
    });
  }

  void _initializeConnectivity() {
    try {
      final hybridRepository = context.read<HybridCanvasRepository>();

      final initialConnectivity = hybridRepository.isOnline;

      setState(() {
        _isOnline = initialConnectivity;
      });

      _connectivitySubscription = hybridRepository.connectivityStream.listen((
        isOnline,
      ) {
        if (mounted) {
          setState(() {
            _isOnline = isOnline;
          });
        }
      });
    } catch (e) {
      setState(() {
        _isOnline = true;
      });
    }
  }

  Future<void> _loadUserId() async {
    try {
      final sharedPrefsProvider = context.read<SharedPreferencesProvider>();
      _userId = await sharedPrefsProvider.getUserId();

      if (_userId == null) {
        _userId = const Uuid().v4();
        await sharedPrefsProvider.setUserId(_userId!);
      }
    } catch (e) {
      if (kDebugMode) {
        print('Failed to load user ID: $e');
      }
      _userId = const Uuid().v4();
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  @override
  void dispose() {
    _sessionIdController.dispose();
    _titleController.dispose();
    _connectivitySubscription?.cancel();
    super.dispose();
  }

  void _joinSession() {
    if (_sessionIdController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please enter a session ID'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => CanvasPage(
          sessionId: _sessionIdController.text.trim(),
          userId: _userId!,
        ),
      ),
    );
  }

  void _createSession() {
    final sessionId = _generateSessionId();
    final title = _titleController.text.trim().isEmpty
        ? null
        : _titleController.text.trim();

    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) =>
            CanvasPage(sessionId: sessionId, userId: _userId!, title: title),
      ),
    );
  }

  String _generateSessionId() {
    const chars = 'ABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789';
    final random = Random();
    final buffer = StringBuffer();

    for (int i = 0; i < 8; i++) {
      buffer.write(chars[random.nextInt(chars.length)]);
    }

    return buffer.toString();
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Articulate'),
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        actions: [
          Container(
            margin: const EdgeInsets.only(right: 16.0),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 8,
                  height: 8,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: _isOnline ? Colors.green : Colors.orange,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: ConstrainedBox(
          constraints: BoxConstraints(
            minHeight:
                MediaQuery.of(context).size.height -
                MediaQuery.of(context).padding.top -
                kToolbarHeight -
                32,
          ),
          child: IntrinsicHeight(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.brush, size: 64, color: Colors.blue),
                const SizedBox(height: 24),
                const Text(
                  'Collaborative Canvas',
                  style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 8),
                const Text(
                  'Join an existing session or create a new one to start drawing together',
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 16, color: Colors.grey),
                ),
                const SizedBox(height: 32),
                if (!_isOnline)
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(16.0),
                    margin: const EdgeInsets.only(bottom: 16.0),
                    decoration: BoxDecoration(
                      color: Colors.orange[50],
                      border: Border.all(color: Colors.orange[300]!),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Row(
                      children: [
                        Icon(
                          Icons.wifi_off,
                          color: Colors.orange[700],
                          size: 20,
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            'You are currently offline. You need an internet connection to join or create sessions.',
                            style: TextStyle(
                              color: Colors.orange[800],
                              fontSize: 14,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Join Existing Session',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 8),
                        const Text(
                          'Enter a session ID to join an existing drawing board',
                          style: TextStyle(fontSize: 14, color: Colors.grey),
                        ),
                        const SizedBox(height: 16),
                        TextField(
                          controller: _sessionIdController,
                          enabled: _isOnline,
                          decoration: InputDecoration(
                            labelText: 'Session ID',
                            border: const OutlineInputBorder(),
                            hintText: 'Enter session ID',
                            prefixIcon: const Icon(Icons.link),
                            disabledBorder: OutlineInputBorder(
                              borderSide: BorderSide(color: Colors.grey[300]!),
                            ),
                          ),
                        ),
                        const SizedBox(height: 16),
                        SizedBox(
                          width: double.infinity,
                          child: ElevatedButton.icon(
                            onPressed: _isOnline ? _joinSession : null,
                            icon: const Icon(Icons.join_full),
                            label: const Text('Join Session'),
                            style: ElevatedButton.styleFrom(
                              padding: const EdgeInsets.symmetric(vertical: 12),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Create New Session',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 8),
                        const Text(
                          'Create a new drawing session and share the ID with others',
                          style: TextStyle(fontSize: 14, color: Colors.grey),
                        ),
                        const SizedBox(height: 16),
                        TextField(
                          controller: _titleController,
                          enabled: _isOnline,
                          decoration: InputDecoration(
                            labelText: 'Session Title (optional)',
                            border: const OutlineInputBorder(),
                            hintText: 'Enter session title',
                            prefixIcon: const Icon(Icons.title),
                            disabledBorder: OutlineInputBorder(
                              borderSide: BorderSide(color: Colors.grey[300]!),
                            ),
                          ),
                        ),
                        const SizedBox(height: 16),
                        SizedBox(
                          width: double.infinity,
                          child: ElevatedButton.icon(
                            onPressed: _isOnline ? _createSession : null,
                            icon: const Icon(Icons.add),
                            label: const Text('Create New Session'),
                            style: ElevatedButton.styleFrom(
                              padding: const EdgeInsets.symmetric(vertical: 12),
                              backgroundColor: Colors.green,
                              foregroundColor: Colors.white,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 24),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.grey[100],
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          const Icon(Icons.person, size: 16),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              'Your ID: ${_userId?.substring(0, 8)}...',
                              style: const TextStyle(fontSize: 12),
                            ),
                          ),
                        ],
                      ),
                      if (!_isOnline) ...[
                        const SizedBox(height: 8),
                        Row(
                          children: [
                            Icon(
                              Icons.info_outline,
                              size: 14,
                              color: Colors.orange[700],
                            ),
                            const SizedBox(width: 4),
                            Expanded(
                              child: Text(
                                'Drawing works offline, but sessions require internet',
                                style: TextStyle(
                                  fontSize: 11,
                                  color: Colors.orange[700],
                                  fontStyle: FontStyle.italic,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
