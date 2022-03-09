import Vapor
import FluentPostgresDriver
import Fluent
import Redis


public func configure(_ app: Application) throws {
    
    let port: Int
    
    guard let serverHostname = Environment.get("SERVER_HOSTNAME") else {
        return print("No Env Server Hostname")
    }
    
    if let envPort = Environment.get("SERVER_PORT") {
        port = Int(envPort) ?? 8081
    } else {
        port = 8081
    }

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
    
    app.logger.logLevel = .debug
    app.http.server.configuration.port = port
    app.http.server.configuration.hostname = serverHostname
    
    app.migrations.add(CreateSchemaRoles())
    app.migrations.add(CreateSchemaUser())
    app.migrations.add(SeedDBRoles())
    
    //migration
    try app.autoMigrate().wait()

    //register routes
    try routes(app)
    
}
