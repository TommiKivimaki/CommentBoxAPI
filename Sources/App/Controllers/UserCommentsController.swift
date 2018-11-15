import Vapor
import Fluent

struct UserCommentsController: RouteCollection {
  
  // Register routes when the controller boots
  func boot(router: Router) throws {
    
    // Create a group for /api/comments/ path to make maintenance easier
    let userCommentsRoutes = router.grouped("api", "comments")
    
    userCommentsRoutes.get(use: getAllHandler)
    userCommentsRoutes.post(UserComment.self, use: createHandler)
    userCommentsRoutes.get(UserComment.parameter, use: getHandler)
    userCommentsRoutes.put(UserComment.parameter, use: updateHandler)
    userCommentsRoutes.delete(UserComment.parameter, use: deleteHandler)
    userCommentsRoutes.get("search", use: searchHandler)
    userCommentsRoutes.get("searchor", use: searchOrHandler)
    userCommentsRoutes.get("first", use: getFirstHandler)
    userCommentsRoutes.get("sorted", use: sortedHandler)
  }
  
  /// GETs all comments
  func getAllHandler(_ req: Request) throws -> Future<[UserComment]> {
    return UserComment.query(on: req).all()
  }
  
  /// Creates a new comment (POST)
  /// - parameters:
  ///     - userComment: Decode parameter for the JSON in the POST request body
  func createHandler(_ req: Request, userComment: UserComment) throws -> Future<UserComment> {
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
                       req.content.decode(UserComment.self)) { userComment, updateUserComment in
                        
                        userComment.timestamp = updateUserComment.timestamp
                        userComment.comment = updateUserComment.comment
                        
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
  
}
