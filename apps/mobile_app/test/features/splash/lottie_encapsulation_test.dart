import '../../support/package_encapsulation.dart';

/// Worked example of the encapsulation guardrail.
///
/// `lottie` is a rendering detail of the splash screen. Keeping its import in
/// one directory means swapping the animation library — or replacing the
/// splash with plain widgets — touches that directory and nothing else.
///
/// Copy this test for every dependency that must stay behind an adapter: any
/// pre-1.0 package, any package with a history of breaking minor releases,
/// and anything whose types would otherwise spread through the codebase. See
/// `docs/architecture/patterns/platform-gateways.md`.
void main() {
  expectPackageEncapsulated(
    package: 'lottie',
    allowedDirectory: 'lib/features/splash/presentation',
  );
}
