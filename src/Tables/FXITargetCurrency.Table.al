namespace FxIntegration.Integration;

using Microsoft.Finance.Currency;

table 52102 "FXI Target Currency"
{
    Caption = 'FX Target Currency';
    DataClassification = CustomerContent;

    fields
    {
        field(1; "Currency Code"; Code[10])
        {
            TableRelation = Currency.Code;
            DataClassification = CustomerContent;
        }
    }

    keys
    {
        key(PK; "Currency Code") { Clustered = true; }
    }
}