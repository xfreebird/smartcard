using MoldSign.Desktop;

namespace MoldSign.Core.Tests;

public sealed class SavedPinActionsTests
{
    [Fact]
    public void Forget_selected_preserves_other_cards()
    {
        var vault = new TrackingVault();
        Assert.True(SavedPinActions.ForgetSelected(vault, "card-a", false));
        Assert.Equal(new[] { "card-b" }, vault.SavedCards());
        Assert.False(vault.DeleteAllCalled);
    }

    [Theory]
    [InlineData(null, false)]
    [InlineData("", false)]
    [InlineData("missing", false)]
    [InlineData("card-a", true)]
    public void Missing_selection_or_demo_does_not_delete(string? selection, bool demo)
    {
        var vault = new TrackingVault();
        Assert.False(SavedPinActions.ForgetSelected(vault, selection, demo));
        Assert.Equal(2, vault.SavedCards().Count);
        Assert.False(vault.DeleteAllCalled);
    }

    private sealed class TrackingVault : IPinVault
    {
        private readonly List<string> cards = ["card-a", "card-b"];
        public bool DeleteAllCalled { get; private set; }
        public void Save(string pin, string certificateSha1) => throw new NotSupportedException();
        public bool Contains(string certificateSha1) => cards.Contains(certificateSha1);
        public Task<string?> LoadAsync(string certificateSha1, string reason) => throw new NotSupportedException();
        public void Delete(string certificateSha1) => cards.Remove(certificateSha1);
        public void DeleteAll() { DeleteAllCalled = true; cards.Clear(); }
        public IReadOnlyList<string> SavedCards() => cards.ToArray();
    }
}
