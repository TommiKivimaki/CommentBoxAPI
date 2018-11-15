import Vapor
import FluentPostgreSQL

final class UserComment: Codable {
  var id: Int?
  var timestamp: String
  var comment: String
  
  init(timestamp: String, user comment: String) {
    self.timestamp = timestamp
    self.comment = comment
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

