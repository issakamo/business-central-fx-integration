namespace FxIntegration.Integration;

using Microsoft.Finance.Currency;
using System.Environment;

table 52101 "FXI Integration Setup"
{
    Caption = 'FX Integration Setup';
    DataClassification = CustomerContent;

    fields
    {
        field(1; "Primary Key"; Code[10])
        {
            DataClassification = SystemMetadata;
        }
        field(10; "Base Currency Code"; Code[10])
        {
            DataClassification = CustomerContent;
        }
        field(11; "Provider"; Enum "FXI Provider Type")
        {
            DataClassification = CustomerContent;

            trigger OnValidate()
            begin
                CheckProviderAllowed();
            end;
        }
        field(20; "Enabled"; Boolean)
        {
            DataClassification = CustomerContent;
        }
        field(30; "Last Successful Run"; DateTime)
        {
            Editable = false;
            DataClassification = SystemMetadata;
        }
    }

    keys
    {
        key(PK; "Primary Key")
        {
            Clustered = true;
        }
    }
    procedure CheckProviderAllowed()
    var
        EnvironmentInformation: Codeunit "Environment Information";
    begin
        // The Mock provider writes fixed placeholder rates into the real
        // Currency Exchange Rate table, so it is restricted to sandboxes.
        if (Provider = Provider::Mock) and not EnvironmentInformation.IsSandbox() then
            Error('The Mock provider writes placeholder exchange rates and is only available in sandbox environments.');
    end;
}