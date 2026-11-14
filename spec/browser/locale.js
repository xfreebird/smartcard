// Runs before page scripts; native callers substitute a supported app language.
(() => {
    const language = "__APP_LANGUAGE__";
    if (!["ro", "en", "ru"].includes(language)) return false;
    // Sites that use browser language should see the same preference as the app.
    try {
        Object.defineProperty(navigator, "language", {get: () => language, configurable: true});
        Object.defineProperty(navigator, "languages", {get: () => [language], configurable: true});
    } catch (_) {}
    // MSign ignores browser language and initializes its Vue store in Romanian.
    // Touch only its own top-level HTTPS origin, preserving other persisted state.
    if (window.top !== window || location.origin !== "https://msign.gov.md") return false;
    try {
        const saved = localStorage.getItem("vuex");
        let state;
        try { state = JSON.parse(saved || "{}"); } catch (_) {}
        if (!state || typeof state !== "object" || Array.isArray(state)) state = {};
        const previous = state.language;
        const languageState = previous && typeof previous === "object" && !Array.isArray(previous)
            ? previous : {};
        if (languageState.culture === language) return false;
        state.language = {...languageState, culture: language};
        localStorage.setItem("vuex", JSON.stringify(state));
        return true; // Older Android WebViews can reload once after initializing storage.
    } catch (_) { return false; } // Storage can be disabled; never block navigation.
})();
