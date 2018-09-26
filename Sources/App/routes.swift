import Vapor

/// Register your application's routes here.
public func routes(_ router: Router) throws {
    router.get("hello") { req in
        return "Hello! I'm running the API for the Comment Box"
    }

  router.post("api", "comments") { req -> Future<UserComment> in
    return try req.content.decode(UserComment.self).flatMap(to: UserComment.self, { comment in
      return comment.save(on: req)
    })
  }

  router.get("api", "comments") { req -> Future<[UserComment]> in
    return UserComment.query(on: req).all()
  }
}
