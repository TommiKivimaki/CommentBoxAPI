import Vapor

struct UsersController: RouteCollection {
  
  func boot(router: Router) throws {
    let usersRoute = router.grouped("api", "users")
    
    usersRoute.post(User.self, use: createHandler)
    usersRoute.get(use: getAllHandler)
    usersRoute.get(User.parameter, use: getHandler)
  }
  
  func createHandler(_ req: Request, user: User) throws -> Future<User> {
    return user.save(on: req)
  }
  
  /// Get all users
  func getAllHandler(_ req: Request) throws -> Future<[User]> {
    return User.query(on: req).all()
  }
  
  /// Get a specific user
  func getHandler(_ req: Request) throws -> Future<User> {
    return try req.parameters.next(User.self)
  }
  
}
