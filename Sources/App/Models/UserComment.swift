import Vapor
import FluentPostgreSQL

final class UserComment: Codable {
  var id: Int?
  var timestamp: String
  var comment: String
  var userID: User.ID
  
  // userComment was type user comment
  init(timestamp: String?, userComment: String, userID: User.ID) {
    self.timestamp = timestamp ?? "Ei aikaleimaa"
//    self.comment = comment
    self.comment = userComment
    self.userID = userID
  }
}

extension UserComment: PostgreSQLModel {}
extension UserComment: Content {}
extension UserComment: Parameter {}
extension UserComment: Equatable {
  static func ==(lhs: UserComment, rhs: UserComment) -> Bool {
    return lhs.timestamp == rhs.timestamp && lhs.comment == rhs.comment
  }
}


// Adds a computed property that returns Fluents generic Parent type using Fluents parent( :) function
extension UserComment {
  var user: Parent<UserComment, User> {
    return parent(\.userID)
  }
  // For the Pivot relationships
  var categories: Siblings<UserComment, Category, UserCommentCategoryPivot> {
    return siblings()  // Fluent returns all the categories of a comment
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
  
//  // For the Pivot relationships
//  var categories: Siblings<UserComment, Category, UserCommentCategoryPivot> {
//    return siblings()  // Fluent returns all the categories of a comment
//  }
}

