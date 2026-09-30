namespace FxIntegration.Integration.Test;

using FxIntegration.Integration;
using System.TestLibraries.Utilities;

codeunit 52120 "FXI Frankfurter Live Test"
{
    Subtype = Test;

    // MANUAL/OPTIONAL TEST — this genuinely calls the real internet.
    // Requires the container to have outbound network access, and
    // depends on Frankfurter's service being up. Deliberately NOT
    // representative of the project's core automated suite: run it
    // by hand (CodeLens "Run Test" on this specific procedure) when
    // you want to confirm the live connector still works against the
    // real API's current shape — never rely on it for routine CI-style
    // verification, since a network hiccup would fail it for reasons
    // that have nothing to do with your code.

    [Test]
    procedure GetRates_LiveFrankfurterCall_ReturnsRealRates()
    var
        Provider: Codeunit "FXI Frankfurter Rate Provider";
        Assert: Codeunit "Library Assert";
        TargetCurrencies: List of [Code[10]];
        ResultRates: Dictionary of [Code[10], Decimal];
        Success: Boolean;
    begin
        // [GIVEN] A real request for USD -> EUR, GBP
        TargetCurrencies.Add('EUR');
        TargetCurrencies.Add('GBP');

        // [WHEN] The live Frankfurter API is called
        Success := Provider.GetRates('USD', TargetCurrencies, ResultRates);

        // [THEN] The call succeeded and both currencies came back with
        // plausible (nonzero, positive) rates — not asserting exact
        // values, since real market rates change every day
        Assert.IsTrue(Success, 'Expected the live API call to succeed');
        Assert.IsTrue(ResultRates.ContainsKey('EUR'), 'Expected EUR in the result');
        Assert.IsTrue(ResultRates.ContainsKey('GBP'), 'Expected GBP in the result');
        Assert.IsTrue(ResultRates.Get('EUR') > 0, 'EUR rate should be a positive number');
        Assert.IsTrue(ResultRates.Get('GBP') > 0, 'GBP rate should be a positive number');
    end;
}