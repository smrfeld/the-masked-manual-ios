import UIKit

var a : String
var comps : [String]

a = "hello world"
comps = a.components(separatedBy: " ")
print(comps)

a = "hello wor-ld"
comps = a.components(separatedBy: " ")
print(comps)

a = "hello wor-ld"
comps = a.components(separatedBy: [" ","-"])
print(comps)
