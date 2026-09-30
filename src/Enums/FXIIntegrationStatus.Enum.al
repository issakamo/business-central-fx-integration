namespace FxIntegration.Integration;

enum 52103 "FXI Integration Status"
{
    Extensible = true;
    value(0; Started)
    {
        Caption = 'Started';
    }
    value(1; Completed)
    {
        Caption = 'Completed';
    }
    value(2; "Partial Success")
    {
        Caption = 'Partial Success';
    }
    value(3; Failed)
    {
        Caption = 'Failed';
    }
}