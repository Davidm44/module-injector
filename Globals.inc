;************************
;Main function globals
;***********************
.data
AppName db "Module Injector",0
ClassName db "Injector",0

hwnd HWND ?
msg MSG <>
wnd WNDCLASSEX <> 

hInst HINSTANCE ?

snapshot HANDLE ?
pHandle HANDLE ?
pEntry PROCESSENTRY32 <>

allocMem dd 0

processBuffer db 1024 DUP(0)

kernel32dll db "kernel32.dll",0
floadlibrary db "LoadLibraryA",0

error db "Error",0
error_1 db "Process not found!",0

;********************
;controls                 
;********************
buttonClass db "button",0
editClass db "edit",0
staticClass db "static",0


button1 HWND ?
button1Text db "Inject",0

button2 HWND ?
button2Text db "Browse",0

textbox1 HWND ?
textbox1Text db 0

textbox2 HWND ?
textbox2Text db 0

label1 HWND ?
label1Text db "Process: ",0

label2 HWND ?
label2Text db "DLL: ",0

fileDialog OPENFILENAME <>
filter db "DLL",0,"*.DLL"
buffer db 1024 DUP ( 0 )