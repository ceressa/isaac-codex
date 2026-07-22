// Picks the web (file download/upload) or the stub (clipboard) implementation.
export 'seed_io_stub.dart' if (dart.library.html) 'seed_io_web.dart';
