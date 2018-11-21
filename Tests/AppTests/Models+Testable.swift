@testable import App
import FluentPostgreSQL

extension User {
  static func create(name: String = "Luke", username: String = "lukes", on connection: PostgreSQLConnection) throws -> User {
    
    let user = User(name: name, username: username)
    return try user.save(on: connection).wait()
  }
}

extension UserComment {
  static func create(comment: String = "test comment", user: User? = nil, on connection: PostgreSQLConnection ) throws -> UserComment {
    
    var userCommentsUser = user
    if userCommentsUser == nil {
      userCommentsUser = try User.create(on: connection)
    }
    
    let userComment = UserComment(timestamp: "Maanantaina, Valmetilla", userComment: "Testikommentti", userID: userCommentsUser!.id!)
    
    return try userComment.save(on: connection).wait()
  }
}

// Simplify creating categories to database
extension App.Category {
  static func create(name: String = "Random", on connection: PostgreSQLConnection) throws -> App.Category {
    
    let category = Category(name: name)
    return try category.save(on: connection).wait()
  }
}
