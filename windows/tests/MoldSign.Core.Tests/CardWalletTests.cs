using System.Security.Cryptography;
using System.Security.Cryptography.X509Certificates;

namespace MoldSign.Core.Tests;

/// <summary>Card generations per reader and the multi-card wallet model (docs/09 §3.1b, docs/10 §0.1–0.2).</summary>
public class CardWalletTests
{
    private static readonly CertificateSummary s_ion = Summary("CN=ION POPESCU, C=MD");
    private static readonly CertificateSummary s_maria = Summary("CN=MARIA POPESCU, C=MD");

    // MARK: - ReaderGenerationTracker

    [Fact]
    public void Insert_remove_reinsert_gets_a_new_generation()
    {
        var tracker = new ReaderGenerationTracker();

        Assert.Equal(new ReaderSlot("R", SlotState.Empty, 0), tracker.Update([new("R", false)]).Single());
        Assert.Equal(new ReaderSlot("R", SlotState.Card, 1), tracker.Update([new("R", true)]).Single());
        Assert.Equal(1, tracker.Update([new("R", true)]).Single().Generation); // unchanged
        Assert.Equal(SlotState.Empty, tracker.Update([new("R", false)]).Single().State);
        Assert.Equal(2, tracker.Update([new("R", true)]).Single().Generation);
    }

    [Fact]
    public void A_swap_between_two_snapshots_is_caught_by_the_event_counter()
    {
        var tracker = new ReaderGenerationTracker();
        tracker.Update([new("R", true, EventCount: 1)]);

        // Removed and another card inserted between two snapshots: still present, counter moved by 2.
        var slot = tracker.Update([new("R", true, EventCount: 3)]).Single();

        Assert.Equal(2, slot.Generation);
    }

    [Fact]
    public void Replugging_a_reader_with_its_card_is_a_new_generation()
    {
        var tracker = new ReaderGenerationTracker();
        tracker.Update([new("R", true)]);
        tracker.Update([]);

        Assert.Equal(2, tracker.Update([new("R", true)]).Single().Generation);
    }

    [Fact]
    public void A_card_without_an_answer_is_mute()
    {
        var slot = new ReaderGenerationTracker().Update([new("R", true, Mute: true)]).Single();
        Assert.Equal(SlotState.Mute, slot.State);
    }

    // MARK: - CardWallet

    [Fact]
    public void Two_cards_select_the_first_then_follow_the_pick()
    {
        var wallet = new CardWallet();

        var toRead = wallet.Apply([new("A", SlotState.Card, 1), new("B", SlotState.Card, 1)]);

        Assert.Equal(["A", "B"], toRead.Select(c => c.Reader));
        Assert.Equal("A", wallet.Selected?.Reader);
        Assert.True(wallet.Select("B"));
        Assert.Equal("B", wallet.Selected?.Reader);
        Assert.False(wallet.Select("nowhere"));
        Assert.Equal("B", wallet.Selected?.Reader);
    }

    [Fact]
    public void Removing_the_selected_card_falls_back_to_another_one()
    {
        var wallet = new CardWallet();
        wallet.Apply([new("A", SlotState.Card, 1), new("B", SlotState.Card, 1)]);
        wallet.Select("B");

        wallet.Apply([new("A", SlotState.Card, 1), new("B", SlotState.Empty, 1)]);

        Assert.Equal("A", wallet.Selected?.Reader);
        Assert.Equal(["A", "B"], wallet.Readers);
        wallet.Apply([new("A", SlotState.Card, 1), new("B", SlotState.Card, 2)]);
        Assert.Equal("B", wallet.Selected?.Reader);
    }

    [Fact]
    public void A_late_read_for_a_reinserted_card_is_dropped()
    {
        var wallet = new CardWallet();
        var first = wallet.Apply([new("A", SlotState.Card, 1)]).Single();
        var second = wallet.Apply([new("A", SlotState.Card, 2)]).Single(); // swapped while the read ran

        Assert.False(wallet.CompleteRead(first, s_ion));
        Assert.Null(wallet.Selected?.Certificate);
        Assert.True(wallet.CompleteRead(second, s_maria));
        Assert.Equal(s_maria.Sha1, wallet.Selected?.Certificate?.Sha1);
    }

    [Fact]
    public void An_unchanged_generation_keeps_the_certificate()
    {
        var wallet = new CardWallet();
        var card = wallet.Apply([new("A", SlotState.Card, 1)]).Single();
        wallet.CompleteRead(card, s_ion);

        Assert.Empty(wallet.Apply([new("A", SlotState.Card, 1), new("B", SlotState.Empty, 0)]));
        Assert.Equal(s_ion.Sha1, wallet.Selected?.Certificate?.Sha1);
    }

    [Fact]
    public void Reread_forgets_the_card_and_ignores_the_previous_read()
    {
        var wallet = new CardWallet();
        var card = wallet.Apply([new("A", SlotState.Card, 1)]).Single();
        wallet.CompleteRead(card, s_ion);

        var again = wallet.Reread("A").Single();

        Assert.True(wallet.Selected?.IsReading);
        Assert.False(wallet.CompleteRead(card, s_ion));
        Assert.True(wallet.CompleteRead(again, s_ion));
        Assert.Empty(wallet.Reread("nowhere"));
    }

    [Fact]
    public void Status_light_follows_docs_10_section_0_1()
    {
        var wallet = new CardWallet();
        Assert.Equal(StatusLight.Idle, wallet.Light(busy: false));

        wallet.Apply([new("A", SlotState.Empty, 0)]);
        Assert.Equal(StatusLight.Reader, wallet.Light(busy: false));          // reader, no card

        var card = wallet.Apply([new("A", SlotState.Card, 1)]).Single();
        Assert.Equal(StatusLight.Reader, wallet.Light(busy: false));          // card being read

        wallet.CompleteRead(card, s_ion);
        Assert.Equal(StatusLight.Ready, wallet.Light(busy: false));
        Assert.Equal(StatusLight.Busy, wallet.Light(busy: true));

        wallet.MarkProblem("A", CardErrorKind.PinBlocked);
        Assert.Equal(StatusLight.Error, wallet.Light(busy: false));

        wallet.Apply([new("A", SlotState.Mute, 1)]);
        Assert.Equal(StatusLight.Error, wallet.Light(busy: false));           // mute card, nothing else
    }

    [Fact]
    public void A_failed_read_is_an_error_on_that_card()
    {
        var wallet = new CardWallet();
        var cards = wallet.Apply([new("A", SlotState.Card, 1), new("B", SlotState.Card, 1)]);
        wallet.FailRead(cards[0], CardErrorKind.CardStateStuck);
        wallet.CompleteRead(cards[1], s_maria);

        Assert.Equal(StatusLight.Error, wallet.Light(busy: false));
        wallet.Select("B");
        Assert.Equal(StatusLight.Ready, wallet.Light(busy: false));
    }

    private static CertificateSummary Summary(string subject)
    {
        using var rsa = RSA.Create(2048);
        var request = new CertificateRequest(subject, rsa, HashAlgorithmName.SHA256, RSASignaturePadding.Pkcs1);
        using var cert = request.CreateSelfSigned(DateTimeOffset.UtcNow.AddDays(-1), DateTimeOffset.UtcNow.AddYears(1));
        return CertificateSummary.FromDer(cert.Export(X509ContentType.Cert));
    }
}
