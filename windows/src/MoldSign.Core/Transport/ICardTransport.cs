namespace MoldSign.Core;

/// <summary>
/// Raw APDU in, raw response INCLUDING SW1 SW2 out (docs/09-architecture.md §3.1).
/// No GET RESPONSE handling here: <see cref="CosmoXCard"/> loops on <c>61xx</c> itself.
/// </summary>
public interface ICardTransport : IDisposable
{
    string ReaderName { get; }

    /// <summary>Answer-to-reset of the connected card, when the transport knows it (token recognition, Phase TOK).</summary>
    byte[]? Atr => null;

    byte[] Transmit(byte[] apdu);
}
