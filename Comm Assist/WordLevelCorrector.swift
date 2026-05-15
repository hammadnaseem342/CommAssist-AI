import Foundation

final class WordLevelCorrector {
    
    private var currentWord = ""
    private(set) var sentence = ""
    
    // ✅ IMPROVED: Track recent letters to prevent accidental duplicates
    private var recentLetters: [String] = []
    private let recentBuffer = 3
    
    func add(letter: String) {
        // ✅ Prevent immediate letter duplication
        if recentLetters.last == letter {
            return
        }
        
        currentWord += letter
        
        recentLetters.append(letter)
        if recentLetters.count > recentBuffer {
            recentLetters.removeFirst()
        }
    }
    
    func space() {
        if !currentWord.isEmpty {
            sentence += currentWord + " "
            currentWord = ""
            recentLetters.removeAll()
        }
    }
    
    func delete() {
        if !currentWord.isEmpty {
            currentWord.removeLast()
            if recentLetters.last == currentWord.last.map(String.init) {
                recentLetters.removeLast()
            }
        } else if !sentence.isEmpty {
            sentence.removeLast()
        }
    }
    
    func text() -> String {
        return sentence + currentWord
    }
    
    // ✅ NEW: Clear everything
    func clear() {
        currentWord = ""
        sentence = ""
        recentLetters.removeAll()
    }
}
