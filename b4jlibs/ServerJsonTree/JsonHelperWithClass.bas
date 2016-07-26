﻿Type=Class
Version=4.2
ModulesStructureVersion=1
B4J=true
@EndOfDesignText@
'Class module
Sub Class_Globals
	Private mResp As ServletResponse
	Private resMap As Map
	Dim sb_code As StringBuilder,sbCLS As StringBuilder
	Dim flg As Int,nFloor As Int
'	Private lstMaps As List
End Sub

Public Sub Initialize
	
End Sub
Sub tmr_Tick
'	Log("----------"&CRLF&sb_code.ToString&CRLF&"------------")
'	Log("----------"&CRLF&sbCLS.ToString&CRLF&"------------")
	resMap.Put("code",sb_code.ToString&CRLF&CRLF&"'types below"&CRLF&sbCLS.ToString)
	Dim jg As JSONGenerator
	jg.Initialize(resMap)
	mResp.Write(jg.ToString)
	
End Sub

Sub parseJS(jsonstr As String)
	If jsonstr.Length<1 Then Return
	nFloor=-1
	sbCLS.Initialize
	sb_code.Initialize
	Dim jsp As JSONParser
'	lstMaps.Initialize
	Dim isLst As Boolean=False,isMap As Boolean=False
	If jsonstr.CharAt(0)="[" Then
		isLst=True
	Else if jsonstr.CharAt(0)="{" Then
			isMap=True
	End If
	sb_code.Append(getTABS(nFloor)&"Dim jsp As JSONParser"&CRLF&getTABS(nFloor)&"jsp.Initialize(str)"&CRLF&getTABS(nFloor)&"Dim root As ")
	Try
		jsp.Initialize(jsonstr)
		If isLst Then
			sb_code.Append("List = jsp.NextArray"&CRLF)
			parseJSO(jsp.NextArray,"root")
		Else
			sb_code.Append("Map = jsp.NextObject"&CRLF)
			parseJSO(jsp.NextObject,"root")
		End If
	Catch
		Log(LastException)
	End Try
	tmr_Tick
	
End Sub
'分层级
Sub parseJSO(obj As Object,parent As Object)
	nFloor=nFloor+1
	If obj Is List Then
		Dim lst As List=obj
		If lst.Size>0 Then
			sb_code.Append(getTABS(nFloor)&"For Each col"&parent&" As "&getJOType(lst.Get(0))&" in "&parent&CRLF)
			parseJSO(lst.Get(0),"col"&parent)
			sb_code.Append(getTABS(nFloor)&"Next"&CRLF)
		Else
			sb_code.Append(getTABS(nFloor)&"'Empty List"&CRLF)
		End If
	else if obj Is Map Then
		flg=flg+1
		
		Dim m As Map=obj
		Dim tobj2 As Object
		sbCLS.Append(getTABS(nFloor)&"Type typ"&parent&"(")
		sb_code.Append(getTABS(nFloor)&"Dim myItem As typ"&parent&CRLF&getTABS(nFloor)&"myItem.Initialize"&CRLF)
		For Each k As String In m.Keys
			tobj2=m.Get(k)
			If "root".CompareTo(parent)=0 Then sbCLS.Append(k&" as "&getJOType(tobj2)&",") Else sbCLS.Append(parent&"_"&k&" as "&getJOType(tobj2)&",")
			If "root".CompareTo(parent)=0 Then sb_code.Append(getTABS(nFloor)&"myItem."&k&" = "&parent&".Get("""&k&""")"&CRLF) Else sb_code.Append(getTABS(nFloor)&"myItem."&parent&"_"&k&" = "&parent&".Get("""&k&""")"&CRLF)
			parseJSO(tobj2,parent&"_"&k)
		Next
		sbCLS.Remove(sbCLS.Length-1,sbCLS.Length)
		sbCLS.Append(")"&CRLF)		
	End If	
	nFloor=nFloor-1
	Log("nFloor:"&nFloor)
End Sub
Sub getTABS(n As Int) As String
	Dim ret As String=""
	If n>0 Then
		For i=0 To n
			ret=ret&"    "
		Next
	End If
	Return ret
End Sub
Sub getJOType(obj As Object) As String
	Dim ret As String
	If obj Is Int Then
		ret="Int"
	else if obj Is Double Then
		ret="Double"
	Else if obj Is Map Then
		ret="Map"
	Else if obj Is String Then
		ret="String"
	Else 
		ret="Object"
	End If
	Return ret
End Sub
Sub Handle(req As ServletRequest, resp As ServletResponse)
	resp.ContentType = "application/json"
	resp.CharacterEncoding="UTF-8"
	mResp=resp
	resMap.Initialize
	Try
		Dim data() As Byte = Bit.InputStreamToBytes(req.InputStream)
		Dim text As String = BytesToString(data, 0, data.Length, "UTF8")
		
		Dim parser As JSONParser
		parser.Initialize(text)
		Dim squareBracketFound As Boolean
		'check whether we need to call NextArray or NextObject
		For i = 0 To text.Length
			If text.CharAt(i) = "[" Then
				squareBracketFound = True
				Exit
			Else If text.CharAt(i) = "{" Then
				Exit
			End If
		Next
		Dim code As StringBuilder
		code.Initialize
		code.Append("Dim parser As JSONParser").Append(" "&CRLF)
		code.Append("parser.Initialize(str)").Append(" "&CRLF)
		code.Append("Dim root As ")
		Dim root As TreeItem = CreateTreeItem ("")
		If squareBracketFound Then
			BuildTree(parser.NextArray, root, code, "root", "", False, "")
		Else
			BuildTree(parser.NextObject, root, code, "root", "", False, "")
		End If
		Dim sb As StringBuilder
		sb.Initialize
		ConvertTreeToHtml(sb, root, True)
		resMap.Put("tree", sb.ToString)
		resMap.Put("success", True)
		parseJS(text)
	Catch
		resMap.Put("success", False)
		resMap.Put("error", "Error parsing string:" & CRLF & LastException.Message&" str:"&text)
		Dim jg As JSONGenerator
		jg.Initialize(resMap)
		mResp.Write(jg.ToString)
	End Try
	
	
End Sub
'Sub docaller(co As caller)
'	BuildTree(co.element,co.parent,co.code,co.parentName,co.GetFromMap,co.BuildList,co.indent)
'End Sub
Sub BuildTree(element As Object, parent As TreeItem, code As StringBuilder, _
		parentName As String, GetFromMap As String, BuildList As Boolean, indent As String)
	If element Is Map Then
		Dim m As Map = element
		For Each k As String In m.Keys
			Dim ti As TreeItem = CreateTreeItem(k)
		
			If m.Get(k) Is String Then Log("dim "&parent.Text&"_"&k&" as string")
			If m.Get(k) Is Int Then Log("dim "&parent.Text&"_"&k&" as int")
			If m.Get(k) Is Double Then Log("dim "&parent.Text&"_"&k&" as double")
			parent.Children.Add(ti)
			BuildTree(m.Get(k), ti, code, k, parentName & ".Get(""" & k & """)", False, indent)
		Next
	Else If element Is List Then
		Dim l As List = element
		Dim index As Int = 0
		For Each e As Object In l
			Dim ti As TreeItem = CreateTreeItem(index)
			parent.Children.Add(ti)
			Dim stubCode As StringBuilder
			'only write the code for the first item
			If index = 0 Then stubCode = code Else stubCode.Initialize
			BuildTree(e, ti, stubCode, "col" & parentName ,"", index = 0, indent)
			index = index + 1
		Next
	Else
		parent.Text = parent.Text & ": " & element
	End If
End Sub

Private Sub ConvertTreeToHtml(sb As StringBuilder, parent As TreeItem, isRoot As Boolean)
	If isRoot = False Then sb.Append("<li>").Append(EscapeXml(parent.Text))
	If parent.Children.Size > 0 Then
		sb.Append("<ul>")
		For Each ti As TreeItem In parent.Children
			sb.Append(CRLF)
			ConvertTreeToHtml(sb, ti, False)
		Next
		sb.Append("</ul>")
	End If
	If isRoot = False Then sb.Append("</li>")
End Sub
Private Sub CreateTreeItem (text As String) As TreeItem
	Dim ti As TreeItem
	ti.Initialize
	ti.Children.Initialize
	ti.text = text
	Return ti
End Sub
Private Sub EscapeXml(Raw As String) As String
   Dim sb As StringBuilder
   sb.Initialize
   For i = 0 To Raw.Length - 1
     Dim C As Char = Raw.CharAt(i)
     Select C
       Case QUOTE
         sb.Append("&quot;")
       Case "'"
         sb.Append("&apos;")
       Case "<"
         sb.Append("&lt;")
       Case ">"
         sb.Append("&gt;")
       Case "&"
         sb.Append("&amp;")
       Case Else
         sb.Append(C)
     End Select
   Next
   Return sb.ToString
End Sub