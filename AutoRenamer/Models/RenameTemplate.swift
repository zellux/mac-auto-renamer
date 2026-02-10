import Foundation

struct RenameTemplate {
    let templateString: String

    var variableNames: [String] {
        let regex = try! NSRegularExpression(pattern: "\\{([^}]+)\\}")
        let range = NSRange(templateString.startIndex..., in: templateString)
        return regex.matches(in: templateString, range: range).compactMap { match in
            guard let range = Range(match.range(at: 1), in: templateString) else { return nil }
            return String(templateString[range])
        }
    }

    func apply(values: [String: String]) -> String {
        var result = templateString
        for (key, value) in values {
            result = result.replacingOccurrences(of: "{\(key)}", with: value)
        }
        return result
    }
}
