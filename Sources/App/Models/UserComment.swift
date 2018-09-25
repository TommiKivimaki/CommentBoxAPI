import Vapor
import FluentSQLite

final class UserComment: Codable {
  var id: Int?
  var comment: String
  
  init(user comment: String) {
    self.comment = comment
  }
}

extension UserComment: SQLiteModel {}
extension UserComment: Migration {}
extension UserComment: Content {}

