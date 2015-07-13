//
//  Regex.swift
//  macme
//
//  Created by Vincent Pacelli on 7/9/15.
//  Copyright (c) 2015 tnecniv. All rights reserved.
//

import Foundation

// Thanks: http://benscheirman.com/2014/06/regex-in-swift/

class Regex {
    var internalExpression: NSRegularExpression
    var pattern: String
    var captureGroups: [String] = [String]()
    var error: NSError?
    
    init(_ pattern: String) {
        self.pattern = pattern
        self.internalExpression = NSRegularExpression(pattern: pattern, options: .CaseInsensitive, error: &error)!
    }
    
    func test(input: String) -> Bool {
        if let match = internalExpression.firstMatchInString(input, options: nil, range:NSMakeRange(0, count(input))) {
            for i in 0...(match.numberOfRanges - 1) {
                let range = match.rangeAtIndex(i)
                let nsinput: NSString = NSString(string: input)
                let sub = nsinput.substringWithRange(range)
                
                captureGroups.append(sub)
            }
            
            return true
        } else {
            return false
        }
    }
}