import AVFoundation

final class SpeechManager {

    // Shared synthesiser — creating a new one every call caused audio glitches
    private static let synth = AVSpeechSynthesizer()
    private static var lastWord = ""

    func speak(word: String) {
        guard !word.isEmpty, word != SpeechManager.lastWord else { return }
        SpeechManager.lastWord = word

        let utterance      = AVSpeechUtterance(string: word)
        utterance.rate     = 0.48
        utterance.volume   = 1.0
        utterance.pitchMultiplier = 1.1

        SpeechManager.synth.speak(utterance)
    }
}
