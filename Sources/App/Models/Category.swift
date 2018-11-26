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
  
  static func addCategory(_ name: String, to userComment: UserComment, on req: Request) throws -> Future<Void> {
    return Category.query(on: req)
      .filter(\.name == name)
      .first()
      .flatMap(to: Void.self) { foundCategory in
        if let existingCategory = foundCategory {
          return userComment.categories
            .attach(existingCategory, on: req)
            .transform(to: ())
        } else {
          let category = Category(name: name)
          return category.save(on: req)
            .flatMap(to: Void.self) { savedCategory in
              return userComment.categories
                .attach(savedCategory, on: req)
                .transform(to: ())
          }
        }
    }
  }
}

