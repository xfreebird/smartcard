namespace MoldSign.Core;

/// <summary>
/// The one glance that answers "can I sign?" (docs/10 §0.1, UX-01). Same semantics on every platform; the light is
/// never the only signal, the UI always shows the matching text too.
/// </summary>
public enum StatusLight
{
    /// <summary>No dot, glyph dimmed: nothing connected. "Conectează cititorul".</summary>
    Idle,
    /// <summary>Amber: reader(s) connected, no card, or a card being read. "Cititor conectat · introdu cardul".</summary>
    Reader,
    /// <summary>Green: the selected card was read and can sign. "Card pregătit · {holder}".</summary>
    Ready,
    /// <summary>Blue: signing or a bridge request in progress. "Se semnează…".</summary>
    Busy,
    /// <summary>Red: mute or stuck card, PIN blocked. The error's one-line recovery.</summary>
    Error,
}

/// <summary>
/// One PC/SC reader as <c>SCardGetStatusChange</c> reports it (Windows: <c>WinSCardTransport.GetReaderStates</c>).
/// <paramref name="EventCount"/> is the card insertion/removal counter from the upper 16 bits of <c>dwEventState</c>.
/// </summary>
public sealed record ReaderStatus(string Name, bool CardPresent, bool Mute = false, int EventCount = 0);

/// <summary>What sits in a reader.</summary>
public enum SlotState
{
    Empty,
    Card,
    /// <summary>A card is present but does not answer (no ATR).</summary>
    Mute,
}

/// <summary>A reader and its card. <see cref="Generation"/> changes on every insertion, including a swap.</summary>
public sealed record ReaderSlot(string Name, SlotState State, int Generation);

/// <summary>
/// Card-change detection for PC/SC (docs/09 §3.1b): every inserted card gets a generation per reader, bumped when a
/// reader goes empty → card, or when the card event counter moves while a card is present (a remove + reinsert
/// or a swap that happened entirely between two snapshots). Same rules as the GNOME monitor (LNX-08).
/// Not thread-safe: feed it from one thread.
/// </summary>
public sealed class ReaderGenerationTracker
{
    private readonly Dictionary<string, int> _generations = new(StringComparer.Ordinal);
    private readonly Dictionary<string, bool> _present = new(StringComparer.Ordinal);
    private readonly Dictionary<string, int> _eventCounts = new(StringComparer.Ordinal);

    public IReadOnlyList<ReaderSlot> Update(IReadOnlyList<ReaderStatus> states)
    {
        ArgumentNullException.ThrowIfNull(states);
        foreach (var state in states)
        {
            var wasPresent = _present.GetValueOrDefault(state.Name);
            var counterMoved = _eventCounts.TryGetValue(state.Name, out var count) && count != state.EventCount;
            if (state.CardPresent && (!wasPresent || counterMoved))
                _generations[state.Name] = _generations.GetValueOrDefault(state.Name) + 1;
            _present[state.Name] = state.CardPresent;
            _eventCounts[state.Name] = state.EventCount;
        }

        // A reader that went away forgets its presence, so plugging it back in with a card is a new generation.
        // Generations themselves are kept: a number is never reused for the same reader name.
        var names = states.Select(s => s.Name).ToHashSet(StringComparer.Ordinal);
        foreach (var gone in _present.Keys.Where(n => !names.Contains(n)).ToList())
        {
            _present.Remove(gone);
            _eventCounts.Remove(gone);
        }

        return states.Select(s => new ReaderSlot(
            s.Name,
            !s.CardPresent ? SlotState.Empty : s.Mute ? SlotState.Mute : SlotState.Card,
            _generations.GetValueOrDefault(s.Name))).ToList();
    }
}

/// <summary>
/// One inserted card in the wallet. <see cref="Certificate"/> is null while the PIN-less read runs;
/// <see cref="Problem"/> is set when the read (or an operation on this card) failed.
/// <see cref="ReadToken"/> identifies one read request, so a late answer for a re-inserted or re-read card is dropped.
/// </summary>
public sealed record WalletCard(string Reader, int Generation, int ReadToken,
                                CertificateSummary? Certificate = null, CardErrorKind? Problem = null)
{
    public bool IsReading => Certificate is null && Problem is null;
}

/// <summary>
/// The multi-card model behind the card wallet (docs/10 §0.2, UX-02), UI-framework free so it is unit-tested:
/// cards per reader with their generation, the selected card (the user's pick, else the first card),
/// stale-read protection, "Recitește cardul", and the status light. Port of the Apple/GNOME AppModel logic.
/// Not thread-safe: the app drives it from the UI thread.
/// </summary>
public sealed class CardWallet
{
    private List<WalletCard> _cards = [];
    private List<string> _readers = [];
    private int _nextToken;

    public IReadOnlyList<WalletCard> Cards => _cards;

    /// <summary>Every connected reader (with or without a card).</summary>
    public IReadOnlyList<string> Readers => _readers;

    /// <summary>A reader holds a card that does not answer.</summary>
    public bool HasMuteCard { get; private set; }

    /// <summary>The user's pick; <see cref="Selected"/> falls back to the first card.</summary>
    public string? SelectedReader { get; private set; }

    /// <summary>The card the UI signs with.</summary>
    public WalletCard? Selected => _cards.FirstOrDefault(c => c.Reader == SelectedReader) ?? _cards.FirstOrDefault();

    /// <summary>
    /// Applies a reader snapshot. A card with an unchanged generation keeps what is known about it; a new or
    /// re-inserted card starts over. Returns the cards that need a PIN-less certificate read.
    /// </summary>
    public IReadOnlyList<WalletCard> Apply(IReadOnlyList<ReaderSlot> slots)
    {
        ArgumentNullException.ThrowIfNull(slots);
        _readers = slots.Select(s => s.Name).ToList();
        HasMuteCard = slots.Any(s => s.State == SlotState.Mute);

        var next = new List<WalletCard>();
        var toRead = new List<WalletCard>();
        foreach (var slot in slots.Where(s => s.State == SlotState.Card))
        {
            var known = _cards.FirstOrDefault(c => c.Reader == slot.Name);
            if (known is not null && known.Generation == slot.Generation)
            {
                next.Add(known);
                continue;
            }
            var fresh = new WalletCard(slot.Name, slot.Generation, ++_nextToken);
            next.Add(fresh);
            toRead.Add(fresh);
        }
        _cards = next;
        if (SelectedReader is null || _cards.All(c => c.Reader != SelectedReader))
            SelectedReader = _cards.FirstOrDefault()?.Reader;
        return toRead;
    }

    /// <summary>Stores a finished PIN-less read. False (ignored) when the card changed or was re-read meanwhile.</summary>
    public bool CompleteRead(WalletCard requested, CertificateSummary certificate)
    {
        ArgumentNullException.ThrowIfNull(certificate);
        return Replace(requested, c => c with { Certificate = certificate, Problem = null });
    }

    /// <summary>Records a failed PIN-less read. False (ignored) when the card changed or was re-read meanwhile.</summary>
    public bool FailRead(WalletCard requested, CardErrorKind problem) =>
        Replace(requested, c => c with { Problem = problem });

    /// <summary>
    /// Marks the card in <paramref name="reader"/> as failing after an operation (6985 stuck, PIN blocked…);
    /// the status light turns red until the card is re-inserted or re-read.
    /// </summary>
    public bool MarkProblem(string reader, CardErrorKind problem)
    {
        var index = _cards.FindIndex(c => c.Reader == reader);
        if (index < 0) return false;
        _cards[index] = _cards[index] with { Problem = problem };
        return true;
    }

    /// <summary>"Recitește cardul": forgets what is known about one card (or all when null) and returns them to read.</summary>
    public IReadOnlyList<WalletCard> Reread(string? reader = null)
    {
        var toRead = new List<WalletCard>();
        for (var i = 0; i < _cards.Count; i++)
        {
            if (reader is not null && _cards[i].Reader != reader) continue;
            _cards[i] = new WalletCard(_cards[i].Reader, _cards[i].Generation, ++_nextToken);
            toRead.Add(_cards[i]);
        }
        return toRead;
    }

    /// <summary>Selects the card in <paramref name="reader"/>; false when no card sits there.</summary>
    public bool Select(string reader)
    {
        if (_cards.All(c => c.Reader != reader)) return false;
        SelectedReader = reader;
        return true;
    }

    /// <summary>docs/10 §0.1: busy wins, then idle (no reader), then the selected card's state.</summary>
    public StatusLight Light(bool busy)
    {
        if (busy) return StatusLight.Busy;
        if (_readers.Count == 0) return StatusLight.Idle;
        if (Selected is not { } card) return HasMuteCard ? StatusLight.Error : StatusLight.Reader;
        if (card.Problem is not null) return StatusLight.Error;
        return card.Certificate is not null ? StatusLight.Ready : StatusLight.Reader;
    }

    private bool Replace(WalletCard requested, Func<WalletCard, WalletCard> update)
    {
        ArgumentNullException.ThrowIfNull(requested);
        var index = _cards.FindIndex(c => c.Reader == requested.Reader && c.Generation == requested.Generation &&
                                          c.ReadToken == requested.ReadToken);
        if (index < 0) return false;
        _cards[index] = update(_cards[index]);
        return true;
    }
}
