import Foundation

let url = URL(fileURLWithPath: CommandLine.arguments[1])
let data = try url.bookmarkData(options: [], includingResourceValuesForKeys: nil, relativeTo: nil)
FileHandle.standardOutput.write(data)
