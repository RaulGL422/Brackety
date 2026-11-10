import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../auth/state/admin_session.dart';
import '../data/users_api.dart';

final usersApiProvider = Provider<UsersApi>(
  (ref) => UsersApi(ref.watch(adminDioProvider)),
);

/// What the list searches (email or organization) and which page it shows.
typedef UserSearch = ({String query, int page});

final userSearchProvider = NotifierProvider<UserSearchController, UserSearch>(
  UserSearchController.new,
);

class UserSearchController extends Notifier<UserSearch> {
  @override
  UserSearch build() => (query: '', page: 0);

  /// A new search starts on the first page.
  void search(String query) => state = (query: query.trim(), page: 0);

  void go(int page) => state = (query: state.query, page: page);
}

final usersProvider =
    AsyncNotifierProvider.autoDispose<UsersController, AdminUserPage>(
      UsersController.new,
      retry: (_, _) => null,
    );

class UsersController extends AsyncNotifier<AdminUserPage> {
  @override
  Future<AdminUserPage> build() {
    final search = ref.watch(userSearchProvider);
    return ref
        .read(usersApiProvider)
        .list(query: search.query, page: search.page);
  }

  void refresh() => ref.invalidateSelf();
}

/// The account open in the tab; null shows the list.
final selectedUserProvider = NotifierProvider<SelectedUserController, String?>(
  SelectedUserController.new,
);

class SelectedUserController extends Notifier<String?> {
  @override
  String? build() => null;

  void open(String accountId) => state = accountId;

  void close() => state = null;
}

final userDetailProvider = AsyncNotifierProvider.autoDispose
    .family<UserDetailController, AdminUserDetail, String>(
      UserDetailController.new,
      retry: (_, _) => null,
    );

/// One account; every action reloads it and the list.
class UserDetailController extends AsyncNotifier<AdminUserDetail> {
  UserDetailController(this.accountId);

  final String accountId;

  UsersApi get _api => ref.read(usersApiProvider);

  @override
  Future<AdminUserDetail> build() => _api.detail(accountId);

  void refresh() => ref.invalidateSelf();

  Future<void> suspend(String reason) =>
      _run(() => _api.suspend(accountId, reason));

  Future<void> unsuspend(String reason) =>
      _run(() => _api.unsuspend(accountId, reason));

  Future<DateTime> delete(String reason) =>
      _run(() => _api.delete(accountId, reason));

  // Reloads after it, and after a 404 too: the account changed meanwhile.
  Future<T> _run<T>(Future<T> Function() call) async {
    try {
      final result = await call();
      _reload();
      return result;
    } on DioException catch (e) {
      if (e.response?.statusCode == 404) _reload();
      rethrow;
    }
  }

  void _reload() {
    if (!ref.mounted) return;
    ref
      ..invalidateSelf()
      ..invalidate(usersProvider);
  }
}
