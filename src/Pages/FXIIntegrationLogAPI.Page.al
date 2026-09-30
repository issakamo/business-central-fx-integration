namespace FxIntegration.Integration;

page 52103 "FXI Integration Log API"
{
    PageType = API;
    APIPublisher = 'issakamo';
    APIGroup = 'fxIntegration';
    APIVersion = 'v1.0';
    EntityName = 'integrationLogEntry';
    EntitySetName = 'integrationLogEntries';
    SourceTable = "FXI Integration Log";
    Editable = false;
    InsertAllowed = false;
    ModifyAllowed = false;
    DeleteAllowed = false;

    layout
    {
        area(Content)
        {
            repeater(Group)
            {
                field(entryNo; Rec."Entry No.")
                {
                    Caption = 'entryNo';
                }
                field(integrationName; Rec."Integration Name")
                {
                    Caption = 'integrationName';
                }
                field(direction; Rec.Direction)
                {
                    Caption = 'direction';
                }
                field(startTime; Rec."Start Time")
                {
                    Caption = 'startTime';
                }
                field(endTime; Rec."End Time")
                {
                    Caption = 'endTime';
                }
                field(status; Rec.Status)
                {
                    Caption = 'status';
                }
                field(recordsProcessed; Rec."Records Processed")
                {
                    Caption = 'recordsProcessed';
                }
                field(recordsSuccessful; Rec."Records Successful")
                {
                    Caption = 'recordsSuccessful';
                }
                field(recordsFailed; Rec."Records Failed")
                {
                    Caption = 'recordsFailed';
                }
                field(retryCount; Rec."Retry Count")
                {
                    Caption = 'retryCount';
                }
                field(errorMessage; Rec."Error Message")
                {
                    Caption = 'errorMessage';
                }
            }
        }
    }
}