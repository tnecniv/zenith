import Cocoa

var error: NSError?
var captureGroups: [String] = []
var input = "http://www.google.com"

var pattern = "(https?|ftp|file|gopher|mailto|news|nntp|telnet|wais)://[a-zA-Z0-9_@]+([.:][a-zA-Z0-9_@]+)*/?[a-zA-Z0-9_?,%#~&/\\-]+([:.][a-zA-Z0-9_?,%#~&/\\-]+)*"

var internalExpression = NSRegularExpression(pattern: pattern, options: .CaseInsensitive, error: &error)!

if let match = internalExpression.firstMatchInString(input, options: nil, range: NSMakeRange(0, count(input))) {
    
    match.numberOfRanges
    match.rangeAtIndex(0)
    match.rangeAtIndex(1)
    match.rangeAtIndex(2)
}
