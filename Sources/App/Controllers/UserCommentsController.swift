import Vapor
import Fluent
import Authentication

struct UserCommentsController: RouteCollection {
  
  // Register routes when the controller boots
  func boot(router: Router) throws {
    
    router.get("hello", use: getHelloHandler)
    
    // Create a group for /api/comments/ path to make maintenance easier
    let userCommentsRoutes = router.grouped("api", "comments")
    userCommentsRoutes.get(use: getAllHandler)
    userCommentsRoutes.get(UserComment.parameter, use: getHandler)
    userCommentsRoutes.get("search", use: searchHandler)
    userCommentsRoutes.get("searchor", use: searchOrHandler)
    userCommentsRoutes.get("first", use: getFirstHandler)
    userCommentsRoutes.get("sorted", use: sortedHandler)
    userCommentsRoutes.get(UserComment.parameter, "user", use: getUserHandler)
    userCommentsRoutes.get(UserComment.parameter, "categories", use: getCategoriesHandler)
    
    let tokenAuthMiddleware = User.tokenAuthMiddleware()
    let guardAuthMiddleware = User.guardAuthMiddleware()
    let tokenAuthGroup = userCommentsRoutes.grouped(tokenAuthMiddleware, guardAuthMiddleware)
    tokenAuthGroup.post(UserCommentCreateData.self, use: createHandler)
    tokenAuthGroup.post(UserComment.parameter, "categories", Category.parameter, use: addCategoriesHandler)
    tokenAuthGroup.put(UserComment.parameter, use: updateHandler)
    tokenAuthGroup.delete(UserComment.parameter, use: deleteHandler)
    tokenAuthGroup.delete(UserComment.parameter, "categories", Category.parameter, use: removeCategoriesHandler)
  }
  
  /// Returns "Hello"
  func getHelloHandler(_ req: Request) -> String {
    return "Hello! I'm the API who runs Comment Box"
  }
  
  /// GETs all comments
  func getAllHandler(_ req: Request) throws -> Future<[UserComment]> {
    return UserComment.query(on: req).all()
  }
  
  /// Creates a new comment (POST)
  func createHandler(_ req: Request, data: UserCommentCreateData) throws -> Future<UserComment> {
    let user = try req.requireAuthenticated(User.self)
    let userComment = try UserComment(timestamp: data.timestamp, userComment: data.comment, userID: user.requireID())
    return userComment.save(on: req)
  }
  
  /// GETs a single comment
  func getHandler(_ req: Request) throws -> Future<UserComment> {
    return try req.parameters.next(UserComment.self)
  }
  
  /// Updates row with PUT
  func updateHandler(_ req: Request) throws -> Future<UserComment> {
    return try flatMap(to: UserComment.self,
                       req.parameters.next(UserComment.self),
                       req.content.decode(UserCommentCreateData.self)) { userComment, updateData in
                        
                        userComment.timestamp = updateData.timestamp ?? ""
                        userComment.comment = updateData.comment
                        let user = try req.requireAuthenticated(User.self)
                        userComment.userID = try user.requireID()
                        return userComment.save(on: req)
    }
  }
  
  /// DELETEs a row
  func deleteHandler(_ req: Request) throws -> Future<HTTPStatus> {
    return try req.parameters.next(UserComment.self)
      .delete(on: req)
      .transform(to: HTTPStatus.noContent)
  }
  
  /// Searches a comment
  func searchHandler(_ req: Request) throws -> Future<[UserComment]> {
    guard let searchTerm = req.query[String.self, at: "term"] else { throw Abort(.badRequest) }
    
    return UserComment.query(on: req)
      .filter(\.comment == searchTerm)
      .all()
  }
  
  /// Searches comment and timestamp fields
  func searchOrHandler(_ req: Request) throws -> Future<[UserComment]> {
    guard let searchTerm = req.query[String.self, at: "term"] else { throw Abort(.badRequest) }
    
    return UserComment.query(on: req).group(.or) { or in      // Creates a group with OR relation
      or.filter(\.comment == searchTerm)                      // Adds a filter to the group
      or.filter(\.timestamp == searchTerm)                    // Adds another filter to the group
      }.all()
  }
  
  /// GETs first
  func getFirstHandler(_ req: Request) throws -> Future<UserComment> {
    return UserComment.query(on: req)
      .first()
      .map(to: UserComment.self, { comment in
        guard let comment = comment else { throw Abort(.notFound) }
        return comment
      })
  }
  
  /// Returns result in a sorted order
  func sortedHandler(_ req: Request) throws -> Future<[UserComment]> {
    return UserComment.query(on: req)
      .sort(\.comment, .ascending)   // Defines the properties that's the base in sorting
      .all()
  }
  
  /// Get the parent a.k.a user of the comment
  func getUserHandler(_ req: Request) throws -> Future<User.Public> {
    return try req.parameters.next(UserComment.self)
      .flatMap(to: User.Public.self) { userComment in
        userComment.user.get(on: req).convertToPublic()
    }
  }
  
  /// Get categories
  func addCategoriesHandler(_ req: Request) throws -> Future<HTTPStatus> {
    return try flatMap(to: HTTPStatus.self,
                       req.parameters.next(UserComment.self),
                       req.parameters.next(Category.self)) { userComment, category in
                        return userComment.categories
                          .attach(category, on: req)
                          .transform(to: .created)
    }
  }
  
  /// Query sibling relationship
  func getCategoriesHandler(_ req: Request) throws -> Future<[Category]> {
    return try req.parameters.next(UserComment.self)
      .flatMap(to: [Category].self) { userComment in
        try userComment.categories.query(on: req).all()
    }
  }
  
  // Remove the sibling relationship
  func removeCategoriesHandler(_ req: Request) throws -> Future<HTTPStatus> {
    return try flatMap(to: HTTPStatus.self,
                       req.parameters.next(UserComment.self),
                       req.parameters.next(Category.self)) { userComment, category in
                        return userComment.categories
                          .detach(category, on: req)
                          .transform(to: .noContent)
    }
  }
  
}

// Defines the request data user has to send to create a comment.
struct UserCommentCreateData: Content {
  let comment: String
  let timestamp: String?
}
