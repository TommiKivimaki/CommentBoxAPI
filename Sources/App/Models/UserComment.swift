import Vapor
import FluentPostgreSQL

final class UserComment: Codable {
  var id: Int?
  var timestamp: String
  var comment: String
  var userID: User.ID
  
  init(timestamp: String, user comment: String, userID: User.ID) {
    self.timestamp = timestamp
    self.comment = comment
    self.userID = userID
  }
}

extension UserComment: PostgreSQLModel {}
extension UserComment: Content {}
extension UserComment: Equatable {
  static func ==(lhs: UserComment, rhs: UserComment) -> Bool {
    return lhs.timestamp == rhs.timestamp && lhs.comment == rhs.comment
  }
}
extension UserComment: Parameter {}

// Adds a computed property that returns Fluents generic Parent type using Fluents parent( :) function
extension UserComment {
  var user: Parent<UserComment, User> {
    return parent(\.userID)
  }
}

// Foreign Key support
extension UserComment: Migration {
  static func prepare(on connection: PostgreSQLConnection) -> Future<Void> {
    return Database.create(self, on: connection) { builder in  // Create table for  UserComment
      // Add all the fields to database
      try addProperties(to: builder)
      // Add a reference between userID property on UserComment and the id property on User
      // Links UserComment's userID property to User table
      builder.reference(from: \.userID, to: \User.id)
    }
  }
}

