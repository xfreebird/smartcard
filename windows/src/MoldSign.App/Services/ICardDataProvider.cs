using MoldSign.Core;

namespace MoldSign.App.Services;

/// <summary>Supplies card data without coupling wallet reconciliation to hardware or preview scenarios.</summary>
public interface ICardDataProvider
{
    Task<CardDataResult> ReadAsync(string reader);
}
