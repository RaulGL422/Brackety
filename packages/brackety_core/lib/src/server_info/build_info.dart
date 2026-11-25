/// The web images' release and commit (deploy/web.Dockerfile); debug builds number themselves
/// (0.8.2-dev.7), so what is being tried is told apart. Empty in local and Android builds.
const builtVersion = String.fromEnvironment('BRACKETY_VERSION');
const builtCommit = String.fromEnvironment('BRACKETY_COMMIT');
