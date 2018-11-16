import Vapor
import Fluent

/// Register your application's routes here.
public func routes(_ router: Router) throws {
  
  // Register controller that will handle the routes
  let userCommentsController = UserCommentsController()
  try router.register(collection: userCommentsController)
  
  /// GET a greeting
//  router.get("hello") { req in
//    return "Hello! I'm running the API for the Comment Box"
//  }
//  
//  /// POST a comment
//  router.post("api", "comments") { req -> Future<UserComment> in
//    return try req.content.decode(UserComment.self).flatMap(to: UserComment.self, { comment in
//      return comment.save(on: req)
//    })
//  }
//  
//  /// GET all comments
////  router.get("api", "comments") { req -> Future<[UserComment]> in
////    return UserComment.query(on: req).all()
////  }
//  
//  /// GET a single comment
//  router.get("api", "comments", UserComment.parameter) { req -> Future<UserComment> in
//    return try req.parameters.next(UserComment.self)
//  }
//  
//  /// PUT an update to a comment
//  router.put("api", "comments", UserComment.parameter) { req -> Future<UserComment> in
//    return try flatMap(to: UserComment.self,
//                       req.parameters.next(UserComment.self),
//                       req.content.decode(UserComment.self)) { userComment, updateUserComment in
//                        
//                        userComment.timestamp = updateUserComment.timestamp
//                        userComment.comment = updateUserComment.comment
//                        
//                        return userComment.save(on: req)
//    }
//  }
//  
//  /// DELETE a row
//  router.delete("api", "comments", UserComment.parameter) { req -> Future<HTTPStatus> in
//    return try req.parameters.next(UserComment.self)
//      .delete(on: req)
//      .transform(to: HTTPStatus.noContent)
//  }
//  
//  /// SEARCHING comment field
//  router.get("api", "comments", "search") { req -> Future<[UserComment]> in
//    guard let searchTerm = req.query[String.self, at: "term"] else { throw Abort(.badRequest) }
//    
//    return UserComment.query(on: req)
//      .filter(\.comment == searchTerm)
//      .all()
//  }
//  
//  /// SEARCHING comment and timestamp fields with OR logic
//  router.get("api", "comments", "searchor") { req -> Future<[UserComment]> in
//    guard let searchTerm = req.query[String.self, at: "term"] else { throw Abort(.badRequest) }
//    
//    return UserComment.query(on: req).group(.or) { or in      // Creates a group with OR relation
//      or.filter(\.comment == searchTerm)                      // Adds a filter to the group
//      or.filter(\.timestamp == searchTerm)                    // Adds another filter to the group
//      }.all()
//  }
//  
//  /// FISRT returns the first found result
//  router.get("api", "comments", "first") { req -> Future<UserComment> in
//    return UserComment.query(on: req)
//      .first()
//      .map(to: UserComment.self, { comment in
//        guard let comment = comment else { throw Abort(.notFound) }
//        return comment
//      })
//  }
//  
//  /// SORT results
//  router.get("api", "comments", "sorted") { req -> Future<[UserComment]> in
//    return UserComment.query(on: req)
//    .sort(\.comment, .ascending)   // Defines the properties that's the base in sorting
//    .all()
//  }
  
  
}
