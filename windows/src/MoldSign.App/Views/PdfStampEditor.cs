using Microsoft.UI;
using Microsoft.UI.Windowing;
using System.Runtime.InteropServices;
using Microsoft.UI.Xaml;
using Microsoft.UI.Xaml.Controls;
using Microsoft.UI.Xaml.Controls.Primitives;
using Microsoft.UI.Xaml.Automation;
using Microsoft.UI.Xaml.Media;
using Microsoft.UI.Xaml.Markup;
using Microsoft.UI.Xaml.Media.Imaging;
using MoldSign.App.Services;
using MoldSign.Core;
using Windows.Data.Pdf;
using Windows.Storage.Streams;

namespace MoldSign.App.Views;

/// <summary>Native PDF preview. Placement is saved on the queued document, never on its source file.</summary>
internal static class PdfStampEditor
{
    [DllImport("user32.dll")] private static extern nint GetAncestor(nint window, uint flags);
    [DllImport("user32.dll")] private static extern bool EnableWindow(nint window, bool enabled);
    [DllImport("user32.dll", EntryPoint="SetWindowLongPtrW")] private static extern nint SetOwner(nint window, int index, nint owner);

    internal static async Task<bool> ShowAsync(XamlRoot root, FileRow row, Action<PdfStampPlacement?>? onBatch = null, string? requester = null, CancellationToken cancellationToken = default, bool previewOnly = false)
    {
        var appLanguage = Microsoft.Windows.Globalization.ApplicationLanguages.PrimaryLanguageOverride;
        if (string.IsNullOrEmpty(appLanguage)) appLanguage = Microsoft.Windows.Globalization.ApplicationLanguages.Languages.FirstOrDefault() ?? "ro";
        var placement = (row.Stamp ?? new PdfStampPlacement()) with { Language = PdfStampText.FromLocale(appLanguage) };
        var enabled = new ToggleSwitch { Header = Loc.Get("Stamp_Visible"), IsOn = !previewOnly, Visibility = previewOnly ? Visibility.Collapsed : Visibility.Visible };
        var queue = new CheckBox { Content = Loc.Get("Stamp_Queue") };
        var all = new RadioButton { Content = Loc.Get("Stamp_AllPages"), GroupName="StampScope", IsChecked = placement.AllPages };
        var selected = new RadioButton { Content=Loc.Get("Stamp_SelectedPage"), GroupName="StampScope", IsChecked=!placement.AllPages };
        var error = new TextBlock { TextWrapping = TextWrapping.Wrap };
        var previewColumn = new StackPanel { Spacing=16, Padding=new Thickness(16) };
        var pageScroll = new ScrollViewer { Content=previewColumn, HorizontalScrollBarVisibility=ScrollBarVisibility.Disabled };
        var options = new StackPanel { Spacing=16, Padding=new Thickness(20) };
        options.Children.Add(new TextBlock { Text=Loc.Get("Stamp_Title"), FontSize=20, FontWeight=Microsoft.UI.Text.FontWeights.SemiBold });
        Border Group(params UIElement[] children) {
            var stack=new StackPanel { Spacing=16, Padding=new Thickness(16) };
            foreach (var child in children) stack.Children.Add(child);
            // Resolve theme resources in the editor's visual tree, not the application's default theme.
            var border = (Border)XamlReader.Load("""
                <Border xmlns="http://schemas.microsoft.com/winfx/2006/xaml/presentation"
                        CornerRadius="8" Background="{ThemeResource LayerFillColorDefaultBrush}" />
                """);
            border.Child = stack;
            return border;
        }
        options.Children.Add(Group(enabled,new TextBlock { Text=Path.GetFileName(row.Path), TextWrapping=TextWrapping.Wrap, Opacity=.65 }));
        var scope=new StackPanel { Spacing=12 };
        scope.Children.Add(new TextBlock { Text=Loc.Get("Stamp_Scope") });
        scope.Children.Add(selected); scope.Children.Add(all);
        if (onBatch is not null) scope.Children.Add(queue);
        if (!previewOnly)
        {
            options.Children.Add(Group(scope));
            options.Children.Add(new TextBlock { Text=Loc.Get("Stamp_MoveHint"), TextWrapping=TextWrapping.Wrap, Opacity=.65 });
        }
        if (requester is not null) options.Children.Add(new TextBlock { Text=requester, TextWrapping=TextWrapping.Wrap });
        options.Children.Add(error);
        var editor = new Window { Title=Loc.Get("Stamp_Title") };
        var completion = new TaskCompletionSource<bool>();
        var apply = new Button { Content=Loc.Get(previewOnly ? "Action_Sign" : "Stamp_Save"), MinWidth=100, IsEnabled=false, Style=(Style)Application.Current.Resources["AccentButtonStyle"] };
        var cancel = new Button { Content=Loc.Get("Action_Cancel"), MinWidth=100 };
        var footer = new StackPanel { Orientation=Orientation.Horizontal, Spacing=12, HorizontalAlignment=HorizontalAlignment.Right, Margin=new Thickness(24,16,24,20) };
        footer.Children.Add(cancel); footer.Children.Add(apply);
        var chrome = (Grid)XamlReader.Load("""
            <Grid xmlns="http://schemas.microsoft.com/winfx/2006/xaml/presentation"
                  Background="{ThemeResource ApplicationPageBackgroundThemeBrush}" />
            """);
        chrome.RequestedTheme = (root.Content as FrameworkElement)?.ActualTheme ?? ElementTheme.Default;
        chrome.ColumnDefinitions.Add(new ColumnDefinition { Width=new GridLength(1,GridUnitType.Star) });
        chrome.ColumnDefinitions.Add(new ColumnDefinition { Width=new GridLength(380) });
        chrome.Children.Add(pageScroll);
        var inspector=new Grid();
        inspector.RowDefinitions.Add(new RowDefinition { Height=new GridLength(1,GridUnitType.Star) });
        inspector.RowDefinitions.Add(new RowDefinition { Height=GridLength.Auto });
        inspector.Children.Add(new ScrollViewer { Content=options, HorizontalScrollBarVisibility=ScrollBarVisibility.Disabled });
        Grid.SetRow(footer,1); inspector.Children.Add(footer);
        Grid.SetColumn(inspector,1); chrome.Children.Add(inspector);
        editor.Content=chrome;
        var scale=WindowHelpers.Scale(editor);
        var work=DisplayArea.GetFromWindowId(editor.AppWindow.Id,DisplayAreaFallback.Nearest).WorkArea;
        var windowWidth=Math.Min((int)(1100*scale),work.Width-40);
        var windowHeight=Math.Min((int)(850*scale),work.Height-40);
        editor.AppWindow.MoveAndResize(new Windows.Graphics.RectInt32(work.X+(work.Width-windowWidth)/2,work.Y+(work.Height-windowHeight)/2,windowWidth,windowHeight));
        WindowHelpers.ApplyCaptionTheme(editor);
        var owner=GetAncestor(Microsoft.UI.Win32Interop.GetWindowFromWindowId(root.ContentIslandEnvironment.AppWindowId),2);
        SetOwner(WindowHelpers.Handle(editor),-8,owner);
        var ownerWindow=AppWindow.GetFromWindowId(Microsoft.UI.Win32Interop.GetWindowIdFromWindow(owner));
        if (ownerWindow.Presenter is OverlappedPresenter ownerPresenter && editor.AppWindow.Presenter is OverlappedPresenter editorPresenter)
            editorPresenter.IsAlwaysOnTop=ownerPresenter.IsAlwaysOnTop;
        cancel.Click += (_,_) => editor.Close();
        apply.Click += (_,_) => { completion.TrySetResult(true); editor.Close(); };
        editor.Closed += (_,_) => completion.TrySetResult(false);
        PdfDocument? document = null; InMemoryRandomAccessStream? source = null; var rendering = false; var resizing = false;
        var overlays=new List<Action>();
        var pageLayouts=new List<Action>();
        void LayoutPages() {
            foreach (var layout in pageLayouts) layout();
            Overlay();
        }
        pageScroll.SizeChanged += (_,_) => LayoutPages();
        void Overlay() {
            foreach (var refresh in overlays) refresh();
            apply.IsEnabled=!enabled.IsOn || document is not null && !rendering && string.IsNullOrEmpty(error.Text);
            all.IsEnabled=selected.IsEnabled=enabled.IsOn;
        }
        async Task RenderAsync() {
            if (document is null) return;
            rendering=true;
            for (var pageIndex=0;pageIndex<document.PageCount;pageIndex++) {
                var index=pageIndex;
                using var page=document.GetPage((uint)index);
        var preview = new Canvas { Width = 500, Height = 480, Background = new SolidColorBrush(Colors.White) };
        var image = new Image(); preview.Children.Add(image);
        var artwork = new StackPanel { Spacing = 0 };
        var ink = new SolidColorBrush(Colors.Black);
        var lines = (placement.Language ?? PdfStampText.CurrentLanguage).Lines(AppState.Current.Certificate?.CommonName ?? "", DateTimeOffset.Now);
        TextBlock StampLine(int index, double maximumWidth)
        {
            var line = new TextBlock { Text = lines[index], FontFamily = new FontFamily("Times New Roman"), FontSize = index == 5 ? 7 : 13, Foreground = ink };
            line.Measure(new Windows.Foundation.Size(double.PositiveInfinity, double.PositiveInfinity));
            if (line.DesiredSize.Width > maximumWidth) line.FontSize *= maximumWidth / line.DesiredSize.Width;
            return line;
        }
        for (var line = 0; line < 4; line++) artwork.Children.Add(StampLine(line, 228));
        artwork.Children.Add(new Border { BorderBrush = new SolidColorBrush(Colors.Gray), BorderThickness = new Thickness(.5), Padding = new Thickness(5, 1, 5, 1), Width = 175, HorizontalAlignment = HorizontalAlignment.Left,
            Child = StampLine(4, 164) });
        artwork.Children.Add(StampLine(5, 228));
        artwork.Width = 240;
        var stamp = new Border { BorderBrush = (Brush)Application.Current.Resources["AccentFillColorDefaultBrush"], BorderThickness = new Thickness(1),
            Child = new Viewbox { Child = artwork, Stretch = Stretch.Fill } };
        preview.Children.Add(stamp);
        var handles = new List<Thumb>();
                var pageRatio=page.Size.Width/page.Size.Height;
                void LayoutPage() {
                    // Show approximately 90% of a portrait page vertically, without horizontal clipping.
                    var width=Math.Max(1,pageScroll.ActualWidth-40);
                    var height=Math.Max(1,pageScroll.ActualHeight-32)/.9;
                    preview.Width=Math.Min(width,height*pageRatio);
                    preview.Height=preview.Width/pageRatio;
                    image.Width=preview.Width; image.Height=preview.Height;
                }
                pageLayouts.Add(LayoutPage); LayoutPage();
                using var stream=new InMemoryRandomAccessStream();
                await page.RenderToStreamAsync(stream,new PdfPageRenderOptions { DestinationWidth=1600 });
                var bitmap=new BitmapImage(); await bitmap.SetSourceAsync(stream); image.Source=bitmap;
                var badge=new TextBlock { HorizontalAlignment=HorizontalAlignment.Center, Margin=new Thickness(0,8,0,0) };
                var card=new StackPanel { HorizontalAlignment=HorizontalAlignment.Center }; card.Children.Add(preview); card.Children.Add(badge); previewColumn.Children.Add(card);
                overlays.Add(() => {
                    var visible=enabled.IsOn && (all.IsChecked==true || placement.Page==index);
                    stamp.Visibility=visible ? Visibility.Visible : Visibility.Collapsed;
                    stamp.Width=preview.Width*placement.Width; stamp.Height=preview.Height*placement.Height;
                    Canvas.SetLeft(stamp,preview.Width*placement.X); Canvas.SetTop(stamp,preview.Height*placement.Y);
                    for (var corner=0;corner<handles.Count;corner++) {
                        handles[corner].Visibility=stamp.Visibility;
                        Canvas.SetLeft(handles[corner],preview.Width*(placement.X+(corner%2==1 ? placement.Width : 0))-8);
                        Canvas.SetTop(handles[corner],preview.Height*(placement.Y+(corner>=2 ? placement.Height : 0))-8);
                    }
                    badge.Text=$"{(visible ? "✓  " : "")}{index+1} / {document.PageCount}";
                });
        void Move(Windows.Foundation.Point point)
        {
            if (!enabled.IsOn || rendering || resizing || preview.Width <= 0) return;
            placement = placement with { Page=index, X = Math.Clamp(point.X / preview.Width - placement.Width / 2, 0, 1 - placement.Width),
                Y = Math.Clamp(point.Y / preview.Height - placement.Height / 2, 0, 1 - placement.Height) }; Overlay();
        }
        preview.PointerPressed += (_, e) => { if (e.OriginalSource is Thumb) return; preview.CapturePointer(e.Pointer); Move(e.GetCurrentPoint(preview).Position); };
        preview.PointerMoved += (_, e) => { if (e.GetCurrentPoint(preview).Properties.IsLeftButtonPressed) Move(e.GetCurrentPoint(preview).Position); };
        preview.PointerReleased += (_, e) => preview.ReleasePointerCapture(e.Pointer);

        for (var corner = 0; corner < 4; corner++) {
            var cornerIndex = corner; var start = placement; double dx=0,dy=0;
            var handle = new Thumb { Width=16, Height=16, Background=(Brush)Application.Current.Resources["AccentFillColorDefaultBrush"], BorderBrush=new SolidColorBrush(Colors.White), BorderThickness=new Thickness(2) };
            AutomationProperties.SetName(handle, Loc.Get("Stamp_Size"));
            handle.DragStarted += (_, _) => { resizing=true; placement=placement with { Page=index }; start=placement; dx=0; dy=0; };
            handle.DragCompleted += (_, _) => resizing=false;
            handle.DragDelta += (_, e) => { dx+=e.HorizontalChange/preview.Width; dy+=e.VerticalChange/preview.Height; placement=start.Resized(cornerIndex,dx,dy); Overlay(); };
            handle.KeyDown += (_, e) => {
                if (e.Key is Windows.System.VirtualKey.Left or Windows.System.VirtualKey.Right) {
                    placement=placement.Resized(cornerIndex,(e.Key==Windows.System.VirtualKey.Right ? .02 : -.02)*(cornerIndex%2==1 ? 1 : -1),0); Overlay(); e.Handled=true;
                }
            };
            handles.Add(handle); preview.Children.Add(handle);
        }
            }
            rendering=false; Overlay();
        }
        enabled.Toggled += (_,_) => Overlay();
        all.Checked += (_,_) => Overlay(); all.Unchecked += (_,_) => Overlay();
        try {
                var bytes = await File.ReadAllBytesAsync(row.Path);
                placement = placement with { DocumentSHA256 = Convert.ToHexString(System.Security.Cryptography.SHA256.HashData(bytes)) };
                // Preview the same private bytes bound to the placement, including provider-backed files.
                source = new InMemoryRandomAccessStream();
                using (var writer = new DataWriter(source.GetOutputStreamAt(0))) { writer.WriteBytes(bytes); await writer.StoreAsync(); await writer.FlushAsync(); }
                source.Seek(0); document = await PdfDocument.LoadFromStreamAsync(source); await RenderAsync();
            }
        catch (Exception e) { rendering=false; error.Text = e.Message; Overlay(); }
        try
        {
            cancellationToken.ThrowIfCancellationRequested();
            using var registration = cancellationToken.Register(() => editor.DispatcherQueue.TryEnqueue(() => editor.Close()));
            EnableWindow(owner,false);
            editor.Activate();
            var applied = await completion.Task;
            cancellationToken.ThrowIfCancellationRequested();
            if (applied)
            {
                row.Stamp = enabled.IsOn ? placement with { AllPages = all.IsChecked == true } : null;
                if (queue.IsChecked == true) onBatch?.Invoke(row.Stamp);
            }
            return applied;
        }
        finally { EnableWindow(owner,true); source?.Dispose(); }
    }
}
