import 'package:brackety/features/server/data/server_store.dart';

class FakeServerStore implements ServerStore {
  String? url;

  @override
  Future<String?> read() async => url;

  @override
  Future<void> write(String url) async => this.url = url;
}
