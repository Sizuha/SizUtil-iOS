import XCTest
@testable import SizUtil

final class SizUtilTests: XCTestCase {
    func testYearMonthDay() {
		let src = SizYearMonthDay(2019, 4, 10)
		if let date = src.toDate() {
			print("YearMonthDay to Date:", date)
			
			let cal = Calendar(identifier: .gregorian)
			XCTAssertEqual(cal.component(.year, from: date), 2019)
			XCTAssertEqual(cal.component(.month, from: date), 4)
			XCTAssertEqual(cal.component(.day, from: date), 10)
			XCTAssertEqual(cal.component(.hour, from: date), 0)
			XCTAssertEqual(cal.component(.minute, from: date), 0)
			XCTAssertEqual(cal.component(.second, from: date), 0)
		}
		else {
			XCTAssert(false)
		}
		
		let src2 = SizYearMonthDay(2019, 4, 10)
		XCTAssertEqual(src, src2)
		
		XCTAssertEqual(src2.add(month: -4) , SizYearMonthDay(2018, 12, 10))
	}

	func testRegex() {
		let sample = "123456789"
		XCTAssertTrue((?="[0-9]+") ~= sample)
		XCTAssertTrue(sample ~= (?="[0-9]+"))
		XCTAssertTrue((?="[A-Z]+") ~= sample)
		XCTAssertTrue(sample ~= (?="[A-Z]+"))
	}

    static var allTests = [
        ("testYearMonthDay", testYearMonthDay),
		("testRegex", testRegex),
    ]
}
