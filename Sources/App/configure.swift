import FluentPostgreSQL
import Vapor
import Leaf
import Authentication

/// Called before your application initializes.
public func configure(_ config: inout Config, _ env: inout Environment, _ services: inout Services) throws {
  /// Register providers first
  try services.register(FluentPostgreSQLProvider())
  try services.register(LeafProvider())
  try services.register(AuthenticationProvider())
  
  /// Register routes to the router
  let router = EngineRouter.default()
  try routes(router)
  services.register(router, as: Router.self)
  
  /// Register middleware
  var middlewares = MiddlewareConfig() // Create _empty_ middleware config
  let corsConfiguration = CORSMiddleware.Configuration(
    allowedOrigin: .all,
    allowedMethods: [.GET, .POST, .PUT, .OPTIONS, .DELETE, .PATCH],
    allowedHeaders: [.accept, .authorization, .contentType, .origin, .xRequestedWith, .userAgent, .accessControlAllowOrigin]
  )
  let corsMiddleware = CORSMiddleware(configuration: corsConfiguration)
  middlewares.use(corsMiddleware)
  middlewares.use(FileMiddleware.self) // Serves files from `Public/` directory
  middlewares.use(ErrorMiddleware.self)
  middlewares.use(SessionsMiddleware.self)
  services.register(middlewares)

  /// Configure database for Vapor Cloud deployment
  var databases = DatabasesConfig()
  
  let databaseName: String
  let databasePort: Int
  if (env == .testing) {
    databaseName = "vapor-test"
    if let testPort = Environment.get("DATABASE_PORT") {
      databasePort = Int(testPort) ?? 5433
    } else {
      databasePort = 5433
    }
  } else {
    databaseName = Environment.get("DATABASE_DB") ?? "vapor"
    databasePort = 5432
  }
  // If get does not return a password we a running locally and the hardcoded password is used on on localhost.
  let hostname = Environment.get("DATABASE_HOSTNAME") ?? "localhost"
//  let hostname = Environment.get("DATABASE_HOSTNAME") ?? "postgres-test"
  let username = Environment.get("DATABASE_USER") ?? "vapor"
  let password = Environment.get("DATABASE_PASSWORD") ?? "R4RXzEMDpNMO"
  
  let databaseConfig = PostgreSQLDatabaseConfig(hostname: hostname, port: databasePort, username: username, database: databaseName, password: password)
  let database = PostgreSQLDatabase(config: databaseConfig)
  databases.add(database: database, as: .psql)
  services.register(databases)
  
  /// Configure migrations
  var migrations = MigrationConfig()
  migrations.add(model: User.self, database: .psql)
  migrations.add(model: UserComment.self, database: .psql)
  migrations.add(model: Category.self, database: .psql)
  migrations.add(model: UserCommentCategoryPivot.self, database: .psql)
  migrations.add(model: Token.self, database: .psql)
  migrations.add(migration: AdminUser.self, database: .psql)
  services.register(migrations)
  
  /// Adds 'revert' and 'migrate' commands to config. 'revert' wipes the DB, 'migrate' creates tables
  var commandConfig = CommandConfig.default()
  commandConfig.useFluentCommands()
  services.register(commandConfig)
  
  
  // Configure a preferred Leaf renderer
  config.prefer(LeafRenderer.self, for: ViewRenderer.self)
  // Key-Value cache that backs SessionMiddleware
  config.prefer(MemoryKeyedCache.self, for: KeyedCache.self)
  
}
