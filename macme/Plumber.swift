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

enum PlumberLexResult {
    case Definition(String, String)
    case RuleOrAction(String, String, String)
    case Include(String)
    case LexError(String?)
}

enum PlumbResult {
    
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
        var currentRule: PlumberRule = PlumberRule()
        var content: String = NSString(contentsOfFile: path.stringByExpandingTildeInPath, encoding: NSASCIIStringEncoding, error: nil) as! String
        lines = split(content, allowEmptySlices: true, isSeparator: {(c: Character) -> Bool in return c == "\n" })
    }
    
    func lex(line: String) -> PlumberLexResult {
        var first: String = ""
        var second: String = ""
        var rest: String = ""
        var mode: Int = 0;
        var eatWhitespace: Bool = true
        var error: String = ""
        
        for c in Range(start: line.unicodeScalars.startIndex, end: line.unicodeScalars.endIndex) {
            switch mode {
            case 0:
                if NSCharacterSet.whitespaceCharacterSet().longCharacterIsMember(line.unicodeScalars[c].value) {
                    if eatWhitespace {
                        continue
                    } else {
                        eatWhitespace = true
                        mode = 1;
                    }
                } else if line.unicodeScalars[c] == "=" {
                    var value: String = ""
                    
                    for x in Range(start: c.successor(), end: line.unicodeScalars.endIndex) {
                        value.append(line.unicodeScalars[x])
                    }
                    
                    return .Definition(first, value.stringByTrimmingCharactersInSet(NSCharacterSet.whitespaceCharacterSet()))
                } else {
                    eatWhitespace = false
                    first.append(line.unicodeScalars[c])
                }
            case 1:
                if NSCharacterSet.whitespaceCharacterSet().longCharacterIsMember(line.unicodeScalars[c].value) {
                    if eatWhitespace {
                        continue
                    } else {
                        eatWhitespace = true
                        mode = 2
                    }
                } else {
                    eatWhitespace = false
                    second.append(line.unicodeScalars[c])
                }
            case 2:
                rest.append(line.unicodeScalars[c])
            default:
                return .LexError(error)
            }
        }
        
        if first == "" || second == "" {
            return .LexError("Line incomplete")
        } else if first == "include" {
            return .Include(second + rest)
        } else if rest == "" {
            return .LexError("Expected argument")
        } else {
            return .RuleOrAction(first, second, rest)
        }
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
                } else if singleQuote {
                    ret.append(c)
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
                        ret += "" // Shell doesnt error on undefs, they are just empty
                    }
                } else {
                    ret.append(c)
                }
            }
        }
        
        if (variable) {
            if let val = defs[variableName] {
                ret += val
            } else {
                
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
                if line.stringByTrimmingCharactersInSet(NSCharacterSet.whitespaceAndNewlineCharacterSet()) == "" {
                    skipRule = false
                }
                
                continue
            } else {
                if let equals = line.rangeOfString("=") {
                    
                }
            }

            var words = split(line, allowEmptySlices: true, isSeparator: {(c: Character) -> Bool in return c == " " })
            words[2] = evalArg(words[2], defs: defs)
            
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
                    exists = fileMgr.fileExistsAtPath(dir.stringByExpandingTildeInPath, isDirectory: &isDir)
                } else {
                    exists = fileMgr.fileExistsAtPath(words[2] + "/" + dir.stringByExpandingTildeInPath, isDirectory: &isDir)
                }
                
                skipRule = !(exists && isDir)
                
                if !skipRule {
                    defs["$dir"] = words[2]
                }
            } else if words[1] == "isfile" {
                var file: String = ""
                var exists: Bool = false
                var isDir: ObjCBool = false
                
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
                    exists = fileMgr.fileExistsAtPath(file.stringByExpandingTildeInPath, isDirectory: &isDir)
                } else {
                    exists = fileMgr.fileExistsAtPath(words[2] + "/" + file.stringByExpandingTildeInPath, isDirectory: &isDir)
                }
                
                skipRule = !(exists && !isDir)
                
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
