namespace FxIntegration.Integration;

codeunit 52100 "FXI Mock Exch Rate Provider" implements "FXI Exchange Rate Provider"
{
    procedure GetRates(BaseCurrencyCode: Code[10]; TargetCurrencyCodes: List of [Code[10]]; var ResultRates: Dictionary of [Code[10], Decimal]): Boolean
    var
        CurrencyCode: Code[10];
    begin
        foreach CurrencyCode in TargetCurrencyCodes do
            case CurrencyCode of
                'EUR':
                    ResultRates.Add(CurrencyCode, 0.92);
                'GBP':
                    ResultRates.Add(CurrencyCode, 0.79);
                'JPY':
                    ResultRates.Add(CurrencyCode, 149.50);
                else
                    ResultRates.Add(CurrencyCode, 1.00);
            end;

        exit(true);
    end;
}