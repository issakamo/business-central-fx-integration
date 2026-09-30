namespace FxIntegration.Integration;

permissionset 52100 "FXI Integration User"
{
    Caption = 'FX Integration User';
    Assignable = true;

    Permissions =
        tabledata "FXI Integration Log" = R,
        tabledata "FXI Integration Setup" = RIM,
        tabledata "FXI Target Currency" = RIMD,
        table "FXI Integration Log" = X,
        table "FXI Integration Setup" = X,
        table "FXI Target Currency" = X,
        page "FXI Integration Setup" = X,
        page "FXI Target Currency List" = X,
        page "FXI Integration Log List" = X,
        page "FXI Integration Log API" = X;
}