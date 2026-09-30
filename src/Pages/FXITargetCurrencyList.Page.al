namespace FxIntegration.Integration;

page 52101 "FXI Target Currency List"
{
    ApplicationArea = All;
    Caption = 'Target Currencies';
    PageType = ListPart;
    SourceTable = "FXI Target Currency";

    layout
    {
        area(Content)
        {
            repeater(Group)
            {
                field("Currency Code"; Rec."Currency Code")
                {
                    ApplicationArea = All;
                    Tooltip = 'Specifies the target currency code.';
                }
            }
        }
    }
}