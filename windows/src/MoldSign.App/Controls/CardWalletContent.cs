namespace MoldSign.App.Controls;

public sealed record CardWalletContent(IReadOnlyList<IdentityCardContent> Items, int SelectedIndex,
    bool IsBusy, string PreviousLabel, string NextLabel, string SelectedLabel)
{
    public static CardWalletContent Empty { get; } = new([], 0, false, "", "", "");
    public int CardCount => Items.Count(item => item.IsCard);
}
