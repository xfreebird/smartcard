using System.Collections.ObjectModel;
using System.ComponentModel;
using System.Globalization;
using System.Runtime.CompilerServices;
using Microsoft.UI.Xaml;
using Microsoft.UI.Xaml.Media;
using MoldSign.Core;

namespace MoldSign.App.Services;

/// <summary>StatusCard states (docs/10 §3).</summary>
public enum StatusKind
{
    NoReader,
    Empty,
    Reading,
    Ready,
    Busy,
    Error,
}

/// <summary>ActivityRow: status, file, action ("Semnat" / "Verificat" / "Cerere msign.gov.md"), time, path.</summary>
public sealed record ActivityItem(string FileName, string Action, DateTimeOffset When, bool Success, string? Path)
{
    public string Glyph => Success ? "" : ""; // CheckMark / Error
    public string WhenText => When.ToLocalTime().ToString("HH:mm", CultureInfo.CurrentCulture);
}

/// <summary>
/// UI-thread view state shared by the tray flyout and the main window (x:Bind OneWay targets).
/// Mutate it only on the UI thread; AppServices marshals card/bridge events through the DispatcherQueue.
/// </summary>
public sealed class AppState : INotifyPropertyChanged
{
    public static AppState Current { get; } = new();

    private StatusKind _kind = StatusKind.NoReader;
    private string _holder = "MoldSign";
    private string _statusLine = "";
    private string _validityLine = "";
    private string? _readerName;
    private CertificateSummary? _certificate;
    private bool _bridgeEnabled;
    private string _bridgeStatus = "";

    private AppState()
    {
        Recent.CollectionChanged += (_, _) => Raise(nameof(RecentEmptyVisibility));
        Apply(new ReaderState.NoReader());
    }

    public event PropertyChangedEventHandler? PropertyChanged;

    public StatusKind Kind { get => _kind; private set => Set(ref _kind, value, [nameof(DotBrush), nameof(IsBusy)]); }
    public string Holder { get => _holder; private set => Set(ref _holder, value); }
    public string StatusLine { get => _statusLine; private set => Set(ref _statusLine, value); }
    public string ValidityLine { get => _validityLine; private set => Set(ref _validityLine, value, [nameof(ValidityVisibility)]); }
    public string? ReaderName { get => _readerName; private set => Set(ref _readerName, value); }
    public CertificateSummary? Certificate { get => _certificate; private set => Set(ref _certificate, value, [nameof(HasCertificate)]); }
    public bool BridgeEnabled { get => _bridgeEnabled; set => Set(ref _bridgeEnabled, value); }
    public string BridgeStatus { get => _bridgeStatus; set => Set(ref _bridgeStatus, value); }

    public bool IsBusy => Kind is StatusKind.Busy or StatusKind.Reading;
    public bool HasCertificate => Certificate is not null;
    public Visibility ValidityVisibility => string.IsNullOrEmpty(ValidityLine) ? Visibility.Collapsed : Visibility.Visible;

    /// <summary>Status dot: green when ready, red on error, neutral otherwise (an icon always accompanies it).</summary>
    public Brush DotBrush => WindowHelpers.ThemeBrush(Kind switch
    {
        StatusKind.Ready => "SuccessBrush",
        StatusKind.Error => "DangerBrush",
        StatusKind.Busy or StatusKind.Reading => "BrandBrush",
        _ => "TextFillColorTertiaryBrush",
    });

    public ObservableCollection<ActivityItem> Recent { get; } = [];

    public Visibility RecentEmptyVisibility => Recent.Count == 0 ? Visibility.Visible : Visibility.Collapsed;

    public void Apply(ReaderState state)
    {
        switch (state)
        {
            case ReaderState.NoReader:
                Kind = StatusKind.NoReader;
                Holder = "MoldSign";
                StatusLine = Loc.Get("Status_NoReader");
                ReaderName = null;
                Certificate = null;
                ValidityLine = "";
                break;
            case ReaderState.Empty empty:
                Kind = StatusKind.Empty;
                Holder = "MoldSign";
                StatusLine = $"{Loc.Get("Status_Empty")} · {empty.Reader}";
                ReaderName = empty.Reader;
                Certificate = null;
                ValidityLine = "";
                break;
            case ReaderState.CardPresent present:
                ReaderName = present.Reader;
                if (present.Certificate is { } cert) Certificate = cert;
                Kind = Certificate is null && present.Holder is null ? StatusKind.Reading : StatusKind.Ready;
                Holder = present.Holder ?? Certificate?.CommonName ?? Loc.Get("Status_Reading");
                StatusLine = $"{Loc.Get(Kind == StatusKind.Ready ? "Status_Ready" : "Status_Reading")} · {present.Reader}";
                ValidityLine = Certificate is { } c
                    ? Loc.Format("Card_ValidUntil", c.NotAfter.ToLocalTime().ToString("MM.yyyy", CultureInfo.CurrentCulture))
                    : "";
                break;
            case ReaderState.Busy busy:
                Kind = StatusKind.Busy;
                StatusLine = $"{Loc.Get("Status_Busy")} · {busy.Reader}";
                break;
            case ReaderState.Error error:
                Kind = StatusKind.Error;
                StatusLine = ErrorText(error.Kind);
                break;
        }
    }

    public void AddActivity(ActivityItem item)
    {
        Recent.Insert(0, item);
        while (Recent.Count > 50) Recent.RemoveAt(Recent.Count - 1);
    }

    /// <summary>One calm line + one recovery action per error kind (docs/09 §3.3, docs/10 §1.5).</summary>
    public static string ErrorText(CardErrorKind kind) => kind switch
    {
        CardErrorKind.NoReader => Loc.Get("Status_NoReader"),
        CardErrorKind.NoCard => Loc.Get("Error_NoCard"),
        CardErrorKind.WrongPin => Loc.Get("Error_WrongPin"),
        CardErrorKind.PinBlocked => Loc.Get("Error_PinBlocked"),
        CardErrorKind.CardStateStuck => Loc.Get("Error_CardStuck"),
        CardErrorKind.SmOutOfSync => Loc.Get("Error_SmOutOfSync"),
        CardErrorKind.Network => Loc.Get("Error_Network"),
        _ => Loc.Get("Error_Generic"),
    };

    private void Set<T>(ref T field, T value, string[]? alsoChanged = null, [CallerMemberName] string name = "")
    {
        if (EqualityComparer<T>.Default.Equals(field, value)) return;
        field = value;
        Raise(name);
        foreach (var other in alsoChanged ?? []) Raise(other);
    }

    private void Raise(string name) => PropertyChanged?.Invoke(this, new PropertyChangedEventArgs(name));
}
