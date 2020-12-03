#tag Class
Protected Class App
Inherits Application
	#tag Event
		Sub Open()
		  // INSTANTIATE SENTRY.IO CLASS AND REGISTER DSN
		  Var myDsnStr as Text = "<your-DSN-string>"         //  Example "https://74d53ceed344439dc86c532698e806c1c@o437786.ingest.sentry.io/55345"
		  Var myAppNameStr as String = "<your-app-name>
		  Sentry= new sentryModule.XojoSentry(myDsnStr, myAppNameStr)
		  
		  
		  // FORCE AN EXCEPTION USING THIS METHOD EXAMPLE
		  Call testSentryFunction()
		  
		End Sub
	#tag EndEvent


	#tag Method, Flags = &h0
		Function testSentryFunction() As Boolean
		  Var thisIsBadTimer as Timer
		  thisIsBadTimer.Period = 100
		  
		  
		  // SENTRY EXCEPTION HANDLING
		  Exception err
		    If Not sentryModule.HandleException(err, CurrentMethodName) Then
		      Raise err
		    End If
		    
		    
		    
		    
		    
		End Function
	#tag EndMethod


	#tag Property, Flags = &h0
		sentry As sentryModule.XojoSentry
	#tag EndProperty


	#tag ViewBehavior
	#tag EndViewBehavior
End Class
#tag EndClass
