namespace FxIntegration.Integration.Test;

using FxIntegration.Integration;
using Microsoft.Finance.Currency;
using Microsoft.Finance.GeneralLedger.Setup;
using System.TestLibraries.Utilities;

codeunit 52121 "FXI Exchange Rate Sync Test"
{
    Subtype = Test;

    [Test]
    procedure SyncRates_AllCurrenciesValid_CompletesSuccessfully()
    var
        IntegrationLog: Record "FXI Integration Log";
        GLSetup: Record "General Ledger Setup";
        MockProvider: Codeunit "FXI Mock Exch Rate Provider";
        SyncMgt: Codeunit "FXI Exchange Rate Sync Mgt";
        TargetCurrencies: List of [Code[10]];
        Success: Boolean;
    begin
        // [GIVEN] The mock provider, and target currencies that exist in
        // BC's own Currency table (EUR/GBP ship with CRONUS demo data)
        GLSetup.Get();
        TargetCurrencies.Add('EUR');
        TargetCurrencies.Add('GBP');

        // [WHEN]
        Success := SyncMgt.SyncRates(MockProvider, GLSetup."LCY Code", TargetCurrencies);

        // [THEN] Both currencies succeeded, and the log reflects Completed
        Assert.IsTrue(Success, 'Expected the sync to fully succeed');

        IntegrationLog.SetCurrentKey("Entry No.");
        IntegrationLog.Ascending(false);
        IntegrationLog.FindFirst();
        Assert.AreEqual(IntegrationLog.Status::Completed, IntegrationLog.Status, 'Expected Completed status');
        Assert.AreEqual(2, IntegrationLog."Records Successful", 'Expected both currencies to succeed');
        Assert.AreEqual(0, IntegrationLog."Records Failed", 'Expected no failures');
    end;

    [Test]
    procedure SyncRates_OneCurrencyNotSetUpInBC_ReportsPartialSuccess()
    var
        IntegrationLog: Record "FXI Integration Log";
        GLSetup: Record "General Ledger Setup";
        MockProvider: Codeunit "FXI Mock Exch Rate Provider";
        SyncMgt: Codeunit "FXI Exchange Rate Sync Mgt";
        TargetCurrencies: List of [Code[10]];
        NonexistentCurrencyCode: Code[10];
        Success: Boolean;
    begin
        // [GIVEN] EUR (assumed present) plus a deliberately fabricated
        // currency code guaranteed not to exist in this container's
        // Currency table, rather than assuming any specific real currency
        // (e.g., JPY) happens to be absent
        GLSetup.Get();
        NonexistentCurrencyCode := FindNonexistentCurrencyCode();
        TargetCurrencies.Add('EUR');
        TargetCurrencies.Add(NonexistentCurrencyCode);

        // [WHEN]
        Success := SyncMgt.SyncRates(MockProvider, GLSetup."LCY Code", TargetCurrencies);

        // [THEN]
        Assert.IsFalse(Success, 'Expected overall failure due to one bad currency');

        IntegrationLog.SetCurrentKey("Entry No.");
        IntegrationLog.Ascending(false);
        IntegrationLog.FindFirst();
        Assert.AreEqual(IntegrationLog.Status::"Partial Success", IntegrationLog.Status, 'Expected Partial Success status');
        Assert.AreEqual(1, IntegrationLog."Records Successful", 'Expected exactly one success');
        Assert.AreEqual(1, IntegrationLog."Records Failed", 'Expected exactly one failure');
    end;

    local procedure FindNonexistentCurrencyCode(): Code[10]
    var
        Currency: Record Currency;
        CandidateCode: Code[10];
        i: Integer;
        TempText: Text;
    begin
        for i := 1 to 999 do begin
            TempText := 'ZZ%1';
            CandidateCode := CopyStr(StrSubstNo(TempText, i), 1, MaxStrLen(CandidateCode));
            if not Currency.Get(CandidateCode) then
                exit(CandidateCode);
        end;
        Error('Could not find an unused currency code for this test.');
    end;

    [Test]
    procedure SyncRates_BaseCurrencyNotLCY_Fails()
    var
        GLSetup: Record "General Ledger Setup";
        MockProvider: Codeunit "FXI Mock Exch Rate Provider";
        SyncMgt: Codeunit "FXI Exchange Rate Sync Mgt";
        TargetCurrencies: List of [Code[10]];
    begin
        // [GIVEN] This check only means something when the company has an
        // actual LCY Code configured; if it's blank, the guard is
        // deliberately skipped (documented limitation), so this test only
        // asserts anything meaningful when that precondition holds.
        GLSetup.Get();
        if GLSetup."LCY Code" = '' then
            exit;

        TargetCurrencies.Add('EUR');

        // [WHEN/THEN] Deliberately passing a base currency that cannot be
        // the real LCY code should raise an error, not silently proceed
        asserterror SyncMgt.SyncRates(MockProvider, 'ZZZ', TargetCurrencies);
        Assert.ExpectedError('must match the company');
    end;

    var
        Assert: Codeunit "Library Assert";
}