using Microsoft.UI.Xaml.Controls;
using MoldSign.App.Services;

namespace MoldSign.App.Controls;

public sealed partial class StatusLightPill : UserControl
{
    public StatusLightPill()
    {
        InitializeComponent();
    }

    public AppState State => AppState.Current;
}
