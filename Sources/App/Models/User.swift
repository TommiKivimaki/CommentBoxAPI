import Foundation
import Vapor
import FluentPostgreSQL
import Authentication

final class User: Codable {
  var id: UUID?
  var name: String
  var username: String
  var password: String
  var twitterURL: String?
  
  init(name: String, username: String, password: String, twitterURL: String? = nil) {
    self.name = name
    self.username = username
    self.password = password
    self.twitterURL = twitterURL
  }
  
  // Inner class to represent a public view of the user
  final class Public: Codable {
    var id: UUID?
    var name: String
    var username: String
    var twitterURL: String?
    
    init(id: UUID?, name: String, username: String, twitterURL: String? = nil) {
      self.id = id
      self.name = name
      self.username = username
      self.twitterURL = twitterURL
    }
  }
}

extension User: PostgreSQLUUIDModel {}
extension User: Content {}
extension User: Migration {
  static func prepare(on connection: PostgreSQLConnection) -> Future<Void> {
    return Database.create(self, on: connection) { builder in  // Creates User table
//      try addProperties(to: builder)                        // Adds all the columns to the User table based on User's properties
      
      // Manually add only original fields. If e.g. for testing db is reverted it's important that only the original fields
      // are added in the initial migration. Thus manually adding fields here. 
      builder.field(for: \.id, isIdentifier: true)
      builder.field(for: \.name)
      builder.field(for: \.username)
      builder.field(for: \.password)
      builder.unique(on: \.username) // Add a unique constraint to User's username
    }
  }
}
extension User: Parameter {}
extension User {
  var userComments: Children<User, UserComment> {
    return children(\.userID)
  }
}
extension User {
  func convertToPublic() -> User.Public {
    return User.Public(id: id, name: name, username: username, twitterURL: twitterURL)
  }
}

// Extension to allow call convertToPublic on Future<User>
extension Future where T: User {
  func convertToPublic() -> Future<User.Public> {
    return self.map(to: User.Public.self) { user in
      return user.convertToPublic()
    }
  }
}

extension User.Public: Content {}

extension User: BasicAuthenticatable {
  static var usernameKey: WritableKeyPath<User, String> {
    return \User.username
  }
  
  static var passwordKey: WritableKeyPath<User, String> {
    return \User.password
  }
}
extension User: TokenAuthenticatable {
  typealias TokenType = Token  // Tell Vapor what type a token is
}

extension User: PasswordAuthenticatable {
  // All the necessary properties are already implemented in BasicAuthenticable
}
extension User: SessionAuthenticatable {
  // Allows Vapor to save and retrieve user as part of a session
}

struct AdminUser: Migration {
  typealias Database = PostgreSQLDatabase
  
  static func prepare(on conn: PostgreSQLConnection) -> Future<Void> {
    let password = try? BCrypt.hash("password")
    guard let hashedPassword = password else { fatalError("Failed to create admin user") }
    let user = User(name: "Real Admin", username: "realadmin", password: hashedPassword)
    return user.save(on: conn).transform(to: ())
  }
  
  static func revert(on conn: PostgreSQLConnection) -> Future<Void> {
    return .done(on: conn)
  }
}
