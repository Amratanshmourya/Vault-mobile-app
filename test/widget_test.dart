import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:vault/core/services/clipboard_service.dart';
import 'package:vault/core/services/storage_service.dart';
import 'package:vault/data/repositories/vault_repository.dart';
import 'package:vault/main.dart';

void main() {
  testWidgets('App renders onboarding on fresh install', (WidgetTester tester) async {
    SharedPreferences.setMockInitialValues({});
    final storageService = StorageService();
    await storageService.init();

    final clipboardService = ClipboardService(storageService: storageService);
    final vaultRepository = VaultRepository(storageService: storageService);

    await tester.pumpWidget(
      VaultRootApp(
        storageService: storageService,
        clipboardService: clipboardService,
        vaultRepository: vaultRepository,
      ),
    );

    await tester.pumpAndSettle();

    expect(find.text('Welcome to Vault'), findsOneWidget);
    expect(find.text('Next'), findsOneWidget);
  });
}
