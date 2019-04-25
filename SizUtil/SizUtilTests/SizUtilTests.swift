//
//  SizUtilTests.swift
//  SizUtilTests
//
//  Created by IL KYOUNG HWANG on 2019/04/01.
//  Copyright © 2019 Sizuha. All rights reserved.
//

import XCTest
@testable import SizUtil

class SizUtilTests: XCTestCase {

    override func setUp() {
        // Put setup code here. This method is called before the invocation of each test method in the class.
    }

    override func tearDown() {
        // Put teardown code here. This method is called after the invocation of each test method in the class.
    }

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

//    func testPerformanceExample() {
//        // This is an example of a performance test case.
//        self.measure {
//            // Put the code you want to measure the time of here.
//        }
//    }

}
