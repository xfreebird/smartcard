using System.Collections.ObjectModel;
using System.ComponentModel;
using System.Globalization;
using System.Runtime.CompilerServices;
using System.Text.Json.Serialization;
using Microsoft.UI.Xaml;
using Microsoft.UI.Xaml.Controls;
using Microsoft.UI.Xaml.Media;
using MoldSign.Core;

namespace MoldSign.App.Services;

/// <summary>
/// ActivityRow: status, file, action ("Semnat" / "Verificat" / "Cerere msign.gov.md"), time, path. File entries carry
/// the document's <see cref="Path"/> (shown only while that file exists); browser requests have none.
/// </summary>
public sealed record ActivityItem(string FileName, string Action, DateTimeOffset When, bool Success, string? Path, bool? SignedOutput = null, string? ProtectionOperation = null)
{
    public string ActionLabel => ProtectionOperation is "encrypted" ? Loc.Get("protect_encrypted") : ProtectionOperation is "decrypted" ? Loc.Get("protect_decrypted") : SignatureLabels.Human(Action);
    public bool CanVerify => Path is not null && ProtectionOperation != "encrypted" && (System.IO.Path.GetExtension(Path).Equals(".pdf", StringComparison.OrdinalIgnoreCase) || System.IO.Path.GetExtension(Path).Equals(".xml", StringComparison.OrdinalIgnoreCase));
    public bool IsProtectionOutput => ProtectionOperation is "encrypted" or "decrypted";
    [JsonIgnore]
    public bool IsSavedDocument => IsSignedDocument || (Success && Path is not null && IsProtectionOutput);
    public Visibility VerifyVisibility => CanVerify ? Visibility.Visible : Visibility.Collapsed;
    public string VerifyLabel => Loc.Get("Action_Verify");
    public string OpenLabel => Path is null ? "" : Loc.Get(IsProtectionOutput ? "saved_files" : "saved_details");
    [JsonIgnore]
    public bool IsSignedDocument => Success && Path is not null &&
        (SignedOutput == true || (SignedOutput is null && System.IO.Path.GetFileName(Path).Contains("-semnat", StringComparison.OrdinalIgnoreCase)));
    [JsonIgnore]
    public string Glyph => IsProtectionOutput ? "\uE8B7" : Success ? "\uE73E" : "\uE783"; // CheckMark / Error

    [JsonIgnore]
    public string WhenText => When.ToLocalTime().ToString("g", CultureInfo.CurrentCulture);

    /// <summary>A document entry whose file is gone (moved, deleted): hidden and pruned.</summary>
    [JsonIgnore]
    public bool IsMissingFile => Path is { } path && !File.Exists(path);
}

/// <summary>
/// UI-thread view state shared by the tray flyout, the main window and the tray icon (x:Bind OneWay targets).
/// The multi-card logic lives in <see cref="CardWallet"/> (Core, unit-tested); this class mirrors it into
/// <see cref="WalletItems"/> for the CardWallet control and derives the status light (docs/10 §0.1–0.2, UX-01/02).
/// Mutate it only on the UI thread; AppServices marshals card and reader events through the DispatcherQueue.
/// </summary>
public sealed class AppState : INotifyPropertyChanged
{
    public static AppState Current { get; } = new();

    private readonly CardWallet _wallet = new();
    private bool _busy;
    private bool _isDemo;
    private SigningStep? _step;
    private StatusLight _light = StatusLight.Idle;
    private string _lightLabel = "";
    private bool _bridgeEnabled;
    private string _bridgeStatus = "";

    private DateTimeOffset _recentsClearedAt = DateTimeOffset.MinValue;

    private AppState()
    {
        Activity.CollectionChanged += (_, _) => Raise(nameof(ActivityEmptyVisibility));
        RecentDocuments.CollectionChanged += (_, _) =>
        {
            Raise(nameof(RecentEmptyVisibility));
            Raise(nameof(RecentClearVisibility));
        };
        Refresh();
    }

    public event PropertyChangedEventHandler? PropertyChanged;

    /// <summary>Raised after every wallet change (cards, selection), once the items are up to date.</summary>
    public event EventHandler? WalletChanged;

    // MARK: - Wallet

    /// <summary>Inserted cards in reader order, or exactly one placeholder card (insert / connect / mute).</summary>
    public ObservableCollection<WalletCardItem> WalletItems { get; } = [];

    /// <summary>The wallet item of the card the UI signs with; null when no card is inserted.</summary>
    public WalletCardItem? SelectedItem => WalletItems.FirstOrDefault(i => i.Kind == WalletItemKind.Card && i.IsSelected);

    public int SelectedIndex => SelectedItem is { } item ? WalletItems.IndexOf(item) : -1;

    public int CardCount => _wallet.Cards.Count;

    public CertificateSummary? Certificate => _wallet.Selected?.Certificate;

    public IReadOnlyList<CardEntry> BridgeCards => _wallet.Cards
        .Where(c => c.Certificate is not null && c.Problem is null)
        .Select(c => new CardEntry(c.Reader, c.Certificate!)).ToArray();

    public string? SelectedReader => _wallet.Selected?.Reader;

    /// <summary>The selected card can sign right now.</summary>
    public bool CanSign => Light == StatusLight.Ready;

    // MARK: - Status light (docs/10 §0.1)

    public StatusLight Light { get => _light; private set => Set(ref _light, value); }

    /// <summary>Tooltip / accessibility text of the light: it always says what the color says.</summary>
    public string LightLabel { get => _lightLabel; private set => Set(ref _lightLabel, value); }

    public Brush LightBrush => WindowHelpers.ThemeBrush(Light switch
    {
        StatusLight.Ready => "SuccessBrush",
        StatusLight.Reader => "WarningBrush",
        StatusLight.Busy => "BrandBrush",
        StatusLight.Error => "DangerBrush",
        _ => "TextFillColorTertiaryBrush",
    });

    /// <summary>Idle has no dot (docs/10 §0.1).</summary>
    public Visibility LightDotVisibility => Light == StatusLight.Idle ? Visibility.Collapsed : Visibility.Visible;

    public bool IsBusy => _busy;

    /// <summary>Current signing step while busy ("Se verifică PIN-ul…").</summary>
    public string ProgressText => _busy && _step is { } step ? StepText(step) : "";

    public Visibility ProgressVisibility => _busy ? Visibility.Visible : Visibility.Collapsed;

    public Visibility NotBusyVisibility => _busy ? Visibility.Collapsed : Visibility.Visible;

    // MARK: - Tray (docs/10 §0.2b, UX-11): two states only

    /// <summary>Green dot: at least one card is inserted and not failing (reading, ready or signing). Gray otherwise.</summary>
    public bool TrayConnected => _wallet.Cards.Any(c => c.Problem is null);

    /// <summary>"Card conectat · {holder}", "Niciun card conectat", or the error's one-liner (prefixed with the product name).</summary>
    public string TrayLabel
    {
        get
        {
            if (TrayConnected)
            {
                var holder = (_wallet.Selected is { Problem: null, Certificate: { } selected } ? selected : null)
                             ?? _wallet.Cards.FirstOrDefault(c => c.Problem is null && c.Certificate is not null)?.Certificate;
                return holder is null ? Loc.Get("Tray_ConnectedNoHolder") : Loc.Format("Tray_Connected", holder.CommonName);
            }
            return _wallet.Cards.Count > 0 || _wallet.HasMuteCard ? LightLabel : Loc.Get("Tray_None");
        }
    }

    // MARK: - Status InfoBar (main window)

    public bool StatusInfoOpen => Light == StatusLight.Error;

    public InfoBarSeverity StatusInfoSeverity => Light == StatusLight.Error ? InfoBarSeverity.Error : InfoBarSeverity.Informational;

    public string StatusInfoTitle => Light == StatusLight.Error
        ? Loc.Get(_wallet.Selected is null && _wallet.HasMuteCard ? "Wallet_MuteTitle" : "Info_CardErrorTitle")
        : Loc.Get("Info_NoReaderTitle");

    public string StatusInfoMessage => Light == StatusLight.Error ? LightLabel : Loc.Get("Wallet_ConnectMessage");

    /// <summary>"Recitește cardul" on card errors.</summary>
    public Visibility StatusInfoActionVisibility =>
        Light == StatusLight.Error && _wallet.Cards.Count > 0 ? Visibility.Visible : Visibility.Collapsed;

    // MARK: - Activity + bridge

    /// <summary>Activity page: every entry, newest first (documents whose file is gone are pruned).</summary>
    public ObservableCollection<ActivityItem> Activity { get; } = [];
    /// Persistent library; independent of the bounded operation history and tray recents.
    public ObservableCollection<ActivityItem> SignedDocuments { get; } = [];

    /// <summary>
    /// Tray flyout "Recente": existing documents only (no browser requests, no missing files), newest first, one row
    /// per file, not older than the last "Golește lista".
    /// </summary>
    public ObservableCollection<ActivityItem> RecentDocuments { get; } = [];

    public Visibility ActivityEmptyVisibility => Activity.Count == 0 ? Visibility.Visible : Visibility.Collapsed;

    public Visibility RecentEmptyVisibility => RecentDocuments.Count == 0 ? Visibility.Visible : Visibility.Collapsed;

    public Visibility RecentClearVisibility => RecentDocuments.Count > 0 ? Visibility.Visible : Visibility.Collapsed;

    public bool BridgeEnabled { get => _bridgeEnabled; set => Set(ref _bridgeEnabled, value); }

    public string BridgeStatus { get => _bridgeStatus; set => Set(ref _bridgeStatus, value); }

    public bool IsDemo => _isDemo;
    public bool DemoBannerVisible => _isDemo && !DemoMode.ScreenshotCapture;
    public string DemoDisclaimer => Loc.Get("demo_mode_disclaimer");
    public Visibility DemoVisibility => _isDemo ? Visibility.Visible : Visibility.Collapsed;
    public void ResetSession(bool demo)
    {
        _wallet.Apply([]); _busy = false; _step = null; _isDemo = demo;
        Activity.Clear(); SignedDocuments.Clear(); RecentDocuments.Clear(); _recentsClearedAt = DateTimeOffset.MinValue;
        BridgeEnabled = false; BridgeStatus = "";
        Refresh(); Raise(nameof(IsDemo)); Raise(nameof(DemoBannerVisible)); Raise(nameof(DemoVisibility));
    }

    // MARK: - Mutations (UI thread)

    /// <summary>Applies a reader snapshot; returns the cards that need a PIN-less certificate read.</summary>
    public IReadOnlyList<WalletCard> ApplySlots(IReadOnlyList<ReaderSlot> slots)
    {
        var toRead = _wallet.Apply(slots);
        Refresh();
        return toRead;
    }

    public void CompleteRead(WalletCard card, CertificateSummary certificate)
    {
        if (_wallet.CompleteRead(card, certificate)) Refresh();
    }

    public void FailRead(WalletCard card, CardErrorKind problem)
    {
        if (_wallet.FailRead(card, problem)) Refresh();
    }

    /// <summary>An operation failed on this card in a way only a re-insert/re-read fixes (6985, PIN blocked).</summary>
    public void MarkProblem(string reader, CardErrorKind problem)
    {
        if (_wallet.MarkProblem(reader, problem)) Refresh();
    }

    /// <summary>"Recitește cardul" (one card, or all when null): returns the cards to read again.</summary>
    public IReadOnlyList<WalletCard> Reread(string? reader = null)
    {
        var toRead = _wallet.Reread(reader);
        Refresh();
        return toRead;
    }

    public void Select(string reader)
    {
        if (reader != _wallet.Selected?.Reader && _wallet.Select(reader)) Refresh();
    }

    public void SetBusy(bool busy)
    {
        _busy = busy;
        _step = null;
        Refresh();
    }

    public void SetStep(SigningStep step)
    {
        if (!_busy) return;
        _step = step;
        Raise(nameof(ProgressText));
    }

    public void AddActivity(ActivityItem item)
    {
        if (item.IsSavedDocument)
        {
            for (var i = SignedDocuments.Count - 1; i >= 0; i--)
                if (string.Equals(SignedDocuments[i].Path, item.Path, StringComparison.OrdinalIgnoreCase)) SignedDocuments.RemoveAt(i);
            SignedDocuments.Insert(0, item);
        }
        Activity.Insert(0, item);
        while (Activity.Count > ActivityLog.MaxItems) Activity.RemoveAt(Activity.Count - 1);
        RefreshRecents();
        ActivityLog.Save(Activity, _recentsClearedAt, SignedDocuments);
    }

    /// <summary>Loads the saved log (startup) and drops entries whose document no longer exists.</summary>
    public void LoadActivity()
    {
        var snapshot = ActivityLog.Load();
        _recentsClearedAt = snapshot.RecentsClearedAt;
        Activity.Clear();
        SignedDocuments.Clear();
        foreach (var item in snapshot.SignedDocuments.Where(i => i.IsSavedDocument && !i.IsMissingFile)
            .DistinctBy(i => i.Path, StringComparer.OrdinalIgnoreCase)) SignedDocuments.Add(item);
        foreach (var item in snapshot.Items.Where(i => !i.IsMissingFile).Take(ActivityLog.MaxItems)) Activity.Add(item);
        RefreshRecents();
        // Persist migration before a later history clear can remove its source records.
        ActivityLog.Save(Activity, _recentsClearedAt, SignedDocuments);
    }

    /// <summary>Drops document entries whose file was moved or deleted (flyout open, Activity page shown).</summary>
    public void PruneMissingFiles()
    {
        var removed = false;
        for (var i = Activity.Count - 1; i >= 0; i--)
        {
            if (!Activity[i].IsMissingFile) continue;
            Activity.RemoveAt(i);
            removed = true;
        }
        for (var i = SignedDocuments.Count - 1; i >= 0; i--)
        {
            if (!SignedDocuments[i].IsMissingFile) continue;
            SignedDocuments.RemoveAt(i);
            removed = true;
        }
        RefreshRecents();
        if (removed) ActivityLog.Save(Activity, _recentsClearedAt, SignedDocuments);
    }

    /// <summary>Flyout "Golește lista": empties the recent documents; the Activity page keeps its history.</summary>
    public void ClearRecentDocuments()
    {
        _recentsClearedAt = DateTimeOffset.Now;
        RefreshRecents();
        ActivityLog.Save(Activity, _recentsClearedAt, SignedDocuments);
    }

    /// <summary>Activity page "Golește lista" (after confirmation): the whole log, recents included.</summary>
    public void ClearActivity()
    {
        Activity.Clear();
        RefreshRecents();
        ActivityLog.Save(Activity, _recentsClearedAt, SignedDocuments);
    }

    public bool DeleteSignedDocuments(IEnumerable<ActivityItem> items)
    {
        var success = true;
        foreach (var item in items.ToArray())
        {
            if (!SignedDocuments.Contains(item)) continue;
            try
            {
                if (item.Path is not { } path) { success = false; continue; }
                if (Directory.Exists(path)) { success = false; continue; }
                File.Delete(path); // Missing files can safely be removed from the library.
                SignedDocuments.Remove(item);
            }
            catch (Exception error) { AppLog.Error(error); success = false; }
        }
        RefreshRecents();
        ActivityLog.Save(Activity, _recentsClearedAt, SignedDocuments);
        return success;
    }

    private void RefreshRecents()
    {
        var documents = Activity
            .Where(i => i.Path is not null && i.When > _recentsClearedAt && !i.IsMissingFile)
            .DistinctBy(i => i.Path, StringComparer.OrdinalIgnoreCase)
            .Take(8)
            .ToList();
        if (documents.SequenceEqual(RecentDocuments)) return;
        RecentDocuments.Clear();
        foreach (var item in documents) RecentDocuments.Add(item);
    }

    /// <summary>One calm line + one recovery action per error kind (docs/09 §3.3, docs/10 §1.5).</summary>
    public static string ErrorText(CardErrorKind kind) => kind switch
    {
        CardErrorKind.NoReader => Loc.Get("Status_NoReader"),
        CardErrorKind.NoCard => Loc.Get("Error_NoCard"),
        CardErrorKind.WrongPin => Loc.Get("Error_WrongPin"),
        CardErrorKind.PinBlocked => Loc.Get("Error_PinBlocked"),
        CardErrorKind.CardStateStuck or CardErrorKind.CardNotResponding => Loc.Get("Error_CardStuck"),
        CardErrorKind.SmOutOfSync => Loc.Get("Error_SmOutOfSync"),
        CardErrorKind.CardChanged => Loc.Get("Error_CardChanged"),
        CardErrorKind.Network => Loc.Get("Error_Network"),
        _ => Loc.Get("Error_Generic"),
    };

    public static string StepText(SigningStep step) => Loc.Get($"Step_{step}");

    // MARK: - Internals

    /// <summary>Reconciles <see cref="WalletItems"/> with the model (in place, so selection and animations survive).</summary>
    public void RefreshLanguage() => Refresh();

    private void Refresh()
    {
        var desired = new List<(WalletItemKind Kind, string? Reader, WalletCard? Card)>();
        if (_wallet.Cards.Count > 0)
            desired.AddRange(_wallet.Cards.Select(c => (WalletItemKind.Card, (string?)c.Reader, (WalletCard?)c)));
        else if (_wallet.Readers.Count == 0)
            desired.Add((WalletItemKind.ConnectReader, null, null));
        else if (_wallet.HasMuteCard)
            desired.Add((WalletItemKind.MuteCard, null, null));
        else
            desired.Add((WalletItemKind.InsertCard, _wallet.Readers[0], null));

        for (var i = WalletItems.Count - 1; i >= 0; i--)
        {
            var item = WalletItems[i];
            if (!desired.Any(d => d.Kind == item.Kind && d.Reader == item.Reader)) WalletItems.RemoveAt(i);
        }
        var selectedReader = _wallet.Selected?.Reader;
        for (var i = 0; i < desired.Count; i++)
        {
            var (kind, reader, card) = desired[i];
            var at = -1;
            for (var j = 0; j < WalletItems.Count; j++)
            {
                if (WalletItems[j].Kind == kind && WalletItems[j].Reader == reader) at = j;
            }
            if (at < 0) WalletItems.Insert(i, new WalletCardItem(kind, reader));
            else if (at != i) WalletItems.Move(at, i);
            WalletItems[i].Update(card, kind == WalletItemKind.Card && reader == selectedReader);
        }

        Light = _wallet.Light(_busy);
        LightLabel = ComputeLabel();
        Raise(string.Empty); // every derived property (InfoBar, pager, selection, progress…)
        WalletChanged?.Invoke(this, EventArgs.Empty);
    }

    private string ComputeLabel()
    {
        var selected = _wallet.Selected;
        switch (Light)
        {
            case StatusLight.Busy:
                return Loc.Get("Light_Busy");
            case StatusLight.Ready:
                var holder = selected?.Certificate?.CommonName ?? "";
                return _wallet.Cards.Count > 1
                    ? Loc.Format("Light_ReadyMany", holder, _wallet.Cards.Count)
                    : Loc.Format("Light_Ready", holder);
            case StatusLight.Reader:
                return Loc.Get(selected is { IsReading: true } ? "Light_Reading" : "Light_Reader");
            case StatusLight.Error:
                return selected?.Problem is { } problem ? ErrorText(problem) : Loc.Get("Error_CardStuck");
            default:
                return Loc.Get("Light_Idle");
        }
    }

    private void Set<T>(ref T field, T value, [CallerMemberName] string name = "")
    {
        if (EqualityComparer<T>.Default.Equals(field, value)) return;
        field = value;
        Raise(name);
    }

    private void Raise(string name) => PropertyChanged?.Invoke(this, new PropertyChangedEventArgs(name));
}
