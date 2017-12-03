import XCTest
import Entity
import RxSwift
import RxBlocking
import RxTest
import Mock
@testable import DataProvider

private enum UserError: Swift.Error {
    case fake
}

private class UserProviderTests: XCTestCase {
    var provider: UserProvider!
    var storage: UserStorageServiceMock!
    var api: UserApiServiceMock!
    
    func testGetUserReturnsValueFromStorageAndDoesNotHitApi() {
        XCTAssertEqual(provider.user, storage.getMock.user)
        storage.getMock.expect(count: .toBeOne)
        api.fetchMock.expect(count: .toBeZero)
    }
    
    func testGetUserReturnsValueFromApiWhenStorageThrowsAnError() {
        storage.getMock.set(.error(UserError.fake))
        XCTAssertEqual(provider.user, api.fetchMock.user)
        storage.getMock.expect(count: .toBeOne)
        api.fetchMock.expect(count: .toBeOne)
    }
    
    func testGetUserReturnsErrorWhenBothStorageAndApiThrowAnError() {
        storage.getMock.set(.error(UserError.fake))
        api.fetchMock.set(.error(UserError.fake))
        XCTAssertNil(provider.user)
        storage.getMock.expect(count: .toBeOne)
        api.fetchMock.expect(count: .toBeOne)
    }
    
    override func setUp() {
        super.setUp()
        storage = UserStorageServiceMock()
        api = UserApiServiceMock()
        provider = UserProvider(storage: storage, api: api)
    }
    
    override func tearDown() {
        super.tearDown()
        storage = nil
        api = nil
        provider = nil
    }
}

private extension UserProvider {
    var user: User? {
        guard let user = try? getUser().toBlocking().single() else {
            return nil
        }
        return user
    }
}

private extension Mock where T == Single<User> {
    var user: User? {
        guard let user = try? value.toBlocking().single() else {
            return nil
        }
        return user
    }
}

private class UserStorageServiceMock: UserStorageService {
    let getMock = Mock(Single<User>.just(User(firstName: "Stored", lastName: "User")))
    func getUser() -> Single<User> { return getMock.execute() }
    
    let setMock = Mock(Completable.empty())
    func setUser(_ user: User) -> Completable { return setMock.execute() }
}

private class UserApiServiceMock: UserApiService {
    let fetchMock = Mock(Single<User>.just(User(firstName: "Api", lastName: "User")))
    func fetchUser() -> Single<User> { return fetchMock.execute() }
}

private func XCTAssertEqual(_ a: User?, _ b: User?, file: StaticString = #file, line: UInt = #line) {
    guard let a = a else {
        XCTFail("Actual user was not returned", file: file, line: line)
        return
    }
    guard let b = b else {
        XCTFail("Expected user was not returned", file: file, line: line)
        return
    }
    
    XCTAssertEqual(a.firstName, b.firstName)
    XCTAssertEqual(a.lastName, b.lastName)
}
