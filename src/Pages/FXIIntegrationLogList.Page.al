namespace FxIntegration.Integration;

page 52102 "FXI Integration Log List"
{
    ApplicationArea = All;
    Caption = 'FX Integration Log';
    PageType = List;
    SourceTable = "FXI Integration Log";
    UsageCategory = Lists;
    Editable = false;

    layout
    {
        area(Content)
        {
            repeater(Group)
            {
                field("Entry No."; Rec."Entry No.")
                {
                    Tooltip = 'Specifies the unique entry number of the integration log.';
                }
                field("Integration Name"; Rec."Integration Name")
                {
                    Tooltip = 'Specifies the name of the integration.';
                }
                field(Direction; Rec.Direction)
                {
                    Tooltip = 'Specifies the direction of the integration.';
                }
                field("Start Time"; Rec."Start Time")
                {
                    Tooltip = 'Specifies when the integration started.';
                }
                field("End Time"; Rec."End Time")
                {
                    Tooltip = 'Specifies when the integration ended.';
                }
                field(Status; Rec.Status)
                {
                    Tooltip = 'Specifies the status of the integration.';
                    StyleExpr = StatusStyle;
                }
                field("Records Successful"; Rec."Records Successful")
                {
                    Tooltip = 'Specifies the number of records that completed successfully.';
                }
                field("Records Failed"; Rec."Records Failed")
                {
                    Tooltip = 'Specifies the number of records that failed.';
                }
                field("Retry Count"; Rec."Retry Count")
                {
                    Tooltip = 'Specifies the number of times the integration has been retried.';
                }
                field("Error Message"; Rec."Error Message")
                {
                    Tooltip = 'Specifies the error message for the integration.';
                }
            }
        }
    }

    trigger OnAfterGetRecord()
    begin
        case Rec.Status of
            Rec.Status::Failed:
                StatusStyle := 'Unfavorable';
            Rec.Status::"Partial Success":
                StatusStyle := 'Ambiguous';
            else
                StatusStyle := 'Favorable';
        end;
    end;

    var
        StatusStyle: Text;
}