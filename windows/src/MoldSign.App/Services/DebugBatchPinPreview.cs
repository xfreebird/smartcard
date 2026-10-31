#if DEBUG
using Microsoft.UI.Xaml;
using Microsoft.UI.Xaml.Media;
using System.Text.Json;

namespace MoldSign.App.Services;

/// <summary>Standalone UI fixture: no app services, signing, reader, credential vault or biometric request.</summary>
internal static class DebugBatchPinPreview
{
    internal static async Task ShowAsync()
    {
        var appearance = Environment.GetEnvironmentVariable("MSIGN_DEMO_DARK") == "1" ? ElementTheme.Dark : ElementTheme.Light;
        var window = new PinWindow(Loc.Format("Pin_For", "POPESCU ION"),
            ["exemplu-contract.pdf · PAdES-T", "exemplu-cerere.pdf · PAdES-T", "exemplu-anexa.txt · XAdES-BES"],
            remember: false, attemptsLeft: null, appearance: appearance);
        window.ClearPreviewPlaceholder();
        var readyPath = Environment.GetEnvironmentVariable("MSIGN_DEMO_READY_FILE");
        var frames = 0;
        EventHandler<object>? rendered = null;
        rendered = (_, _) =>
        {
            if (window.Content is not FrameworkElement { IsLoaded: true } root || !window.HasEmptyPin) return;
            window.ClearPreviewPlaceholder();
            root.UpdateLayout();
            if (++frames < 3) return;
            CompositionTarget.Rendering -= rendered;
            if (string.IsNullOrEmpty(readyPath)) return;
            File.WriteAllText(readyPath, JsonSerializer.Serialize(new
            {
                Page = "pin", ActualPage = nameof(PinWindow), Scenario = "batch-pin",
                ProcessId = Environment.ProcessId, Window = WindowHelpers.Handle(window).ToInt64(),
                BlankPin = true, CarouselsCentered = true,
            }));
        };
        CompositionTarget.Rendering += rendered;
        using var timeout = new CancellationTokenSource(TimeSpan.FromSeconds(30));
        try
        {
            // Only the dialog is displayed; its result is deliberately discarded.
            await window.ShowAsync(timeout.Token);
        }
        catch (Exception error)
        {
            AppLog.Error(error);
        }
        finally
        {
            CompositionTarget.Rendering -= rendered;
            Application.Current.Exit();
        }
    }
}
#endif
