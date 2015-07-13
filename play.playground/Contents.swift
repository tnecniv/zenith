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

//
//  Plumber.swift
//  macme
//
//  Created by Vincent Pacelli on 7/5/15.
//  Copyright (c) 2015 tnecniv. All rights reserved.
//

import Cocoa
import Foundation

struct PlumberMessage {
    var src: String = ""
    var dst: String = ""
    var wdir: String = ""
    var type: String = ""
    var attr: Dictionary<String, String> = Dictionary()
    var data: [UInt8] = []
}

struct PlumberRule {
    var reqs: [(PlumberMessage) -> Bool] = []
    var actions: [() -> Bool] = []
}

class Plumber {
    var rules: [PlumberRule] = []
    var plumbFileContent: String = "";
    var lines: [String] = []
    var fileMgr: NSFileManager = NSFileManager()
    var lastCaptureGroup: Int = 0
    
    init() {
    }
    
    init(path: String) {
        loadFile(path)
    }
    
    func loadFile(path: String) {
        var error: NSError?
        var content: String = NSString(contentsOfFile: path, encoding: NSASCIIStringEncoding, error: nil) as! String
        print(content)
        lines = split(content, allowEmptySlices: true, isSeparator: {(c: Character) -> Bool in return c == "\n" })
    }
    
    func evalArg(s: String, defs: Dictionary<String, String>) -> String {
        var singleQuote: Bool = false
        var doubleQuote: Bool = false
        var variable: Bool = false
        var escape: Bool = false
        var ret: String = ""
        var variableName: String = ""
        var alphanum = NSCharacterSet.alphanumericCharacterSet();
        
        for c in s.unicodeScalars {
            if c == "'" {
                if doubleQuote {
                    ret.append(c)
                } else if escape {
                    ret.append(c)
                    escape = false
                } else {
                    singleQuote = !singleQuote
                }
            } else if c == "\"" {
                if singleQuote {
                    ret.append(c)
                } else if escape {
                    ret.append(c)
                    escape = false
                } else {
                    doubleQuote = !doubleQuote
                }
            } else if c == "\\" {
                if escape {
                    ret.append(c)
                    escape = false
                } else {
                    escape = true
                }
            } else if c == "$" {
                if escape {
                    ret.append(c)
                } else if singleQuote {
                    ret.append(c)
                } else if variable {
                    if let val = defs[variableName] {
                        ret += val
                    } else {
                        
                    }
                    
                    variableName = String(c);
                } else {
                    variable = true;
                    variableName = String(c);
                }
            } else {
                if variable && alphanum.longCharacterIsMember(c.value) {
                    variableName.append(c)
                } else if variable && !alphanum.longCharacterIsMember(c.value) {
                    variable = false
                    
                    if let val = defs[variableName] {
                        ret += val
                    } else {
                        
                    }
                } else {
                    ret.append(c)
                }
            }
        }
        
        return ret;
    }
    
    func plumb(message: PlumberMessage) {
        var defs: Dictionary<String, String> = Dictionary<String, String>()
        var badParse: Bool = false
        var skipRule: Bool = false
        var msg = message
        
        for line in lines {
            if skipRule {
                continue
            }
            
            //var words: [String] = split(line, allowEmptySlices: true, isSeparator: {(c: Character) -> Bool in NSCharacterSet.whitespaceCharacterSet().characterIsMember(c) })
            var words = split(line, allowEmptySlices: true, isSeparator: {(c: Character) -> Bool in return c == " " })
            
            /*if words[2][words[2].startIndex] == "$" {
            if let w = defs[words[2]] {
            words[2] = w
            } else {
            
            }
            }*/
            
            if words[1] == "is" {
                if words[0] == "src" {
                    skipRule = !(msg.src == words[2])
                } else if words[0] == "dst" {
                    skipRule = !(msg.dst == words[2])
                } else if words[0] == "wdir" {
                    skipRule = !(msg.wdir == words[2])
                } else if words[0] == "type" {
                    skipRule = !(msg.type == words[2])
                } else if words[0] == "ndata" {
                    skipRule = !(count(msg.data) == words[2].toInt())
                } else if words[0] == "data" {
                    skipRule = !(msg.data == ([UInt8](words[2].utf8)))
                } else {
                    
                }
            } else if words[1] == "isdir" {
                var isDir: ObjCBool = false
                var dir: String = ""
                var exists: Bool = false
                
                if words[0] == "src" {
                    dir = msg.src
                } else if words[0] == "dst" {
                    dir = msg.dst
                } else if words[0] == "wdir" {
                    dir = msg.wdir
                } else if words[0] == "type" {
                    dir = msg.type
                } else if words[0] == "ndata" {
                    dir = String(count(msg.data))
                } else if words[0] == "data" {
                    dir = NSString(bytes: msg.data, length: count(msg.data), encoding: NSUTF8StringEncoding) as! String
                } else if words[0] == "arg" {
                    dir = words[2]
                } else {
                    
                }
                
                if words[0] == "arg" {
                    exists = fileMgr.fileExistsAtPath(dir, isDirectory: &isDir)
                } else {
                    exists = fileMgr.fileExistsAtPath(words[2] + "/" + dir, isDirectory: &isDir)
                }
                
                skipRule = !(exists && isDir)
                
                if !skipRule {
                    defs["$dir"] = words[2]
                }
            } else if words[1] == "isfile" {
                var file: String = ""
                var exists: Bool = false
                
                if words[0] == "src" {
                    file = msg.src
                } else if words[0] == "dst" {
                    file = msg.dst
                } else if words[0] == "wdir" {
                    file = msg.wdir
                } else if words[0] == "type" {
                    file = msg.type
                } else if words[0] == "ndata" {
                    file = String(count(msg.data))
                } else if words[0] == "data" {
                    file = NSString(bytes: msg.data, length: count(msg.data), encoding: NSUTF8StringEncoding) as! String
                } else if words[0] == "arg" {
                    file = words[2]
                } else {
                    
                }
                
                if words[0] == "arg" {
                    exists = fileMgr.fileExistsAtPath(file)
                } else {
                    exists = fileMgr.fileExistsAtPath(words[2] + "/" + file)
                }
                
                skipRule = !exists
                
                if !skipRule {
                    defs["$file"] = words[2]
                }
            } else if words[1] == "matches" {
                var str: String = ""
                
                if words[0] == "src" {
                    str = msg.src
                } else if words[0] == "dst" {
                    str = msg.dst
                } else if words[0] == "wdir" {
                    str = msg.wdir
                } else if words[0] == "type" {
                    str = msg.type
                } else if words[0] == "ndata" {
                    str = String(count(msg.data))
                } else if words[0] == "data" {
                    str = NSString(bytes: msg.data, length: count(msg.data), encoding: NSUTF8StringEncoding) as! String
                } else {
                    
                }
                
                var r = Regex(words[2])
                
                skipRule = !r.test(str)
                
                if !skipRule {
                    lastCaptureGroup = count(r.captureGroups) - 1
                    
                    for i in 0...lastCaptureGroup {
                        defs["$" + String(i)] = r.captureGroups[i]
                    }
                }
            } else if words[1] == "set" {
                if words[0] == "src" {
                    msg.src = words[2]
                } else if words[0] == "dst" {
                    msg.dst = words[2]
                } else if words[0] == "wdir" {
                    msg.dst = words[2]
                } else if words[0] == "type" {
                    msg.dst = words[2]
                } else if words[0] == "data" {
                    msg.data = [UInt8](words[2].utf8)
                } else {
                    
                }
            }
        }
    }
}


msg.type