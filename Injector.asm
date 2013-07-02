.386 
.model flat,stdcall
option casemap:none

WinMain proto :DWORD,:DWORD,:DWORD,:DWORD
Inject proto :DWORD,:DWORD

include\masm32\include\windows.inc
include\masm32\include\kernel32.inc
include\masm32\include\user32.inc
include\masm32\include\comdlg32.inc

include Globals.inc

includelib\masm32\lib\kernel32.lib
includelib\masm32\lib\user32.lib
includelib\masm32\lib\comdlg32.lib

.data



.code 

	start:
	
	push NULL
	call GetModuleHandle
	
	mov hInst,eax
	invoke WinMain,eax,NULL,NULL,SW_SHOWDEFAULT
	invoke ExitProcess,0
		

WinMain proc hInstance:HINSTANCE, hPrevInstance:HINSTANCE, cmdLine:LPSTR, cmdShow:DWORD

	mov wnd.cbSize,sizeof WNDCLASSEX
	
	mov ebx,CS_HREDRAW
	or ebx,CS_VREDRAW
	
	mov wnd.style, ebx
	mov wnd.lpfnWndProc, offset WndProc
	
	mov ebx,hInstance
	mov wnd.hInstance,ebx
	
	mov wnd.hbrBackground,COLOR_BTNSHADOW
	mov wnd.lpszClassName, offset ClassName
	
	push IDC_ARROW
	push NULL
	call LoadCursor
	
	mov wnd.hCursor,eax
	
	invoke RegisterClassEx,addr wnd
	invoke CreateWindowEx, NULL,addr ClassName,addr AppName,WS_OVERLAPPEDWINDOW,300,300,300,150,NULL,NULL,hInstance,NULL
	
	mov hwnd,eax
	invoke ShowWindow,eax,cmdShow
	
	;FILL OPENFILENAME STRUCT 
	mov fileDialog.lStructSize,sizeof fileDialog
	
	push hwnd
 	pop fileDialog.hwndOwner
 	
 	push hInstance
 	pop fileDialog.hInstance
 	mov fileDialog.lpstrFile,offset buffer
 	mov fileDialog.lpstrFilter,offset filter
 	mov fileDialog.nMaxFile,1024
	
	
	.while TRUE
	
		invoke GetMessage,addr msg,NULL,NULL,NULL
		
		.break .if eax==NULL
		
		
		invoke TranslateMessage, addr msg
		invoke DispatchMessage, addr msg
		
	.endw
	
	mov eax,msg.wParam
	
	Ret	
WinMain endp

WndProc proc hWnd:HWND, Msg:UINT ,wParam:WPARAM, lParam:LPARAM 
	
	.if Msg==WM_CREATE
		mov ebx,WS_CHILD
		or ebx,WS_VISIBLE
		or ebx, WS_BORDER
		or ebx,ES_AUTOHSCROLL
		invoke CreateWindowEx,NULL,addr editClass,NULL,ebx,70,30,100,20,hWnd,0,hInst,NULL ;DLL textbox
		mov textbox1,eax
		
		mov ebx,WS_CHILD
		or ebx,WS_VISIBLE
		or ebx, BS_DEFPUSHBUTTON
		invoke CreateWindowEx,NULL,addr buttonClass,addr button2Text,ebx,190,30,60,20,hWnd,1,hInst,NULL ;browse button
		
		mov ebx,WS_CHILD
		or ebx,WS_VISIBLE
		or ebx, WS_BORDER
		or ebx,ES_AUTOHSCROLL
		invoke CreateWindowEx,NULL,addr editClass,NULL,ebx,70,60,100,20,hWnd,0,hInst,NULL  ;process textbox
		mov textbox2,eax
		
		mov ebx,WS_CHILD
		or ebx,WS_VISIBLE
		or ebx, BS_DEFPUSHBUTTON
		invoke CreateWindowEx,NULL,addr buttonClass,addr button1Text,ebx,190,60,60,20,hWnd,2,hInst,NULL ;inject button
		
		mov ebx,WS_CHILD
		or ebx,WS_VISIBLE
		invoke CreateWindowEx,NULL,addr staticClass,addr label1Text,ebx,5,60,60,20,hWnd,0,hInst,NULL ; process label
		
		mov ebx,WS_CHILD
		or ebx,WS_VISIBLE
		invoke CreateWindowEx,NULL,addr staticClass,addr label2Text,ebx,35,30,30,20,hWnd,0,hInst,NULL ; DLL label
		
	.endif
	
	.if Msg==WM_COMMAND
		mov eax,wParam
		.if eax==1
			invoke GetOpenFileName, addr fileDialog
			.if eax != NULL
				invoke SendMessage,textbox1,WM_SETTEXT,0,addr buffer
			.endif
		.endif
		
		.if eax==2
			invoke GetWindowText,textbox2,addr processBuffer,1024
			invoke Inject, addr buffer,addr processBuffer
		.endif
	.endif
	
	.if Msg==WM_CLOSE
		invoke PostQuitMessage,0
	.endif
	
	invoke DefWindowProc,hWnd,Msg,wParam,lParam
	Ret

WndProc EndP

Inject proc dllpath:DWORD,processName:DWORD
	
	mov pEntry.dwSize,sizeof pEntry
	invoke CreateToolhelp32Snapshot,TH32CS_SNAPALL,0
	
	.if eax
		mov snapshot,eax
		
		invoke Process32First,snapshot,addr pEntry
		.while eax != NULL
		
			mov ebx,offset pEntry.szExeFile
			
			invoke lstrcmpi ,processName,ebx
			.if eax==0
				jmp processFound
			.endif
			
			invoke Process32Next,snapshot,addr pEntry
		.endw
		
		invoke MessageBox,NULL,addr error_1,addr error,MB_OK
		
		Ret
		
processFound:
		mov ebx,pEntry.th32ProcessID
		
		invoke OpenProcess,PROCESS_ALL_ACCESS,0,ebx
		mov pHandle,eax
		.if eax != NULL
			invoke GetModuleHandle,addr kernel32dll
			invoke GetProcAddress,eax,addr floadlibrary
			.if eax != NULL
				mov ebx,eax
				
				invoke VirtualAllocEx,pHandle,0,sizeof dllpath,MEM_COMMIT,PAGE_EXECUTE_READWRITE
				mov allocMem,eax
				
				invoke lstrlen,dllpath
				mov edx,eax
				
				invoke WriteProcessMemory, pHandle,allocMem,dllpath,edx,0
				.if eax != NULL
					mov ecx,allocMem
					invoke CreateRemoteThread,pHandle,0,0,ebx,ecx,0,0
				.endif
				
			.endif
		.endif

	.endif
	
	Ret
Inject EndP

end start
	