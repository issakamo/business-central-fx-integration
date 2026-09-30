namespace FxIntegration.Integration;

codeunit 52101 "FXI Frankfurter Rate Provider" implements "FXI Exchange Rate Provider"
{
    procedure GetRates(BaseCurrencyCode: Code[10]; TargetCurrencyCodes: List of [Code[10]]; var ResultRates: Dictionary of [Code[10], Decimal]): Boolean
    var
        Client: HttpClient;
        Response: HttpResponseMessage;
        ResponseText: Text;
        RequestUrl: Text;
        TempUrl: Text;
        RatesArray: JsonArray;
        RowToken: JsonToken;
        RowObject: JsonObject;
        QuoteToken: JsonToken;
        RateToken: JsonToken;
        QuoteCode: Code[10];
        i: Integer;
        CurrencyCode: Code[10];
    begin
        TempUrl := 'https://api.frankfurter.dev/v2/rates?base=%1&quotes=%2';
        RequestUrl := StrSubstNo(TempUrl, BaseCurrencyCode, BuildQuotesList(TargetCurrencyCodes));

        if not Client.Get(RequestUrl, Response) then
            exit(false);

        if not Response.IsSuccessStatusCode() then
            exit(false);

        if not Response.Content().ReadAs(ResponseText) then
            exit(false);

        if not RatesArray.ReadFrom(ResponseText) then
            exit(false);

        for i := 0 to RatesArray.Count() - 1 do begin
            if not RatesArray.Get(i, RowToken) then
                exit(false);
            if not RowToken.IsObject() then
                exit(false);
            RowObject := RowToken.AsObject();

            if not RowObject.Get('quote', QuoteToken) then
                exit(false);
            if not RowObject.Get('rate', RateToken) then
                exit(false);

            QuoteCode := CopyStr(QuoteToken.AsValue().AsText(), 1, MaxStrLen(QuoteCode));

            if TargetCurrencyCodes.Contains(QuoteCode) and (not ResultRates.ContainsKey(QuoteCode)) then
                ResultRates.Add(QuoteCode, RateToken.AsValue().AsDecimal());
        end;

        foreach CurrencyCode in TargetCurrencyCodes do
            if not ResultRates.ContainsKey(CurrencyCode) then
                exit(false);

        exit(true);
    end;

    local procedure BuildQuotesList(TargetCurrencyCodes: List of [Code[10]]): Text
    var
        CurrencyCode: Code[10];
        QuotesText: Text;
    begin
        foreach CurrencyCode in TargetCurrencyCodes do begin
            if QuotesText <> '' then
                QuotesText += ',';
            QuotesText += CurrencyCode;
        end;
        exit(QuotesText);
    end;
}