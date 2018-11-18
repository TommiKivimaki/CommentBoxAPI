import FluentPostgreSQL
import Foundation

final class UserCommentCategoryPivot: PostgreSQLUUIDPivot, ModifiablePivot {
  var id: UUID?  // Foundation imported so UUID can be used
  var userCommentID: UserComment.ID
  var categoryID: Category.ID
  
  typealias Left = UserComment
  typealias Right = Category
  
  static let leftIDKey: LeftIDKey = \.userCommentID
  static let rightIDKey: RightIDKey = \.categoryID
  
  init(_ userComment: UserComment, _ category: Category) throws {
    self.userCommentID = try userComment.requireID()
    self.categoryID = try category.requireID()
  }
  
}

// Conform to Migration so that Fluent can setup a table
// Add reference between userCommentID on UserCommentCategoryPivot and the id property on UserComment
// Add similar reference to categoryID and id property on Category
// This sets up foreign key constraint. .cascade sets cascade schema reference action when we delete a userComment
// This means that the relationship is removed automatically instead of throwing an error
// :: Wihtout this deleting a userComment will delete the comment but the relationship will remain between the deleted comment and category
extension UserCommentCategoryPivot: Migration {
  static func prepare(on connection: PostgreSQLConnection) -> Future<Void> {
    return Database.create(self, on: connection) { builder in
      try addProperties(to: builder)
      builder.reference(from: \.userCommentID, to: \UserComment.id, onDelete: .cascade)
      builder.reference(from: \.categoryID, to: \Category.id, onDelete: .cascade)
    }
  }
}
