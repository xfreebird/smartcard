using MoldSign.Core;

namespace MoldSign.App.Services;

/// <summary>Result of a UI-triggered operation, ready for an InfoBar.</summary>
public sealed record OperationOutcome(bool Success, string Message, IReadOnlyList<string> Outputs)
{
    public IReadOnlyDictionary<string, string> FailedInputs { get; init; } = new Dictionary<string, string>();
    public IReadOnlyList<VerificationReport>? Reports { get; init; }
    public IReadOnlyList<string> CompletedInputs { get; init; } = [];
    public string? FailedInput { get; init; }
}
