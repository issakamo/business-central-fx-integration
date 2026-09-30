namespace FxIntegration.Integration;

using Microsoft.Finance.Currency;

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
            TableRelation = Currency.Code;
            DataClassification = CustomerContent;
        }
        field(11; "Provider"; Enum "FXI Provider Type")
        {
            DataClassification = CustomerContent;
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
}