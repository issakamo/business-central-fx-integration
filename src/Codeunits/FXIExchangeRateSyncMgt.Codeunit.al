namespace FxIntegration.Integration;

using Microsoft.Finance.Currency;
using Microsoft.Finance.GeneralLedger.Setup;

codeunit 52102 "FXI Exchange Rate Sync Mgt"
{
    procedure SyncRates(Provider: Interface "FXI Exchange Rate Provider"; BaseCurrencyCode: Code[10]; TargetCurrencyCodes: List of [Code[10]]): Boolean
    var
        IntegrationLog: Record "FXI Integration Log";
        GLSetup: Record "General Ledger Setup";
        ResultRates: Dictionary of [Code[10], Decimal];
        ErrorInfoObj: ErrorInfo;
        ErrorInfoText: Text;
        ErrorInfoTextDetails: Text;
        MaxAttempts: Integer;
        AttemptNo: Integer;
        CallSucceeded: Boolean;
        CurrencyCode: Code[10];
        RecordsSuccessful: Integer;
        RecordsFailed: Integer;
    begin
        GLSetup.Get();
        if BaseCurrencyCode = '' then
            Error('A base currency code is required. Set the LCY Code in General Ledger Setup.');
        if (GLSetup."LCY Code" <> '') and (BaseCurrencyCode <> GLSetup."LCY Code") then
            Error('Base currency %1 must match the company''s LCY (%2). Syncing rates against a non-LCY base would write incorrect financial data.', BaseCurrencyCode, GLSetup."LCY Code");

        IntegrationLog.Init();
        IntegrationLog."Integration Name" := 'Exchange Rate Sync';
        IntegrationLog."Direction" := IntegrationLog."Direction"::Inbound;
        IntegrationLog."Start Time" := CurrentDateTime;
        IntegrationLog."Status" := IntegrationLog.Status::Started;
        IntegrationLog.Insert(true);

        MaxAttempts := 3;
        AttemptNo := 0;
        repeat
            AttemptNo += 1;
            Clear(ResultRates);
            CallSucceeded := Provider.GetRates(BaseCurrencyCode, TargetCurrencyCodes, ResultRates);
        until CallSucceeded or (AttemptNo >= MaxAttempts);

        IntegrationLog."Retry Count" := AttemptNo - 1;

        if not CallSucceeded then begin
            IntegrationLog."End Time" := CurrentDateTime;
            IntegrationLog."Status" := IntegrationLog.Status::Failed;
            ErrorInfoText := 'Provider call failed after %1 attempt(s).';
            IntegrationLog."Error Message" := StrSubstNo(ErrorInfoText, AttemptNo);
            IntegrationLog.Modify();

            // Commit the failed run's log entry before raising the error.
            // Error() rolls back the whole transaction, so without this commit
            // the Failed entry would be rolled back too, and failed runs would
            // never appear in the log. SyncRates is only invoked from the Setup
            // page's Sync Now action, so this commit doesn't commit unrelated
            // work from a calling process.
            Commit();

            ErrorInfoObj.Message := 'Unable to retrieve exchange rates from the external provider.';
            ErrorInfoTextDetails := 'Failed after %1 attempt(s). See FX Integration Log entry %2 for details.';
            ErrorInfoObj.DetailedMessage := StrSubstNo(ErrorInfoTextDetails, AttemptNo, IntegrationLog."Entry No.");
            Error(ErrorInfoObj);
        end;

        foreach CurrencyCode in TargetCurrencyCodes do
            if UpdateCurrencyExchangeRate(CurrencyCode, ResultRates.Get(CurrencyCode)) then
                RecordsSuccessful += 1
            else
                RecordsFailed += 1;

        IntegrationLog."End Time" := CurrentDateTime;
        IntegrationLog."Records Processed" := TargetCurrencyCodes.Count();
        IntegrationLog."Records Successful" := RecordsSuccessful;
        IntegrationLog."Records Failed" := RecordsFailed;
        IntegrationLog."Status" := IntegrationLog.Status::Completed;
        if RecordsFailed > 0 then
            IntegrationLog."Status" := IntegrationLog.Status::"Partial Success";
        IntegrationLog.Modify();

        exit(RecordsFailed = 0);
    end;

    local procedure UpdateCurrencyExchangeRate(CurrencyCode: Code[10]; Rate: Decimal): Boolean
    var
        Currency: Record Currency;
        CurrencyExchangeRate: Record "Currency Exchange Rate";
    begin
        if not Currency.Get(CurrencyCode) then
            exit(false);

        CurrencyExchangeRate.SetRange("Currency Code", CurrencyCode);
        CurrencyExchangeRate.SetRange("Starting Date", Today);
        if not CurrencyExchangeRate.FindFirst() then begin
            CurrencyExchangeRate.Init();
            CurrencyExchangeRate."Currency Code" := CurrencyCode;
            CurrencyExchangeRate."Starting Date" := Today;
            CurrencyExchangeRate.Insert(true);
        end;

        // Validate (not direct assignment) so Business Central's own field
        // logic runs, including filling the adjustment amounts used by the
        // exchange rate adjustment process.
        CurrencyExchangeRate.Validate("Relational Currency Code", '');
        CurrencyExchangeRate.Validate("Exchange Rate Amount", Rate);
        CurrencyExchangeRate.Validate("Relational Exch. Rate Amount", 1);
        CurrencyExchangeRate.Modify(true);

        exit(true);
    end;
}