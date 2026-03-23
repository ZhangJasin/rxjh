Set excel = CreateObject("Excel.Application")
excel.Visible = False
excel.DisplayAlerts = False

Dim dataDir
dataDir = "D:\works\RXjianghu\rxjianghu1\Mirserver\Mir200\Envir\data"

' Process Buff.xls
WScript.Echo "Processing Buff.xls..."
On Error Resume Next
Set wb = excel.Workbooks.Open(dataDir & "\Buff.xls", , True)  ' 只读打开
If Err.Number <> 0 Then
    WScript.Echo "  Error opening Buff.xls: " & Err.Description
    Err.Clear
Else
    Set sheet = wb.Sheets(1)
    sheet.Cells(1, 14).Value = "Priority"
    sheet.Cells(1, 15).Value = "Overlap"
    sheet.Cells(1, 16).Value = "OverType"
    sheet.Cells(1, 17).Value = "ReplaceGroup"
    sheet.Cells(1, 18).Value = "OffsetGroup"
    sheet.Cells(1, 19).Value = "IgnoreGroup"
    wb.SaveAs dataDir & "\Buff_new.xls"
    wb.Close
    WScript.Echo "  Buff_new.xls created"
End If
On Error GoTo 0

' Process Condition.xls
WScript.Echo "Processing Condition.xls..."
On Error Resume Next
Set wb = excel.Workbooks.Open(dataDir & "\Condition.xls", , True)
If Err.Number <> 0 Then
    WScript.Echo "  Error opening Condition.xls: " & Err.Description
    Err.Clear
Else
    Set sheet = wb.Sheets(1)
    sheet.Cells(1, 1).Value = "//cs"
    sheet.Cells(1, 3).Value = "cs"
    sheet.Cells(1, 4).Value = "cs"
    wb.SaveAs dataDir & "\Condition_new.xls"
    wb.Close
    WScript.Echo "  Condition_new.xls created"
End If
On Error GoTo 0

' Process Item.xls
WScript.Echo "Processing Item.xls..."
On Error Resume Next
Set wb = excel.Workbooks.Open(dataDir & "\Item.xls", , True)
If Err.Number <> 0 Then
    WScript.Echo "  Error opening Item.xls: " & Err.Description
    Err.Clear
Else
    Set sheet = wb.Sheets(1)
    sheet.Cells(1, 12).Value = "Weight"
    sheet.Cells(1, 13).Value = "Anicount"
    sheet.Cells(1, 14).Value = "Reserved"
    sheet.Cells(1, 15).Value = "recycle"
    sheet.Cells(1, 16).Value = "Looks"
    sheet.Cells(1, 17).Value = "Need"
    sheet.Cells(1, 18).Value = "NeedLevel"
    sheet.Cells(1, 19).Value = "Price"
    sheet.Cells(1, 20).Value = "Color"
    sheet.Cells(1, 21).Value = "OverLap"
    sheet.Cells(1, 22).Value = "Suit"
    sheet.Cells(1, 23).Value = "Article"
    sheet.Cells(1, 24).Value = "Job"
    sheet.Cells(1, 25).Value = "effectParam"
    sheet.Cells(1, 26).Value = "Desc"
    sheet.Cells(1, 27).Value = "GetWayInfo"
    sheet.Cells(1, 28).Value = "pickset"
    sheet.Cells(1, 29).Value = "auctionby"
    sheet.Cells(1, 30).Value = "bEffect"
    sheet.Cells(1, 31).Value = "Droplooks"
    sheet.Cells(1, 32).Value = "Grade"
    sheet.Cells(1, 33).Value = "quickUse"
    sheet.Cells(1, 34).Value = "CutDownType"
    sheet.Cells(1, 35).Value = "CutDownTime"
    sheet.Cells(1, 36).Value = "ITEMPAEAM1"
    sheet.Cells(1, 37).Value = "ITEMPAEAM2"
    sheet.Cells(1, 38).Value = "nPaimaiConfig"
    sheet.Cells(1, 39).Value = "Buff"
    sheet.Cells(1, 40).Value = "ConditionId"
    sheet.Cells(1, 41).Value = "nPaimaiStall"
    sheet.Cells(1, 42).Value = "QuickUse"
    sheet.Cells(1, 43).Value = "IsForbitNumUseDlg"
    sheet.Cells(1, 44).Value = "AuctionConditionId"
    sheet.Cells(1, 45).Value = "nQiGongId"
    sheet.Cells(1, 46).Value = "nQiGongLv"
    sheet.Cells(1, 47).Value = "AddWare"
    sheet.Cells(1, 48).Value = "ItemType"
    sheet.Cells(1, 49).Value = "ItemClass"
    sheet.Cells(1, 50).Value = "TipsGroupId"
    sheet.Cells(1, 51).Value = "Subscript"
    sheet.Cells(1, 52).Value = "sBack"
    wb.SaveAs dataDir & "\Item_new.xls"
    wb.Close
    WScript.Echo "  Item_new.xls created"
End If
On Error GoTo 0

excel.Quit
WScript.Echo "All modifications completed!"
WScript.Echo "New files created with _new suffix. Please rename them manually."