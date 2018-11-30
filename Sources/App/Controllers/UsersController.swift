import Vapor
import Crypto

struct UsersController: RouteCollection {
  
  func boot(router: Router) throws {
    let usersRoute = router.grouped("api", "users")
    usersRoute.get(use: getAllHandler)
    usersRoute.get(User.parameter, use: getHandler)
    usersRoute.get(User.parameter, "comments", use: getCommentsHandler)
    
    let basicAuthMiddleware = User.basicAuthMiddleware(using: BCryptDigest())
    let basicAuthGroup = usersRoute.grouped(basicAuthMiddleware)
    basicAuthGroup.post("login", use: loginHandler)
    
    let tokenAuthMiddleware = User.tokenAuthMiddleware()
    let guardAuthMiddleware = User.guardAuthMiddleware()
    let tokenAuthGroup = usersRoute.grouped(tokenAuthMiddleware, guardAuthMiddleware)
    tokenAuthGroup.post(User.self, use: createHandler)
  }
  
  func createHandler(_ req: Request, user: User) throws -> Future<User.Public> {
    user.password = try BCrypt.hash(user.password)  // hash the password before saving
    return user.save(on: req).convertToPublic()
  }
  
  /// Get all users
  func getAllHandler(_ req: Request) throws -> Future<[User.Public]> {
    return User.query(on: req).decode(data: User.Public.self).all()
  }
  
  /// Get a specific user
  func getHandler(_ req: Request) throws -> Future<User.Public> {
    return try req.parameters.next(User.self).convertToPublic()
  }
  
  /// Get all the comments of a user
  func getCommentsHandler(_ req: Request) throws -> Future<[UserComment]> {
    return try req.parameters.next(User.self)
      .flatMap(to: [UserComment].self) { user in
        try user.userComments.query(on: req).all()
    }
  }
  
  func loginHandler(_ req: Request) throws -> Future<Token> {
    let user = try req.requireAuthenticated(User.self)
    let token = try Token.generate(for: user)
    return token.save(on: req)
  }
  
}
