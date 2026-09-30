namespace FxIntegration.Integration;

table 52100 "FXI Integration Log"
{
    Caption = 'FX Integration Log';
    DataClassification = SystemMetadata;

    fields
    {
        field(1; "Entry No."; Integer)
        {
            AutoIncrement = true;
            DataClassification = SystemMetadata;
        }
        field(10; "Integration Name"; Text[100])
        {
            DataClassification = SystemMetadata;
        }
        field(11; "Direction"; Enum "FXI Integration Direction")
        {
            DataClassification = SystemMetadata;
        }
        field(20; "Start Time"; DateTime)
        {
            DataClassification = SystemMetadata;
        }
        field(21; "End Time"; DateTime)
        {
            DataClassification = SystemMetadata;
        }
        field(30; "Status"; Enum "FXI Integration Status")
        {
            DataClassification = SystemMetadata;
        }
        field(40; "Records Processed"; Integer)
        {
            DataClassification = SystemMetadata;
        }
        field(41; "Records Successful"; Integer)
        {
            DataClassification = SystemMetadata;
        }
        field(42; "Records Failed"; Integer)
        {
            DataClassification = SystemMetadata;
        }
        field(50; "Retry Count"; Integer)
        {
            DataClassification = SystemMetadata;
        }
        field(60; "Error Message"; Text[250])
        {
            DataClassification = SystemMetadata;
        }
    }

    keys
    {
        key(PK; "Entry No.")
        {
            Clustered = true;
        }
    }
}