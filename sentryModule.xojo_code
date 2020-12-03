#tag Module
Protected Module sentryModule
	#tag Method, Flags = &h0
		Function HandleException(err as RuntimeException, source as String) As Boolean
		  // USE INTROSPECTION TO HANDLE EXCEPTION CALL
		  Var runtimeExceptionObj as RuntimeException = err
		  Var currentFunctionStr as String = source
		  
		  // MAKE SENTRY.IO API CALL (SYNC)
		  Call app.Sentry.SubmitException(runtimeExceptionObj, currentFunctionStr)
		  
		  Return True
		End Function
	#tag EndMethod


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
	#tag EndViewBehavior
End Module
#tag EndModule
