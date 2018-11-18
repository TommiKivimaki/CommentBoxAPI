import Vapor
import FluentPostgreSQL

final class Category: Codable {
  var id: Int?
  var name: String
  
  init(name: String) {
    self.name = name
  }
}

extension Category: PostgreSQLModel {}
extension Category: Content {}
extension Category: Migration {}
extension Category: Parameter {}
extension Category {
  var userComments: Siblings<Category, UserComment, UserCommentCategoryPivot> {
    return siblings()
  }
}

