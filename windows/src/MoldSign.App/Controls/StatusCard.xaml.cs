using Microsoft.UI.Xaml.Controls;
using MoldSign.App.Services;

namespace MoldSign.App.Controls;

public sealed partial class StatusCard : UserControl
{
    public StatusCard()
    {
        InitializeComponent();
    }

    public AppState State => AppState.Current;
}
