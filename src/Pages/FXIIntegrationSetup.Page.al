namespace FxIntegration.Integration;

using Microsoft.Finance.GeneralLedger.Setup;

page 52100 "FXI Integration Setup"
{
    ApplicationArea = All;
    Caption = 'FX Integration Setup';
    PageType = Card;
    SourceTable = "FXI Integration Setup";
    UsageCategory = Administration;
    InsertAllowed = false;
    DeleteAllowed = false;

    layout
    {
        area(Content)
        {
            group(General)
            {
                field("Base Currency Code"; Rec."Base Currency Code")
                {
                    Editable = false;
                    ApplicationArea = All;
                    ToolTip = 'Specifies the base currency used for exchange rate synchronization.';
                }
                field(Provider; Rec.Provider)
                {
                    ApplicationArea = All;
                    ToolTip = 'Specifies the exchange rate provider used for synchronization.';
                }
                field(Enabled; Rec.Enabled)
                {
                    ApplicationArea = All;
                    ToolTip = 'Specifies whether exchange rate synchronization is enabled.';
                }
                field("Last Successful Run"; Rec."Last Successful Run")
                {
                    ApplicationArea = All;
                    ToolTip = 'Specifies the date and time of the last successful exchange rate synchronization.';
                }
            }
            part(TargetCurrencies; "FXI Target Currency List")
            {
                ApplicationArea = All;
            }
        }
    }

    actions
    {
        area(Processing)
        {
            action(SyncNow)
            {
                ApplicationArea = All;
                Caption = 'Sync Now';
                Image = Refresh;
                ToolTip = 'Synchronizes exchange rates for the configured target currencies.';

                trigger OnAction()
                var
                    TargetCurrency: Record "FXI Target Currency";
                    MockProvider: Codeunit "FXI Mock Exch Rate Provider";
                    FrankfurterProvider: Codeunit "FXI Frankfurter Rate Provider";
                    SyncMgt: Codeunit "FXI Exchange Rate Sync Mgt";
                    Provider: Interface "FXI Exchange Rate Provider";
                    TargetCurrencyCodes: List of [Code[10]];
                    Success: Boolean;
                begin
                    if not Rec.Enabled then
                        Error('The FX integration is not enabled. Turn on Enabled to run a sync.');
                    Rec.CheckProviderAllowed();
                    if TargetCurrency.FindSet() then
                        repeat
                            TargetCurrencyCodes.Add(TargetCurrency."Currency Code");
                        until TargetCurrency.Next() = 0;

                    case Rec.Provider of
                        Rec.Provider::Frankfurter:
                            Provider := FrankfurterProvider;
                        Rec.Provider::Mock:
                            Provider := MockProvider;
                    end;

                    Success := SyncMgt.SyncRates(Provider, Rec."Base Currency Code", TargetCurrencyCodes);

                    if Success then begin
                        Rec."Last Successful Run" := CurrentDateTime;
                        Rec.Modify();
                        Message('Sync completed successfully.');
                    end else
                        Message('Sync completed with some failures. See the FX Integration Log for details.');
                end;
            }
            action(ViewLog)
            {
                ApplicationArea = All;
                Caption = 'View Integration Log';
                Image = Log;
                ToolTip = 'Opens the integration log to review recent synchronization activity and errors.';

                trigger OnAction()
                var
                    IntegrationLog: Page "FXI Integration Log List";
                begin
                    IntegrationLog.Run();
                end;
            }
        }
    }

    trigger OnOpenPage()
    begin
        if not Rec.Get() then begin
            Rec.Init();
            Rec.Provider := Rec.Provider::Frankfurter;
            Rec.Insert();
        end;

        // The base must always be the company's LCY, so keep it in step with
        // General Ledger Setup rather than storing a value a user could change.
        if Rec."Base Currency Code" <> GetDefaultLCYCode() then begin
            Rec."Base Currency Code" := GetDefaultLCYCode();
            Rec.Modify();
        end;
    end;

    local procedure GetDefaultLCYCode(): Code[10]
    var
        GLSetup: Record "General Ledger Setup";
    begin
        GLSetup.Get();
        exit(GLSetup."LCY Code");
    end;
}