@testable import App
import Vapor
import XCTest
import FluentPostgreSQL

final class UserCommentTests: XCTestCase {
  
  let commentsURI = "/api/comments/"
  let comment = "OMG Testing"
  let timestamp = "Melekein keskiyöllä"
  var app: Application!
  var conn: PostgreSQLConnection!
  
  override func setUp() {
    try! Application.reset()
    app = try! Application.testable()
    conn = try! app.newConnection(to: .psql).wait()
  }
  
  override func tearDown() {
    conn.close()
    try? app.syncShutdownGracefully()
  }
  
  func testUserCommentCanBeSavedWithAPI() throws {
    let user = try User.create(on: conn)
//    let user = try User.create(name: "Luke", username: "luke", on: conn)
    let userComment = UserComment(timestamp: timestamp, userComment: comment, userID: user.id!)
    let receivedUserComment = try app.getResponse(to: commentsURI, method: .POST,
                                                  headers: ["Content-Type": "application/json"],
                                                  data: userComment,
                                                  decodeTo: UserComment.self,
                                                  loggedInRequest: true)
    
    XCTAssertEqual(receivedUserComment.comment, userComment.comment)
    XCTAssertEqual(receivedUserComment.timestamp, userComment.timestamp)
    XCTAssertNotNil(receivedUserComment.id)

    let userComments = try app.getResponse(to: commentsURI, decodeTo: [UserComment].self)
    
    XCTAssertEqual(userComments.count, 1)
    XCTAssertEqual(userComments[0].comment, userComment.comment)
    XCTAssertEqual(userComments[0].timestamp, userComment.timestamp)
    XCTAssertEqual(userComments[0].id, userComment.id)
  }
  
  
  
  static let allTests = [
    ("testUserCommentCanBeSavedWithAPI", testUserCommentCanBeSavedWithAPI)
  ]
}

