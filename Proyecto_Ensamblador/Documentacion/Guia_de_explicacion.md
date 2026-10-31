# Guía para explicar el código 

## 1. Explicación general
“Mi proyecto es un sistema de ventas e inventario para una tienda de videojuegos. Permite registrar y buscar productos, recibir mercancía, vender, consultar un resumen y guardar o recuperar el catálogo. La regla adicional es un descuento del 10% cuando se compran tres o más unidades del mismo producto.”

## 2. Estructura Product
- Código: 8 bytes, incluyendo el terminador nulo.
- Nombre: 26 bytes, incluyendo el terminador nulo.
- Precio: DWORD en centavos.
- Existencia: DWORD en unidades.
El arreglo `products` reserva espacio para diez registros. `productCount` indica cuántos están activos.

## 3. ReadString y registros
Antes de `ReadString`, `EDX` contiene la dirección del buffer y `ECX` su capacidad máxima. Al regresar, `EAX` contiene la longitud capturada. El texto queda almacenado en el buffer señalado por EDX.

## 4. Conversión de precios
`ParsePrice` procesa cada carácter. Antes del punto acumula pesos; después del punto acumula uno o dos dígitos de centavos. Si hay un solo decimal, lo multiplica por diez. Por ejemplo:
- `185.50` -> 18550 centavos.
- `12.05` -> 1205 centavos.
Rechaza caracteres que no sean dígitos o un único punto y rechaza más de dos decimales.

## 5. Conversión a texto
`PrintUInt` divide repetidamente el número entre diez. El residuo representa el siguiente dígito y se convierte a ASCII sumando `'0'`. Los dígitos se almacenan en orden inverso y luego se imprime la cadena. `PrintMoney` divide entre 100: el cociente son pesos y el residuo son centavos.

## 6. ESI y búsqueda
`FindProduct` inicia ESI en `products`. Compara el código buscado con el campo `pCode` de cada registro. Si no coincide, avanza `SIZEOF Product` bytes. ESI permite recorrer registros consecutivos sin calcular manualmente cada dirección.

## 7. Comparaciones y saltos
- `CMP` compara valores.
- `JE` salta si son iguales.
- `JA` salta si el valor sin signo es mayor.
- `JB` salta si es menor.
Se usan para validar capacidad, código duplicado, precio, cantidad y existencias.

## 8. Venta y actualización atómica
Primero se busca el producto y se valida que la cantidad sea positiva y no supere el stock. Después se calcula el importe y, si corresponde, el descuento. También se valida la suma de ingresos. Solo después de superar todas las validaciones se descuenta el stock y se actualizan los ingresos. Así una venta rechazada no modifica el catálogo.

## 9. CALL, RET y pila
`CALL` transfiere el control a un procedimiento y guarda en la pila la dirección de retorno. `RET` recupera esa dirección para continuar después de la llamada. `USES` hace que MASM genere conservación/restauración de los registros declarados. Los `PUSH` y `POP` deben estar equilibrados.

## 10. Archivos y handle
Un handle es el identificador que devuelve el sistema al abrir o crear un archivo. `CreateOutputFile` devuelve el handle en EAX; `WriteToFile` recibe el handle en EAX, dirección de datos en EDX y cantidad de bytes en ECX. Al regresar, EAX informa los bytes escritos. `ReadFromFile` informa los bytes leídos. El programa comprueba que la cantidad coincida con la esperada.

## 11. Preguntas para practicar
1. ¿Por qué se guarda el precio en centavos y no como decimal?
2. ¿Qué representa `productCount`?
3. ¿Qué datos se pasan a `ReadString`?
4. ¿Cómo se reconoce el punto decimal?
5. ¿Por qué el descuento se calcula con división entera?
6. ¿Qué hace ESI durante un recorrido?
7. ¿Qué diferencia existe entre `JE`, `JA` y `JB`?
8. ¿En qué momento se actualiza el stock durante una venta?
9. ¿Qué hace `CALL` y qué hace `RET`?
10. ¿Qué contiene el archivo `inventario.dat`?
11. ¿Qué se valida al cargar el catálogo?
12. ¿Cuándo se aplica el descuento?

## 12. Antes de la demostración
- Compila en Win32/x86.
- Ejecuta cada caso de la tabla de pruebas.
- Completa “resultado obtenido”.
- Practica una alta válida y una duplicada.
- Practica una venta de 2 unidades (sin descuento) y otra de 3 (con descuento).
- Guarda, cierra y vuelve a cargar el inventario.
- Abre el depurador y sigue `ESI` en `FindProduct`.
