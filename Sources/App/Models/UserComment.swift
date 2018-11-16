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
extension UserComment: Migration {}
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

