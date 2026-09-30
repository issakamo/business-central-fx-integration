namespace FxIntegration.Integration;

interface "FXI Exchange Rate Provider"
{
    procedure GetRates(BaseCurrencyCode: Code[10]; TargetCurrencyCodes: List of [Code[10]]; var ResultRates: Dictionary of [Code[10], Decimal]): Boolean
}