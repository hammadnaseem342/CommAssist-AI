final class WordCorrector {
    
    private let dictionary: Set<String> = [
        "HELLO","YES","NO","THANK","YOU","PLEASE","HELP"
    ]
    
    func correct(_ sentence: String) -> String {
        let words = sentence.split(separator: " ")
        
        return words.map { word in
            let w = word.uppercased()
            return dictionary.contains(w) ? w : w
        }.joined(separator: " ")
    }
}
