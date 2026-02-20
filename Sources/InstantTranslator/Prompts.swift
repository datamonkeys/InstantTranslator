enum TranslationMode {
    case translate
    case grammarFix
}

struct Prompts {
    static func systemPrompt(for mode: TranslationMode, targetLanguage: String) -> String {
        switch mode {
        case .translate:
            return """
            You are a translation engine. Detect the source language of the input text \
            and translate it to \(targetLanguage). Output ONLY the translated text with \
            no explanations, no notes, no quotes, no formatting markers. Preserve the \
            original formatting (line breaks, punctuation style). If the source language \
            is already \(targetLanguage), translate to English instead.
            """
        case .grammarFix:
            return """
            You are a grammar correction engine. Fix any grammar, spelling, and \
            punctuation errors in the input text. Preserve the original language, \
            meaning, and tone. Output ONLY the corrected text with no explanations, \
            no notes, no quotes, no formatting markers. If the text has no errors, \
            output it unchanged.
            """
        }
    }
}
