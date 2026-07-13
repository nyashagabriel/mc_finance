import 'package:flutter/material.dart';
import 'package:googleapis/drive/v3.dart' as drive;
import 'core/libs/signing.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const McFinanceApp());
}

class McFinanceApp extends StatelessWidget {
  const McFinanceApp({super.key});

  @override
  Widget build(BuildContext context) {
    const Color brandBlue = Color(0xFF0058A3);
    const Color brandRed = Color(0xFFD42E12);
    const Color darkSurface = Color(0xFF121820);
    const Color darkBackground = Color(0xFF0A0E14);

    return MaterialApp(
      title: 'McLuke Finance Prototype',
      debugShowCheckedModeBanner: false,
      themeMode: ThemeMode.dark,
      darkTheme: ThemeData(
        brightness: Brightness.dark,
        scaffoldBackgroundColor: darkBackground,
        primaryColor: brandBlue,
        colorScheme: const ColorScheme.dark(
          primary: brandBlue,
          secondary: brandRed,
          surface: darkSurface,
          onPrimary: Colors.white,
          onSecondary: Colors.white,
          onSurface: Color(0xFFE0E6ED),
        ),
        cardTheme: CardThemeData(
          color: darkSurface,
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
            side: BorderSide(color: brandBlue.withAlpha(50), width: 1),
          ),
        ),
        appBarTheme: const AppBarTheme(
          backgroundColor: darkBackground,
          elevation: 0,
          centerTitle: false,
          titleTextStyle: TextStyle(
            fontFamily: 'Roboto',
            fontSize: 20,
            fontWeight: FontWeight.w700,
            color: Colors.white,
          ),
        ),
      ),
      home: const PrototypeDashboard(),
    );
  }
}

class PrototypeDashboard extends StatefulWidget {
  const PrototypeDashboard({super.key});

  @override
  State<PrototypeDashboard> createState() => _PrototypeDashboardState();
}

class _PrototypeDashboardState extends State<PrototypeDashboard> {
  bool _isLoading = false;
  List<drive.File> _sheets = [];
  String? _statusMessage;

  Future<void> _handleSyncSheets() async {
    setState(() {
      _isLoading = true;
      _statusMessage = "Authenticating with Google...";
    });

    try {
      final fetchedSheets = await listUserSheets();
      setState(() {
        _sheets = fetchedSheets;
        _isLoading = false;
        _statusMessage = fetchedSheets.isEmpty 
            ? "No spreadsheets found or sign-in cancelled." 
            : null;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
        _statusMessage = "Failed to sync: ${e.toString()}";
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: const Row(
          children: [
            Icon(Icons.terminal, color: Color(0xFFD42E12)),
            SizedBox(width: 10),
            Text('McLuke TECHWORLD'),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _isLoading ? null : _handleSyncSheets,
            tooltip: 'Sync Sheets',
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _BrandHeader(onActionPressed: _handleSyncSheets, isLoading: _isLoading),
            const SizedBox(height: 20),
            if (_statusMessage != null) ...[
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: theme.colorScheme.secondary.withAlpha(25),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: theme.colorScheme.secondary.withAlpha(100)),
                ),
                child: Text(
                  _statusMessage!,
                  style: TextStyle(color: theme.colorScheme.secondary),
                ),
              ),
              const SizedBox(height: 16),
            ],
            Text(
              'RECENT SPREADSHEETS (${_sheets.length})',
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w800,
                letterSpacing: 1.2,
                color: theme.colorScheme.onSurface.withAlpha(150),
              ),
            ),
            const SizedBox(height: 10),
            Expanded(
              child: _isLoading
                  ? const Center(child: CircularProgressIndicator())
                  : _sheets.isEmpty
                      ? _EmptyStateView(onRetry: _handleSyncSheets)
                      : ListView.separated(
                          itemCount: _sheets.length,
                          separatorBuilder: (_, _) => const SizedBox(height: 8),
                          itemBuilder: (context, index) {
                            return _SheetListCard(sheet: _sheets[index]);
                          },
                        ),
            ),
          ],
        ),
      ),
    );
  }
}

class _BrandHeader extends StatelessWidget {
  final VoidCallback onActionPressed;
  final bool isLoading;

  const _BrandHeader({
    required this.onActionPressed,
    required this.isLoading,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            theme.colorScheme.primary.withAlpha(80),
            theme.colorScheme.surface,
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: theme.colorScheme.primary.withAlpha(100), width: 1.5),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: theme.colorScheme.secondary,
              borderRadius: BorderRadius.circular(4),
            ),
            child: const Text(
              'PROTOTYPE v0.1',
              style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Colors.white),
            ),
          ),
          const SizedBox(height: 12),
          const Text(
            'Google Sheets Engine',
            style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Colors.white),
          ),
          const SizedBox(height: 6),
          Text(
            'Connect your Google Drive to pull recent financial ledgers and prototype data pipelines.',
            style: TextStyle(fontSize: 13, color: theme.colorScheme.onSurface.withAlpha(180)),
          ),
          const SizedBox(height: 16),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: isLoading ? null : onActionPressed,
              style: ElevatedButton.styleFrom(
                backgroundColor: theme.colorScheme.primary,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
              ),
              icon: isLoading 
                  ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                  : const Icon(Icons.link),
              label: Text(isLoading ? 'CONNECTING...' : 'CONNECT GOOGLE OAUTH'),
            ),
          ),
        ],
      ),
    );
  }
}

class _SheetListCard extends StatelessWidget {
  final drive.File sheet;

  const _SheetListCard({required this.sheet});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final modifiedDate = sheet.modifiedTime != null 
        ? '${sheet.modifiedTime!.year}-${sheet.modifiedTime!.month.toString().padLeft(2, '0')}-${sheet.modifiedTime!.day.toString().padLeft(2, '0')}'
        : 'Unknown date';

    return Card(
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        leading: Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: theme.colorScheme.primary.withAlpha(30),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(Icons.table_chart, color: theme.colorScheme.primary),
        ),
        title: Text(
          sheet.name ?? 'Unnamed Spreadsheet',
          style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 15, color: Colors.white),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
        subtitle: Padding(
          padding: const EdgeInsets.only(top: 4.0),
          child: Row(
            children: [
              Icon(Icons.access_time, size: 12, color: theme.colorScheme.onSurface.withAlpha(120)),
              const SizedBox(width: 4),
              Text(
                'Modified: $modifiedDate',
                style: TextStyle(fontSize: 12, color: theme.colorScheme.onSurface.withAlpha(150)),
              ),
            ],
          ),
        ),
        trailing: Icon(Icons.chevron_right, color: theme.colorScheme.onSurface.withAlpha(100)),
        onTap: () {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Selected Sheet ID: ${sheet.id}'),
              duration: const Duration(seconds: 2),
              backgroundColor: theme.colorScheme.surface,
            ),
          );
        },
      ),
    );
  }
}

class _EmptyStateView extends StatelessWidget {
  final VoidCallback onRetry;

  const _EmptyStateView({required this.onRetry});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.folder_open, size: 48, color: theme.colorScheme.onSurface.withAlpha(80)),
          const SizedBox(height: 12),
          Text(
            'No Sheets Loaded',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: theme.colorScheme.onSurface.withAlpha(180)),
          ),
          const SizedBox(height: 4),
          Text(
            'Tap above to authenticate and pull live data.',
            style: TextStyle(fontSize: 13, color: theme.colorScheme.onSurface.withAlpha(120)),
          ),
        ],
      ),
    );
  }
}