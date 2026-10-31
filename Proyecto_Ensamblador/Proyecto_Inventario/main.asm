; ============================================================
; Materia: Lenguajes de Interfaz - Unidad 2
; Alumno: Gael Lopez Delgado
; Proyecto: Sistema de ventas e inventario - Videojuegos
; Plataforma: MASM x86 32 bits + Irvine32
;
; Regla de negocio:
;   Descuento del 10% cuando se venden 3 o mas unidades
;   del mismo producto en una sola operacion.
;   El descuento se calcula sobre el importe base y se
;   truncan las fracciones de centavo.
;
; Formato de archivo:
;   Binario: DWORD cantidad + arreglo de registros Product.
;
; NOTA:
;   El proyecto usa centavos enteros. Los procedimientos de
;   captura validan caracteres y rangos antes de modificar datos.
; ============================================================

INCLUDE Irvine32.inc

MAX_PRODUCTS EQU 10
MAX_STOCK    EQU 100
DISCOUNT_QTY EQU 3
DISCOUNT_PCT EQU 10

Product STRUCT
    pCode  BYTE 8 DUP(0)       ; ABC-123 + terminador
    pName  BYTE 26 DUP(0)      ; 1..25 caracteres + terminador
    pPrice DWORD 0             ; centavos
    pStock DWORD 0
Product ENDS

.data
titleMsg BYTE 13,10,"=== PIXEL STORE: VIDEOJUEGOS ===",13,10,0
menuMsg  BYTE 13,10,"1. Registrar producto",13,10,
              "2. Mostrar inventario",13,10,
              "3. Buscar por codigo",13,10,
              "4. Recibir mercancia",13,10,
              "5. Vender",13,10,
              "6. Resumen",13,10,
              "7. Guardar inventario",13,10,
              "8. Cargar inventario",13,10,
              "0. Salir",13,10,
              "Opcion: ",0
askCode  BYTE "Codigo (ABC-123): ",0
askName  BYTE "Nombre (1-25 caracteres): ",0
askPrice BYTE "Precio MXN (ej. 185.50): ",0
askQty   BYTE "Cantidad entera: ",0
askStock BYTE "Existencia inicial (0-100): ",0
msgFull  BYTE "Catalogo lleno.",13,10,0
msgDup   BYTE "Ese codigo ya existe.",13,10,0
msgBad   BYTE "Entrada invalida. Intente nuevamente.",13,10,0
msgNot   BYTE "Producto no encontrado.",13,10,0
msgOk    BYTE "Operacion realizada.",13,10,0
msgSaved BYTE "Inventario guardado.",13,10,0
msgLoad  BYTE "Inventario cargado.",13,10,0
msgFile  BYTE "No se pudo abrir o validar el archivo.",13,10,0
msgUnsaved BYTE "Hay cambios sin guardar. Guarde antes de salir si lo desea.",13,10,0
msgDiscount BYTE "Descuento por cantidad aplicado (10%).",13,10,0
msgNoDiscount BYTE "No aplica descuento (se requieren 3 unidades).",13,10,0
msgSummary BYTE 13,10,"--- RESUMEN ---",13,10,0
msgUnits BYTE "Unidades disponibles: ",0
msgValue BYTE "Valor del inventario: $",0
msgIncome BYTE "Ingresos de la sesion: $",0
msgMXN BYTE " MXN",13,10,0
msgProduct BYTE "Codigo       Nombre                    Precio       Existencia",13,10,0
spaceMsg BYTE "   ",0
dotMsg BYTE ".",0
crlf BYTE 13,10,0
fileName BYTE "inventario.dat",0

inputBuf BYTE 80 DUP(0)
codeBuf BYTE 8 DUP(0)
nameBuf BYTE 26 DUP(0)
priceCents DWORD ?
qtyValue DWORD ?
choice DWORD ?
productCount DWORD 0
products Product MAX_PRODUCTS DUP(<>)
income DWORD 0
dirty BYTE 0
foundIndex DWORD ?
tempValue DWORD ?
tempValue2 DWORD ?
totalUnits DWORD ?
totalValue DWORD ?
fileHandle DWORD ?
fileBuffer BYTE (4 + MAX_PRODUCTS * SIZEOF Product) DUP(0)
bytesRead DWORD ?
bytesWritten DWORD ?
digitBuffer BYTE 16 DUP(0)
moneyWhole DWORD ?
moneyFrac DWORD ?

.code

; ------------------------------------------------------------
; ReadLine: captura texto en inputBuf.
; Entrada: EDX = direccion destino, ECX = capacidad.
; Salida: EAX = longitud devuelta por ReadString.
; Modifica: EAX, ECX, EDX.
; ------------------------------------------------------------
ReadLine PROC
    call ReadString
    ret
ReadLine ENDP

; ------------------------------------------------------------
; ParseUInt: convierte una cadena decimal sin signo.
; Entrada: ESI = cadena terminada en 0.
; Salida: EAX = valor; EDX=1 si valido, EDX=0 si invalido.
; Modifica: EAX, EBX, ECX, EDX, ESI.
; ------------------------------------------------------------
ParseUInt PROC USES ebx ecx esi
    xor eax,eax
    xor ecx,ecx
    mov edx,1
pu_loop:
    mov bl,[esi]
    cmp bl,0
    je pu_done
    cmp bl,'0'
    jb pu_bad
    cmp bl,'9'
    ja pu_bad
    imul eax,10
    jo pu_bad
    movzx ebx,bl
    sub ebx,'0'
    add eax,ebx
    jo pu_bad
    inc esi
    inc ecx
    jmp pu_loop
pu_done:
    cmp ecx,0
    je pu_bad
    ret
pu_bad:
    xor edx,edx
    xor eax,eax
    ret
ParseUInt ENDP

; ------------------------------------------------------------
; ParsePrice: convierte pesos con 0, 1 o 2 decimales a centavos.
; Entrada: ESI = cadena. Salida EAX=centavos, EDX=1 valido.
; Rechaza signos, separadores, vacio y mas de dos decimales.
; ------------------------------------------------------------
ParsePrice PROC USES ebx ecx esi edi
    LOCAL wholePart:DWORD, fracPart:DWORD, decimals:DWORD, seenDot:DWORD
    mov wholePart,0
    mov fracPart,0
    mov decimals,0
    mov seenDot,0
    mov edx,1
    xor ecx,ecx
pp_loop:
    mov bl,[esi]
    cmp bl,0
    je pp_finish
    cmp bl,'.'
    jne pp_digit
    cmp seenDot,0
    jne pp_bad
    mov seenDot,1
    inc esi
    jmp pp_loop
pp_digit:
    cmp bl,'0'
    jb pp_bad
    cmp bl,'9'
    ja pp_bad
    movzx ebx,bl
    sub ebx,'0'
    cmp seenDot,0
    jne pp_fraction
    mov eax,wholePart
    imul eax,10
    jo pp_bad
    add eax,ebx
    jo pp_bad
    mov wholePart,eax
    jmp pp_next
pp_fraction:
    inc decimals
    cmp decimals,2
    ja pp_bad
    mov eax,fracPart
    imul eax,10
    add eax,ebx
    mov fracPart,eax
pp_next:
    inc ecx
    inc esi
    jmp pp_loop
pp_finish:
    cmp ecx,0
    je pp_bad
    cmp seenDot,0
    je pp_scale
    cmp decimals,0
    je pp_bad
    cmp decimals,1
    jne pp_scale
    imul fracPart,10
pp_scale:
    mov eax,wholePart
    cmp eax,9999
    ja pp_bad
    imul eax,100
    jo pp_bad
    add eax,fracPart
    cmp eax,1
    jb pp_bad
    cmp eax,999999
    ja pp_bad
    mov edx,1
    ret
pp_bad:
    xor eax,eax
    xor edx,edx
    ret
ParsePrice ENDP

; ------------------------------------------------------------
; PrintUInt: imprime EAX como entero decimal usando WriteString.
; Salida: ninguna. Modifica registros de trabajo.
; ------------------------------------------------------------
PrintUInt PROC USES eax ebx ecx edx esi edi
    mov edi,OFFSET digitBuffer
    add edi,SIZEOF digitBuffer
    dec edi
    mov BYTE PTR [edi],0
    mov ebx,10
    cmp eax,0
    jne pu_convert
    dec edi
    mov BYTE PTR [edi],'0'
    jmp pu_print
pu_convert:
    xor edx,edx
    div ebx
    add dl,'0'
    dec edi
    mov [edi],dl
    test eax,eax
    jnz pu_convert
pu_print:
    mov edx,edi
    call WriteString
    ret
PrintUInt ENDP

; ------------------------------------------------------------
; PrintMoney: imprime centavos en EAX como 123.45 MXN.
; ------------------------------------------------------------
PrintMoney PROC USES eax ebx ecx edx
    mov ebx,100
    xor edx,edx
    div ebx
    push edx
    call PrintUInt
    mov edx,OFFSET dotMsg
    call WriteString
    pop eax
    cmp eax,10
    jae pm_frac
    push eax
    mov al,'0'
    call WriteChar
    pop eax
pm_frac:
    call PrintUInt
    mov edx,OFFSET msgMXN
    call WriteString
    ret
PrintMoney ENDP

; ------------------------------------------------------------
; FindProduct: busca codeBuf.
; Salida EAX=indice, EDX=1 encontrado / 0 no encontrado.
; Usa ESI para recorrer arreglo.
; ------------------------------------------------------------
FindProduct PROC USES ebx ecx esi edi
    xor ecx,ecx
    mov esi,OFFSET products
fp_loop:
    cmp ecx,productCount
    jae fp_no
    mov edi,OFFSET codeBuf
    push ecx
    mov ecx,8
    repe cmpsb
    pop ecx
    je fp_yes
    add esi,SIZEOF Product
    inc ecx
    jmp fp_loop
fp_yes:
    mov eax,ecx
    mov edx,1
    ret
fp_no:
    xor eax,eax
    xor edx,edx
    ret
FindProduct ENDP

; ------------------------------------------------------------
; GetCode: captura y valida formato ABC-123.
; ------------------------------------------------------------
GetCode PROC USES eax ebx ecx edx esi
gc_again:
    mov edx,OFFSET askCode
    call WriteString
    mov edx,OFFSET codeBuf
    mov ecx,8
    call ReadLine
    cmp eax,7
    jne gc_bad
    mov esi,OFFSET codeBuf
    mov ecx,3
gc_letters:
    mov al,[esi]
    cmp al,'A'
    jb gc_bad
    cmp al,'Z'
    ja gc_bad
    inc esi
    loop gc_letters
    cmp BYTE PTR [esi],'-'
    jne gc_bad
    inc esi
    mov ecx,3
gc_digits:
    mov al,[esi]
    cmp al,'0'
    jb gc_bad
    cmp al,'9'
    ja gc_bad
    inc esi
    loop gc_digits
    mov BYTE PTR [codeBuf+7],0
    ret
gc_bad:
    mov edx,OFFSET msgBad
    call WriteString
    jmp gc_again
GetCode ENDP

; ------------------------------------------------------------
; RegisterProduct: alta sin duplicados y dentro de limites.
; ------------------------------------------------------------
RegisterProduct PROC USES eax ebx ecx edx esi edi
    cmp productCount,MAX_PRODUCTS
    jb rp_space
    mov edx,OFFSET msgFull
    call WriteString
    ret
rp_space:
    call GetCode
    call FindProduct
    cmp edx,0
    je rp_name
    mov edx,OFFSET msgDup
    call WriteString
    ret
rp_name:
    mov edx,OFFSET askName
    call WriteString
    mov edx,OFFSET nameBuf
    mov ecx,26
    call ReadLine
    cmp eax,1
    jb rp_bad
    cmp eax,25
    ja rp_bad
    mov edx,OFFSET askPrice
    call WriteString
    mov edx,OFFSET inputBuf
    mov ecx,80
    call ReadLine
    mov esi,OFFSET inputBuf
    call ParsePrice
    cmp edx,1
    jne rp_bad
    mov priceCents,eax
    mov edx,OFFSET askStock
    call WriteString
    mov edx,OFFSET inputBuf
    mov ecx,80
    call ReadLine
    mov esi,OFFSET inputBuf
    call ParseUInt
    cmp edx,1
    jne rp_bad
    cmp eax,100
    ja rp_bad
    mov qtyValue,eax
    mov eax,productCount
    imul eax,SIZEOF Product
    mov edi,OFFSET products
    add edi,eax
    mov esi,OFFSET codeBuf
    mov ecx,8
    rep movsb
    mov esi,OFFSET nameBuf
    mov ecx,26
    rep movsb
    mov eax,priceCents
    mov [edi],eax
    mov eax,qtyValue
    mov [edi+4],eax
    inc productCount
    mov dirty,1
    mov edx,OFFSET msgOk
    call WriteString
    ret
rp_bad:
    mov edx,OFFSET msgBad
    call WriteString
    ret
RegisterProduct ENDP

; ------------------------------------------------------------
; ShowInventory: muestra registros con recorrido ESI.
; ------------------------------------------------------------
ShowInventory PROC USES eax ecx edx esi
    mov edx,OFFSET msgProduct
    call WriteString
    mov esi,OFFSET products
    mov ecx,productCount
si_loop:
    cmp ecx,0
    je si_done
    lea edx,[esi].Product.pCode
    call WriteString
    mov edx,OFFSET spaceMsg
    call WriteString
    lea edx,[esi].Product.pName
    call WriteString
    mov edx,OFFSET spaceMsg
    call WriteString
    mov eax,[esi].Product.pPrice
    call PrintMoney
    mov eax,[esi].Product.pStock
    call PrintUInt
    call Crlf
    add esi,SIZEOF Product
    dec ecx
    jmp si_loop
si_done:
    ret
ShowInventory ENDP

; ------------------------------------------------------------
; AskAndFind: captura codigo y busca; EAX indice / EDX bandera.
; ------------------------------------------------------------
AskAndFind PROC
    call GetCode
    call FindProduct
    cmp edx,1
    je af_done
    mov edx,OFFSET msgNot
    call WriteString
af_done:
    ret
AskAndFind ENDP

; ------------------------------------------------------------
; ReceiveStock: suma cantidad sin superar 100.
; ------------------------------------------------------------
ReceiveStock PROC USES eax ebx edx esi
    call AskAndFind
    cmp edx,1
    jne rs_done
    mov foundIndex,eax
    mov edx,OFFSET askQty
    call WriteString
    mov edx,OFFSET inputBuf
    mov ecx,80
    call ReadLine
    mov esi,OFFSET inputBuf
    call ParseUInt
    cmp edx,1
    jne rs_bad
    cmp eax,0
    je rs_bad
    mov ebx,foundIndex
    imul ebx,SIZEOF Product
    mov esi,OFFSET products
    add esi,ebx
    add eax,[esi].Product.pStock
    cmp eax,100
    ja rs_bad
    mov [esi].Product.pStock,eax
    mov dirty,1
    mov edx,OFFSET msgOk
    call WriteString
    jmp rs_done
rs_bad:
    mov edx,OFFSET msgBad
    call WriteString
rs_done:
    ret
ReceiveStock ENDP

; ------------------------------------------------------------
; SellProduct: venta atomica; 10% descuento si cantidad >=3.
; Ingresos se acumulan en centavos.
; ------------------------------------------------------------
SellProduct PROC USES eax ebx ecx edx esi
    call AskAndFind
    cmp edx,1
    jne sp_done
    mov foundIndex,eax
    mov edx,OFFSET askQty
    call WriteString
    mov edx,OFFSET inputBuf
    mov ecx,80
    call ReadLine
    mov esi,OFFSET inputBuf
    call ParseUInt
    cmp edx,1
    jne sp_bad
    cmp eax,0
    je sp_bad
    mov qtyValue,eax
    mov ebx,foundIndex
    imul ebx,SIZEOF Product
    mov esi,OFFSET products
    add esi,ebx
    mov eax,[esi].Product.pStock
    cmp eax,qtyValue
    jb sp_bad
    mov eax,[esi].Product.pPrice
    mul qtyValue
    test edx,edx
    jnz sp_bad
    mov tempValue,eax
    cmp qtyValue,DISCOUNT_QTY
    jb sp_no_discount
    mov edx,OFFSET msgDiscount
    call WriteString
    mov eax,tempValue
    mov ebx,DISCOUNT_PCT
    mul ebx
    mov ebx,100
    div ebx
    sub tempValue,eax
    jmp sp_total
sp_no_discount:
    mov edx,OFFSET msgNoDiscount
    call WriteString
sp_total:
    mov eax,income
    add eax,tempValue
    jc sp_bad
    mov tempValue2,eax
    ; Solo despues de validar todos los calculos se actualiza.
    mov ebx,foundIndex
    imul ebx,SIZEOF Product
    mov esi,OFFSET products
    add esi,ebx
    mov eax,[esi].Product.pStock
    sub eax,qtyValue
    mov [esi].Product.pStock,eax
    mov eax,tempValue2
    mov income,eax
    mov dirty,1
    mov edx,OFFSET msgOk
    call WriteString
    mov eax,tempValue
    call PrintMoney
    jmp sp_done
sp_bad:
    mov edx,OFFSET msgBad
    call WriteString
sp_done:
    ret
SellProduct ENDP

; ------------------------------------------------------------
; ShowSummary: unidades y valor total de inventario + ingresos.
; ------------------------------------------------------------
ShowSummary PROC USES eax ebx ecx edx esi
    mov totalUnits,0
    mov totalValue,0
    mov esi,OFFSET products
    mov ecx,productCount
ss_loop:
    cmp ecx,0
    je ss_print
    mov eax,[esi].Product.pStock
    add totalUnits,eax
    mul [esi].Product.pPrice
    add totalValue,eax
    add esi,SIZEOF Product
    dec ecx
    jmp ss_loop
ss_print:
    mov edx,OFFSET msgSummary
    call WriteString
    mov edx,OFFSET msgUnits
    call WriteString
    mov eax,totalUnits
    call PrintUInt
    call Crlf
    mov edx,OFFSET msgValue
    call WriteString
    mov eax,totalValue
    call PrintMoney
    mov edx,OFFSET msgIncome
    call WriteString
    mov eax,income
    call PrintMoney
    ret
ShowSummary ENDP

; ------------------------------------------------------------
; SaveInventory: DWORD count + registros binarios.
; Comprueba que WriteToFile escriba todos los bytes.
; ------------------------------------------------------------
SaveInventory PROC USES eax ebx ecx edx esi edi
    mov edx,OFFSET fileName
    call CreateOutputFile
    cmp eax,INVALID_HANDLE_VALUE
    je sv_bad
    mov fileHandle,eax
    mov eax,productCount
    mov DWORD PTR fileBuffer,eax
    mov esi,OFFSET products
    mov edi,OFFSET fileBuffer+4
    mov ecx,productCount
    imul ecx,SIZEOF Product
    rep movsb
    mov eax,fileHandle
    mov edx,OFFSET fileBuffer
    mov ecx,4
    mov ebx,productCount
    imul ebx,SIZEOF Product
    add ecx,ebx
    call WriteToFile
    mov bytesWritten,eax
    mov eax,fileHandle
    call CloseFile
    mov eax,productCount
    imul eax,SIZEOF Product
    add eax,4
    cmp bytesWritten,eax
    jne sv_bad
    mov dirty,0
    mov edx,OFFSET msgSaved
    call WriteString
    ret
sv_bad:
    mov edx,OFFSET msgFile
    call WriteString
    ret
SaveInventory ENDP

; ------------------------------------------------------------
; LoadInventory: valida longitud, count y campos basicos antes
; de copiar el catalogo a products.
; ------------------------------------------------------------
LoadInventory PROC USES eax ebx ecx edx esi edi
    mov edx,OFFSET fileName
    call OpenInputFile
    cmp eax,INVALID_HANDLE_VALUE
    je ld_bad
    mov fileHandle,eax
    mov eax,fileHandle
    mov edx,OFFSET fileBuffer
    mov ecx,SIZEOF fileBuffer
    call ReadFromFile
    mov bytesRead,eax
    mov eax,fileHandle
    call CloseFile
    cmp bytesRead,4
    jb ld_bad
    mov eax,DWORD PTR fileBuffer
    cmp eax,MAX_PRODUCTS
    ja ld_bad
    mov ebx,eax
    imul ebx,SIZEOF Product
    add ebx,4
    cmp bytesRead,ebx
    jne ld_bad
    ; Validacion de codigos no vacios, precio y stock.
    mov esi,OFFSET fileBuffer+4
    mov ecx,DWORD PTR fileBuffer
ld_validate:
    cmp ecx,0
    je ld_copy
    cmp BYTE PTR [esi],0
    je ld_bad
    cmp DWORD PTR [esi+34],1
    jb ld_bad
    cmp DWORD PTR [esi+34],999999
    ja ld_bad
    cmp DWORD PTR [esi+38],100
    ja ld_bad
    add esi,SIZEOF Product
    dec ecx
    jmp ld_validate
ld_copy:
    mov eax,DWORD PTR fileBuffer
    mov productCount,eax
    mov esi,OFFSET fileBuffer+4
    mov edi,OFFSET products
    mov ecx,productCount
    imul ecx,SIZEOF Product
    rep movsb
    mov dirty,0
    mov edx,OFFSET msgLoad
    call WriteString
    ret
ld_bad:
    mov edx,OFFSET msgFile
    call WriteString
    ret
LoadInventory ENDP

; ------------------------------------------------------------
; Main menu.
; ------------------------------------------------------------
main PROC
main_loop:
    mov edx,OFFSET titleMsg
    call WriteString
    mov edx,OFFSET menuMsg
    call WriteString
    mov edx,OFFSET inputBuf
    mov ecx,80
    call ReadLine
    mov esi,OFFSET inputBuf
    call ParseUInt
    cmp edx,1
    jne main_bad
    mov choice,eax
    cmp eax,0
    je main_exit
    cmp eax,1
    je do_register
    cmp eax,2
    je do_show
    cmp eax,3
    je do_find
    cmp eax,4
    je do_receive
    cmp eax,5
    je do_sell
    cmp eax,6
    je do_summary
    cmp eax,7
    je do_save
    cmp eax,8
    je do_load
    jmp main_bad
do_register:
    call RegisterProduct
    jmp main_loop
do_show:
    call ShowInventory
    jmp main_loop
do_find:
    call AskAndFind
    cmp edx,1
    jne main_loop
    mov ebx,eax
    imul ebx,SIZEOF Product
    mov esi,OFFSET products
    add esi,ebx
    lea edx,[esi].Product.pName
    call WriteString
    call Crlf
    jmp main_loop
do_receive:
    call ReceiveStock
    jmp main_loop
do_sell:
    call SellProduct
    jmp main_loop
do_summary:
    call ShowSummary
    jmp main_loop
do_save:
    call SaveInventory
    jmp main_loop
do_load:
    call LoadInventory
    jmp main_loop
main_bad:
    mov edx,OFFSET msgBad
    call WriteString
    jmp main_loop
main_exit:
    cmp dirty,0
    je main_end
    mov edx,OFFSET msgUnsaved
    call WriteString
main_end:
    exit
main ENDP

END main
