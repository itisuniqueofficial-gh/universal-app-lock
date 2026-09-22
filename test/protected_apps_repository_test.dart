import 'package:flutter_test/flutter_test.dart';
import 'package:universal_app_lock/repositories/key_value_store.dart';
import 'package:universal_app_lock/repositories/protected_apps_repository.dart';

void main() {
  group('ProtectedAppsRepository', () {
    late InMemoryKeyValueStore store;
    late ProtectedAppsRepository repo;

    setUp(() {
      store = InMemoryKeyValueStore();
      repo = ProtectedAppsRepository(store);
    });

    test('starts empty', () async {
      expect(await repo.getProtectedPackages(), isEmpty);
      expect(await repo.count(), 0);
    });

    test('add / isProtected / remove', () async {
      await repo.addProtectedPackage('com.a');
      expect(await repo.isProtected('com.a'), isTrue);
      expect(await repo.count(), 1);

      await repo.removeProtectedPackage('com.a');
      expect(await repo.isProtected('com.a'), isFalse);
      expect(await repo.count(), 0);
    });

    test('toggle flips state and returns new value', () async {
      expect(await repo.toggle('com.b'), isTrue);
      expect(await repo.isProtected('com.b'), isTrue);
      expect(await repo.toggle('com.b'), isFalse);
      expect(await repo.isProtected('com.b'), isFalse);
    });

    test('ignores blank package names', () async {
      await repo.addProtectedPackage('   ');
      expect(await repo.count(), 0);
    });

    test('persists across repository instances via the same store', () async {
      await repo.addProtectedPackage('com.c');
      final repo2 = ProtectedAppsRepository(store);
      expect(await repo2.isProtected('com.c'), isTrue);
    });

    test('listenable reflects changes', () async {
      await repo.load();
      expect(repo.listenable.value, isEmpty);
      await repo.addProtectedPackage('com.d');
      expect(repo.listenable.value, contains('com.d'));
    });
  });
}
