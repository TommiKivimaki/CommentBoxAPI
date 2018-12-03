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
  
  
  func testUserCommentsCanBeRetrievedFromAPI() throws {
    let comment1 = try UserComment.create(timestamp: timestamp, comment: comment, user: nil, on: conn)
    _ = try UserComment.create(on: conn)
    
    let comments = try app.getResponse(to: commentsURI, decodeTo: [UserComment].self)
    
    XCTAssertEqual(comments.count, 2)
    XCTAssertEqual(comments[0].timestamp, timestamp)
    XCTAssertEqual(comments[0].comment, comment)
    XCTAssertEqual(comments[0].id, comment1.id)
    
    let user = try User.create(on: conn)
    let comment2 = try UserComment.create(timestamp: "Kello neljä", comment: "Luken eka", user: user, on: conn)
    let comment3 = try UserComment.create(timestamp: "Kello neljä", comment: "Luken toka", user: user, on: conn)
    
    XCTAssertEqual(comment2.userID, comment3.userID)
  }
  
  
  func testUserCommentCanBeSavedWithAPI() throws {
    let user = try User.create(on: conn)
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
    XCTAssertEqual(userComments[0].id, receivedUserComment.id)
  }
  
  func testGettingASingleCommentFromTheAPI() throws {
    let comment = try UserComment.create(timestamp: "Yömyöhään", comment: "Test getting a single comment", user: nil, on: conn)
    let receivedComment = try app.getResponse(to: "\(commentsURI)/\(comment.id!)", decodeTo: UserComment.self)
    
    XCTAssertEqual(comment.comment, receivedComment.comment)
  }
  
  
  func testUpdatingAComment() throws {
    let comment = try UserComment.create(timestamp: "Yöllä", comment: "eka versio", user: nil, on: conn)
    let user = try User.create(on: conn)
    
    let returnedOriginalComment = try app.getResponse(to: "\(commentsURI)/\(comment.id!)", decodeTo: UserComment.self)
    
    XCTAssertEqual(comment.comment, returnedOriginalComment.comment)
    
    let updatedComment = UserComment(timestamp: "Yöllä edelleen", userComment: "Päivitetty kommentti", userID: user.id!)
    
    try app.sendRequest(to: "\(commentsURI)/\(comment.id!)", method: .PUT, headers: ["Content-Type": "application/json"], data: updatedComment, loggedInRequest: false, loggedInUser: user)
    let returnedComment = try app.getResponse(to: "\(commentsURI)/\(comment.id!)", decodeTo: UserComment.self)
    
    XCTAssertEqual(returnedComment.comment, updatedComment.comment)
    XCTAssertEqual(returnedComment.timestamp, updatedComment.timestamp)
    XCTAssertEqual(returnedComment.userID, user.id)
  }
  
  
  func testDeletingAComment() throws {
    let comment = try UserComment.create(on: conn)
    var returnedComments = try app.getResponse(to: commentsURI, decodeTo: [UserComment].self)
    
    XCTAssertEqual(returnedComments.count, 1)
    
    _ = try app.sendRequest(to: "\(commentsURI)/\(comment.id!)", method: .DELETE, headers: ["Content-Type": "application/json"], loggedInRequest: true, loggedInUser: nil)
    
    returnedComments = try app.getResponse(to: commentsURI, decodeTo: [UserComment].self)
    
    XCTAssertEqual(returnedComments.count, 0)
  }
  
  
  func testSearchCommentComment() throws {
    let comment = try UserComment.create(on: conn)
    let returnedComments = try app.getResponse(to: "\(commentsURI)/search?term=test+comment", decodeTo: [UserComment].self)
    
    XCTAssertEqual(returnedComments.count, 1)
    XCTAssertEqual(returnedComments[0].comment, comment.comment)
    XCTAssertEqual(returnedComments[0].timestamp, comment.timestamp)
    XCTAssertEqual(returnedComments[0].id!, comment.id!)
  }
  
  
  func testSearchCommentTimestamp() throws {
    let comment = try UserComment.create(on: conn)
    let returnedComments = try app.getResponse(to: "\(commentsURI)/searchor?term=No+time", decodeTo: [UserComment].self)
    
    XCTAssertEqual(returnedComments.count, 1)
    XCTAssertEqual(returnedComments[0].comment, comment.comment)
    XCTAssertEqual(returnedComments[0].timestamp, comment.timestamp)
    XCTAssertEqual(returnedComments[0].id!, comment.id!)
  }
  
  
  func testGetFirstComment() throws {
    let comment = try UserComment.create(timestamp: "Ihan just", comment: "Eka kommentti", user: nil, on: conn)
    _ = try UserComment.create(on: conn)
    _ = try UserComment.create(on: conn)
    let returnedComments = try app.getResponse(to: "\(commentsURI)/first", decodeTo: UserComment.self)
    
    XCTAssertEqual(returnedComments.comment, comment.comment)
    XCTAssertEqual(returnedComments.timestamp, comment.timestamp)
    XCTAssertEqual(returnedComments.id!, comment.id!)
  }
  
  
  func testGetSortedComments() throws {
    let user = try User.create(on: conn)
    let comment1 = try UserComment.create(timestamp: "aika", comment: "aaa", user: user, on: conn)
    let comment2 = try UserComment.create(timestamp: "aika", comment: "ccc", user: user, on: conn)
    let comment3 = try UserComment.create(timestamp: "aika", comment: "bbb", user: user, on: conn)
    
    let returnedComments = try app.getResponse(to: "\(commentsURI)/sorted", decodeTo: [UserComment].self)

    XCTAssertEqual(returnedComments.count, 3)
    XCTAssertEqual(returnedComments[0].comment, comment1.comment)
    XCTAssertEqual(returnedComments[1].comment, comment3.comment)
    XCTAssertEqual(returnedComments[2].comment, comment2.comment)
  }
  

  func testGetCommentsUser() throws {
    let user = try User.create(on: conn)
    let comment = try UserComment.create(timestamp: "Ilta taas", comment: "Testing getting the user of this comment", user: user, on: conn)
    
    let returnedUser = try app.getResponse(to: "\(commentsURI)/\(comment.id!)/user", decodeTo: User.Public.self)
    
    XCTAssertEqual(user.id, returnedUser.id)
    XCTAssertEqual(user.name, returnedUser.name)
    XCTAssertEqual(user.username, returnedUser.username)
  }
  
  
  func testGetCommentsCategories() throws {
    let comment = try UserComment.create(on: conn)
    let category1 = try Category.create(name: "First test category", on: conn)
    let category2 = try Category.create(name: "Second test category", on: conn)
    
    _ = try app.sendRequest(to: "\(commentsURI)/\(comment.id!)/categories/\(category1.id!)", method: .POST, loggedInRequest: true)
    _ = try app.sendRequest(to: "\(commentsURI)/\(comment.id!)/categories/\(category2.id!)", method: .POST, loggedInRequest: true)
    
    let categories = try app.getResponse(to: "\(commentsURI)/\(comment.id!)/categories", decodeTo: [App.Category].self)
    
    XCTAssertEqual(categories.count, 2)
    XCTAssertEqual(categories[0].name, category1.name)
    XCTAssertEqual(categories[0].id, category1.id)
    XCTAssertEqual(categories[1].name, category2.name)
    XCTAssertEqual(categories[1].id, category2.id)
  }
  
  
  func testRemoveCommentsCategories() throws {
    let comment = try UserComment.create(on: conn)
    let category1 = try Category.create(name: "First test category", on: conn)
    let category2 = try Category.create(name: "Second test category", on: conn)
    
    _ = try app.sendRequest(to: "\(commentsURI)/\(comment.id!)/categories/\(category1.id!)", method: .POST, loggedInRequest: true)
    _ = try app.sendRequest(to: "\(commentsURI)/\(comment.id!)/categories/\(category2.id!)", method: .POST, loggedInRequest: true)
    
    var categories = try app.getResponse(to: "\(commentsURI)/\(comment.id!)/categories", decodeTo: [App.Category].self)
    
    XCTAssertEqual(categories.count, 2)
    XCTAssertEqual(categories[0].name, category1.name)
    XCTAssertEqual(categories[0].id, category1.id)
    XCTAssertEqual(categories[1].name, category2.name)
    XCTAssertEqual(categories[1].id, category2.id)
    
    _ = try app.sendRequest(to: "\(commentsURI)/\(comment.id!)/categories/\(category1.id!)", method: .DELETE, loggedInRequest: true)
    
    categories = try app.getResponse(to: "\(commentsURI)/\(comment.id!)/categories", decodeTo: [App.Category].self)
    
    XCTAssertEqual(categories.count, 1)
    XCTAssertEqual(categories[0].name, category2.name)
    XCTAssertEqual(categories[0].id, category2.id)
    
  }
  
  static let allTests = [
    ("testUserCommentsCanBeRetrievedFromAPI", testUserCommentsCanBeRetrievedFromAPI),
    ("testUserCommentCanBeSavedWithAPI", testUserCommentCanBeSavedWithAPI),
    ("testUpdatingAComment", testUpdatingAComment),
    ("testDeletingAComment", testDeletingAComment),
    ("testSearchCommentComment", testSearchCommentComment),
    ("testSearchCommentTimestamp", testSearchCommentTimestamp),
    ("testGetFirstComment", testGetFirstComment),
    ("testGetSortedComments", testGetSortedComments),
    ("testGetCommentsUser", testGetCommentsUser),
    ("testGetCommentsCategories", testGetCommentsCategories),
    ("testRemoveCommentsCategories", testRemoveCommentsCategories)
  ]
}

