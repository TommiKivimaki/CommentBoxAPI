// This migration add twitterURL to User.self model

import FluentPostgreSQL
import Vapor

struct AddTwitterURLToUser: Migration {
  typealias Database = PostgreSQLDatabase
  
  static func prepare(on conn: PostgreSQLConnection) -> EventLoopFuture<Void> {
    return Database.update(User.self, on: conn) { builder in
      builder.field(for: \.twitterURL)
    }
  }
  
  static func revert(on conn: PostgreSQLConnection) -> EventLoopFuture<Void> {
    return Database.update(User.self, on: conn) { builder in
      builder.deleteField(for: \.twitterURL)
    }
  }
  
}
