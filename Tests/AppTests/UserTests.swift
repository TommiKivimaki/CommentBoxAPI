@testable import App
import Vapor
import XCTest
import FluentPostgreSQL

final class UserTests: XCTestCase {
  
  let usersName = "Alice"
  let usersUserName = "alicea"
  let usersURI = "/api/users"
  var app: Application!
  var conn: PostgreSQLConnection!
  
  override func setUp() {
    try! Application.reset()
    app = try! Application.testable()
    conn = try! app.newConnection(to: .psql).wait()
  }
  
  override func tearDown() {
    conn.close()
  }
  
//  func testHelloEndpoint() throws {
//    let excpectedHello = "Hello! I'm running the API for the Comment Box"
//    let helloURI = "/hello"
//
//    let response = try app.getResponse(to: helloURI, decodeTo: String.self)
//
//    let data = response
//    let data = response.http.body.data!
//    let responseString = String(decoding: data, as: UTF8.self)
//    print(responseString)
    
//    XCTAssertEqual(data, excpectedHello)
    
//  }
  
  
  
  
  func testUsersCanBeRetrievedFromAPI() throws {

    let user = try User.create(name: usersName, username: usersUserName, on: conn)
    _ = try User.create(on: conn) // Use the default name and username defined on create() method
    
    let users = try app.getResponse(to: usersURI, decodeTo: [User].self)
    
    // Check the success
    XCTAssertEqual(users.count, 2)
    XCTAssertEqual(users[0].name, usersName)
    XCTAssertEqual(users[0].username, usersUserName)
    XCTAssertEqual(users[0].id, user.id)

  }

  func testUserCanBeSavedWithAPI() throws {
    let user = User(name: usersName, username: usersUserName)
    
    let receivedUser = try app.getResponse(to: usersURI, method: .POST, headers: ["Content-Type": "application/json"], data: user, decodeTo: User.self)
    
    XCTAssertEqual(user.username, receivedUser.username)
    XCTAssertEqual(user.name, receivedUser.name)
    XCTAssertNotNil(receivedUser.id)
    
    let users = try app.getResponse(to: usersURI, method: .GET, headers: ["Content-Type": "application/json"], decodeTo: [User].self)
    
    XCTAssertEqual(users.count, 1)
    XCTAssertEqual(users[0].name, user.name)
    XCTAssertEqual(users[0].username, user.username)
    XCTAssertEqual(users[0].id, receivedUser.id)
  }
  
  func testGettingASingleUserFromTheAPI() throws {
    let user = try User.create(name: usersName, username: usersUserName, on: conn)
    
    let receivedUser = try app.getResponse(to: "\(usersURI)/\(user.id!)", decodeTo: User.self)
    
    XCTAssertEqual(receivedUser.name, usersName)
    XCTAssertEqual(receivedUser.username, usersUserName)
    XCTAssertEqual(receivedUser.id, user.id)
  }
  
  func testGettingAUsersCommentsFromTheAPI() throws {
    let user = try User.create(name: "Teppo Test User", username: "teppotestuser", on: conn)
    let comment = "Testailen tässä kesken maanantain"
    
    let userComment1 = try UserComment.create(comment: comment, user: user, on: conn)
    let _ = try UserComment.create(comment: "Another comment", user: user, on: conn)
    
    let comments = try app.getResponse(to: "\(usersURI)/\(user.id!)/comments", decodeTo: [UserComment].self)
    
    XCTAssertEqual(comments.count, 2)
    XCTAssertEqual(comments[0].id, userComment1.id)
    XCTAssertEqual(comments[0].comment, userComment1.comment)
  }
  
  static let allTests = [
    ("testUsersCanBeRetrievedFromAPI", testUsersCanBeRetrievedFromAPI),
    ("testUserCanBeSavedWithAPI", testUserCanBeSavedWithAPI),
    ("testGettingASingleUserFromTheAPI", testGettingASingleUserFromTheAPI),
    ("testGettingAUsersCommentsFromTheAPI", testGettingAUsersCommentsFromTheAPI)
  ]
}
