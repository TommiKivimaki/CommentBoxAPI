import FluentPostgreSQL
import Vapor

/// Called before your application initializes.
public func configure(_ config: inout Config, _ env: inout Environment, _ services: inout Services) throws {
  /// Register providers first
  try services.register(FluentPostgreSQLProvider())
  
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
  // middlewares.use(FileMiddleware.self) // Serves files from `Public/` directory
  middlewares.use(ErrorMiddleware.self)
  services.register(middlewares)
  
  
//  var databases = DatabasesConfig()
//  let databaseConfig = PostgreSQLDatabaseConfig(hostname: "localhost", username: "vapor", database: "vapor", password: "R4RXzEMDpNMO")
//  let database = PostgreSQLDatabase(config: databaseConfig)
//  databases.add(database: database, as: .psql)
//  services.register(databases)

  /// Configure database for Vapor Cloud deployment
  var databases = DatabasesConfig()
  let hostname = Environment.get("DATABASE_HOSTNAME") ?? "localhost"
  let username = Environment.get("DATABASE_USER") ?? "vapor"
  let databaseName = Environment.get("DATABASE_DB") ?? "vapor"
  // If get does not return a password we a running locally and the hardcoded password is used on on localhost
  let password = Environment.get("DATABASE_PASSWORD") ?? "R4RXzEMDpNMO"
  let databaseConfig = PostgreSQLDatabaseConfig(hostname: hostname, username: username, database: databaseName, password: password)
  let database = PostgreSQLDatabase(config: databaseConfig)
  databases.add(database: database, as: .psql)
  services.register(databases)
  
  /// Configure migrations
  var migrations = MigrationConfig()
  migrations.add(model: UserComment.self, database: .psql)
  services.register(migrations)
  
}
