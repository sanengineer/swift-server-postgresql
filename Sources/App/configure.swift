import Vapor
import FluentPostgresDriver
import Fluent
import Redis


public func configure(_ app: Application) throws {
    

    if let dbUrlEnv = Environment.get("DATABASE_URL"), var postgresConfig = PostgresConfiguration(url: dbUrlEnv) {
        postgresConfig.tlsConfiguration = .makeClientConfiguration()
        postgresConfig.tlsConfiguration?.certificateVerification = .none
        app.databases.use(.postgres(
            configuration: postgresConfig
        ), as: .psql)
    } else {
        app.databases.use(.postgres(
            hostname: Environment.get("DB_HOSTNAME")!,
            port: Environment.get("DB_PORT").flatMap(Int.init(_:))!,
            username: Environment.get("DB_USERNAME")!,
            password: Environment.get("DB_PASSWORD")!,
            database: Environment.get("DB_NAME")!),
            as: .psql)
    }
    
    let corsConfiguration = CORSMiddleware.Configuration(
        allowedOrigin: .all,
        allowedMethods: [.GET, .POST, .PUT, .OPTIONS, .DELETE, .PATCH],
        allowedHeaders: [.accept, .authorization, .contentType, .origin, .xRequestedWith, .userAgent, .accessControlAllowOrigin]
    )
    let cors = CORSMiddleware(configuration: corsConfiguration)

    // Only add this if you want to enable the default per-route logging
    let routeLogging = RouteLoggingMiddleware(logLevel: .info)

    // Add the default error middleware
    let error = ErrorMiddleware.default(environment: app.environment)
    // Clear any existing middleware.
    app.middleware = .init()
    app.middleware.use(cors)
    app.middleware.use(routeLogging)
    app.middleware.use(error)

    app.logger.logLevel = .debug
    
    app.migrations.add(CreateSchemaRoles())
    app.migrations.add(CreateSchemaUser())
    app.migrations.add(SeedDBRoles())
    
    //migration
    try app.autoMigrate().wait()

    //register routes
    try routes(app)
    
}
