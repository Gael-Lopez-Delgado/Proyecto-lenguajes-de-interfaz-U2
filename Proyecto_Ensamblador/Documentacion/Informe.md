# Informe breve 

## 1. Negocio elegido
Se eligió una tienda de videojuegos llamada **Pixel Store**, dedicada a la venta de controles, audífonos, videojuegos y accesorios. El catálogo permite registrar hasta diez productos.

## 2. Regla adicional: descuento por cantidad
Se aplica un **10% de descuento** cuando una venta individual solicita tres o más unidades del mismo producto. Para una cantidad menor a tres, se cobra el importe base. El descuento se calcula sobre `precio_en_centavos × cantidad`; las fracciones de centavo se descartan mediante división entera. El importe final de la venta se suma a los ingresos de la sesión.

Ejemplo: un artículo cuesta $100.00 MXN y se venden 3 unidades. El importe base es $300.00; el descuento es $30.00 y el total es $270.00 MXN.

## 3. Organización de datos en memoria
El programa usa un arreglo de diez elementos del tipo `Product`. Cada registro contiene:
- `pCode`: 8 bytes para el código ABC-123 y terminador nulo.
- `pName`: 26 bytes para el nombre de hasta 25 caracteres y terminador nulo.
- `pPrice`: DWORD con el precio en centavos.
- `pStock`: DWORD con las existencias.

El contador `productCount` indica cuántos registros están ocupados. Los recorridos del catálogo avanzan con `ESI` sumando `SIZEOF Product`. El precio se guarda en centavos para evitar operaciones con punto flotante.

## 4. Formato del archivo
`inventario.dat` es binario. Los primeros cuatro bytes contienen un DWORD con el número de productos. Después se escriben consecutivamente los registros `Product`. Al cargar, se revisa que el contador no supere diez, que la longitud coincida con el tamaño esperado y que los campos básicos estén dentro de rango antes de copiar el contenido al arreglo.

## 5. Decisiones de implementación
- Se captura texto con `ReadString`.
- `ParseUInt` convierte cantidades y opciones validando que solo existan dígitos.
- `ParsePrice` convierte pesos con cero, uno o dos decimales a centavos.
- `PrintUInt` y `PrintMoney` realizan la conversión de enteros a cadenas para mostrarlos con dos decimales.
- La venta verifica existencia, multiplicación y acumulación de ingresos antes de actualizar el inventario.
- `FindProduct`, `ShowInventory` y `ShowSummary` recorren el arreglo usando `ESI`.
- `SaveInventory` y `LoadInventory` usan las rutinas de archivos de Irvine32.

## 6. Fuentes
- Documento de instrucciones del curso: *U2_PROYECTO_ENSAMBLADOR.pdf*, Lenguajes de Interfaz, Unidad 2.
- Kip Irvine, *Assembly Language for x86 Processors*, documentación y ejemplos de la biblioteca Irvine32 (consultar la edición y materiales proporcionados por el docente).
- Microsoft Learn, documentación de MASM y proyectos de Visual Studio: https://learn.microsoft.com/cpp/assembler/masm/microsoft-macro-assembler-reference

