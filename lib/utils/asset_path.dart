class AssetPath {
  static String resolve(String routeOrPath) {
    if (routeOrPath.startsWith('/letters/')) {
      final file = routeOrPath.split('/').last;
      return 'assets/data/letters/$file';
    }
    if (routeOrPath.startsWith('/assets/')) {
      return routeOrPath.substring(1); // "/assets/..." -> "assets/..."
    }
    return routeOrPath.startsWith('assets/')
        ? routeOrPath
        : 'assets/data/letters/$routeOrPath';
  }
}
