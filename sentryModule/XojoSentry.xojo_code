#tag Class
Protected Class XojoSentry
	#tag Method, Flags = &h0
		Sub constructor(DSN as Text, appName as String)
		  appNameStr = appName
		  ParseDSN(DSN)
		End Sub
	#tag EndMethod

	#tag Method, Flags = &h21
		Private Function GenerateJSON(mException as RuntimeException, currentFunction as String) As JSONItem
		  Var errDescriptionStr As String = Introspection.GetType(mException).FullName
		  Var stageCodeStr as String = app.StageCode.ToString
		  Var ourAppVerStr as String = App.Version
		  
		  // BUILD STACK TRACE
		  Var stack as new JSONItem
		  Var cstack() as xojo.Core.StackFrame=mException.CallStack
		  for i as integer=cstack.Ubound downto 0
		    dim frame as xojo.Core.StackFrame=cstack(i)
		    dim jframe as new JSONItem
		    dim fname as String=frame.Name
		    jframe.Value("function")=fname
		    jframe.Value("filename")=str(frame.Address)
		    jframe.Value("module")="-"
		    stack.Append jframe
		  next
		  Var stacktrace as new JSONItem
		  stacktrace.Value("frames") = stack
		  
		  // PREDEFINED DATA:
		  Var timestamp as string=d.Year.ToText+"-"+d.Month.ToText+"-"+d.Day.ToText+"T"+d.Hour.ToText+":"+d.Minute.ToText+":"+d.Second.ToText
		  Var j as new JSONItem
		  j.Value("event_id")=GenerateUUID
		  j.Value("message")=currentFunction + chr(10) + errDescriptionStr
		  j.Value("stacktrace")=stacktrace
		  j.Value("timestamp")=timestamp
		  j.Value("release") = ourAppVerStr
		  
		  // TAGS:  USER DEFINED
		  Var tags As new JSONItem
		  tags.Value("culprit")=currentFunction
		  tags.Value("reason") = errDescriptionStr
		  j.Value("tags")=tags
		  
		  // CONTEXT: APP INFO
		  Var contexts as new JSONItem
		  Var appInfoJsonItem as new JSONItem
		  appInfoJsonItem.Value("App Name") = appNameStr
		  appInfoJsonItem.Value("App Version") = ourAppVerStr
		  appInfoJsonItem.Value("Reason") = errDescriptionStr
		  appInfoJsonItem.Value("Function Name") = currentFunction
		  contexts.Value("app info")=appInfoJsonItem
		  
		  // CONTEXT: CLIENT INFO
		  Var storeInfoJsonItem as new JSONItem
		  storeInfoJsonItem.Value("Client IP") = getOurIpAddress()
		  
		  // CONTEXT: CLIENT OPERATING SYSTEM
		  Var osinfo as new JSONItem
		  #if TargetMacOS
		    osinfo.Value("Name") = "OS X"
		    osinfo.Value("Version")= getOsVer()
		  #Elseif TargetWindows
		    osinfo.Value("Name") = "Windows"
		    osinfo.Value("Version") = getOsVer()
		  #Endif
		  contexts.Value("Client OS")=osinfo
		  
		  // LANGUAGE
		  Var runtime as new JSONItem
		  runtime.Value("Name")="Xojo"
		  runtime.Value("Version") = XojoVersionString
		  contexts.Value("Language")=runtime
		  
		  // JSON ROLL UP
		  j.Value("contexts")=contexts
		  Return j
		End Function
	#tag EndMethod

	#tag Method, Flags = &h21
		Private Function GenerateUUID() As String
		  //From https://forum.xojo.com/18029-native-uuid-generation/0
		  'By Kem Tekinay
		  
		  
		  // From http://www.cryptosys.net/pki/uuid-rfc4122.html
		  //
		  // Generate 16 random bytes (=128 bits)
		  // Adjust certain bits according to RFC 4122 section 4.4 as follows:
		  // set the four most significant bits of the 7th byte to 0100'B, so the high nibble is '4'
		  // set the two most significant bits of the 9th byte to 10'B, so the high nibble will be one of '8', '9', 'A', or 'B'.
		  // Convert the adjusted bytes to 32 hexadecimal digits
		  // Add four hyphen '-' characters to obtain blocks of 8, 4, 4, 4 and 12 hex digits
		  // Output the resulting 36-character string "XXXXXXXX-XXXX-XXXX-XXXX-XXXXXXXXXXXX"
		  
		  dim randomBytes as MemoryBlock = Crypto.GenerateRandomBytes(16)
		  randomBytes.LittleEndian = false
		  
		  //
		  // Adjust seventh byte
		  //
		  dim value as byte = randomBytes.Byte(6)
		  value = value and &b00001111 // Turn off the first four bits
		  value = value or &b01000000 // Turn on the second bit
		  randomBytes.Byte(6) = value
		  
		  //
		  // Adjust ninth byte
		  //
		  value = randomBytes.Byte(8)
		  value = value and &b00111111 // Turn off the first two bits
		  value = value or &b10000000 // Turn on the first bit
		  randomBytes.Byte(8) = value
		  
		  
		  dim result as string = EncodeHex(randomBytes)
		  result = result.LeftB(8) + result.MidB(9, 4) + result.MidB(13, 4) + result.MidB(17, 4) + result.RightB(12)
		  
		  return result
		  
		  
		End Function
	#tag EndMethod

	#tag Method, Flags = &h21
		Private Function getOsVer() As String
		  #if TargetMacOS
		    dim sh as new Shell
		    sh.Execute("sw_vers -productVersion")
		    Return sh.Result
		    
		  #Elseif TargetWindows
		    declare Function GetFileVersionInfoA lib "Api-ms-win-core-version-l1-1-0.dll" (filename as cstring,handle as uint32,len as uint32,p as ptr) as Boolean
		    declare Function GetFileVersionInfoSizeA lib "Api-ms-win-core-version-l1-1-0.dll" (filename as cstring,byref o as uint32) as uint32
		    declare Function VerQueryValueA lib "Api-ms-win-core-version-l1-1-0.dll" (block as ptr,name  as cstring,byref buffer as ptr,byref sze as uint32) as Boolean
		    dim o as uint32
		    dim s as uint32=GetFileVersionInfoSizeA("user32.dll",o)
		    dim v as new MemoryBlock(s)
		    dim r as ptr
		    v.UInt32Value(0)=s
		    if GetFileVersionInfoA("User32.dll",0,s,v) then
		      if VerQueryValueA(v,"\",r,o) then
		        dim res as MemoryBlock=r
		        Var winVerStr as String = str(res.UInt16Value(18))+"."+str(res.UInt16Value(16))+" "+str(res.UInt16Value(22))+"."+str(res.UInt16Value(20))
		        Return winVerStr
		      end if
		    end if
		    
		  #Endif
		End Function
	#tag EndMethod

	#tag Method, Flags = &h21
		Private Function getOurIpAddress() As String
		  Var n As NetworkInterface
		  Var ipAddrStr as String
		  for i as Integer = 0 to System.NetworkInterfaceCount - 1
		    ipAddrStr = ipAddrStr + system.NetworkInterface(i).IPAddress + ""
		  next
		  
		  Return ipAddrStr
		End Function
	#tag EndMethod

	#tag Method, Flags = &h21
		Private Sub ParseDSN(dsn as text)
		  // CURRENT DSN FORMAT: {PROTOCOL}://{PUBLIC_KEY}@{HOST}/{PATH}{PROJECT_ID}
		  
		  // LEGACY DSN FORMAT: {PROTOCOL}://{PUBLIC_KEY}:{SECRET_KEY}@{HOST}/{PATH}{PROJECT_ID}
		  Var myPatternStr as String = "(.*):\/\/(.*)\@(.*)\.(.*)\/(.*)\Z(.*)"
		  Var myRegEx as New RegEx
		  Var myRegExMatch As RegExMatch
		  
		  myRegEx.Options.CaseSensitive = False
		  myRegEx.Options.Greedy = False
		  myRegEx.Options.StringBeginIsLineBegin = True
		  myRegEx.Options.StringEndIsLineEnd = True
		  myRegEx.Options.MatchEmpty = True
		  myRegEx.Options.TreatTargetAsOneLine = False
		  myRegEx.Options.DotMatchAll = false
		  myRegEx.SearchPattern = myPatternStr
		  myRegExMatch = myRegEx.Search(dsn)
		  
		  PublicKey= myRegExMatch.SubExpressionString(2).ToText
		  Path = myRegExMatch.SubExpressionString(3).ToText + "."
		  ProjectID= myRegExMatch.SubExpressionString(5).ToText
		  URI = myRegExMatch.SubExpressionString(1).ToText+"://" + path +myRegExMatch.SubExpressionString(4).ToText
		  
		End Sub
	#tag EndMethod

	#tag Method, Flags = &h0
		Function SubmitException(mException as RuntimeException, currentFunction as String) As JSONItem
		  Var sock as new HTTPSecureSocket
		  sock.ConnectionType = sock.TLSv1
		  sock.port = 443
		  sock.Secure = True
		  sock.Address=uri
		  
		  //Grab the current time in GMT
		  Var GMTZone As New xojo.core.TimeZone("GMT")
		  d=new xojo.core.date(xojo.Core.Date.now.SecondsFrom1970,GMTZone)
		  
		  //Build the header to submit
		  Var header as String = "?sentry_version=7&sentry_client=Xojo-Sentry/"+Version+"&" + _
		  "sentry_timestamp="+Format(d.SecondsFrom1970,"#######")+"&" + _
		  "sentry_key="+PublicKey+"&"
		  
		  sock.SetRequestHeader("User-Agent","Xojo-Sentry/"+Version)
		  
		  Var content as JSONItem=GenerateJSON(mException,currentFunction)
		  Var contentStr as String = content.ToString
		  
		  sock.SetRequestContent(contentStr,"application/json")
		  
		  //send off the report
		  Var postStr as String = uri+"/api/"+ProjectID+"/store/"+header
		  Var res as string = sock.SendRequest("POST", postStr, 20)
		  
		  System.DebugLog(sock.ErrorCode.ToString)
		  System.DebugLog(sock.LastErrorCode.ToString)
		  if sock.ErrorCode=0 then
		    Return new JSONItem(res)
		  else
		    Return content
		  end if
		End Function
	#tag EndMethod


	#tag Property, Flags = &h0
		appNameStr As String
	#tag EndProperty

	#tag Property, Flags = &h0
		d As xojo.Core.Date
	#tag EndProperty

	#tag Property, Flags = &h21
		Private Path As Text
	#tag EndProperty

	#tag Property, Flags = &h21
		Private ProjectID As Text
	#tag EndProperty

	#tag Property, Flags = &h21
		Private PublicKey As text
	#tag EndProperty

	#tag Property, Flags = &h21
		Private URI As Text
	#tag EndProperty


	#tag Constant, Name = Version, Type = String, Dynamic = False, Default = \"0.2", Scope = Private
	#tag EndConstant


	#tag ViewBehavior
		#tag ViewProperty
			Name="Index"
			Visible=true
			Group="ID"
			InitialValue="-2147483648"
			Type="Integer"
			EditorType=""
		#tag EndViewProperty
		#tag ViewProperty
			Name="Left"
			Visible=true
			Group="Position"
			InitialValue="0"
			Type="Integer"
			EditorType=""
		#tag EndViewProperty
		#tag ViewProperty
			Name="Name"
			Visible=true
			Group="ID"
			InitialValue=""
			Type="String"
			EditorType=""
		#tag EndViewProperty
		#tag ViewProperty
			Name="Super"
			Visible=true
			Group="ID"
			InitialValue=""
			Type="String"
			EditorType=""
		#tag EndViewProperty
		#tag ViewProperty
			Name="Top"
			Visible=true
			Group="Position"
			InitialValue="0"
			Type="Integer"
			EditorType=""
		#tag EndViewProperty
		#tag ViewProperty
			Name="appNameStr"
			Visible=false
			Group="Behavior"
			InitialValue=""
			Type="String"
			EditorType="MultiLineEditor"
		#tag EndViewProperty
	#tag EndViewBehavior
End Class
#tag EndClass
