# Tabla de pruebas — Pixel Store

| # | Operación / entrada | Resultado esperado | Resultado obtenido |
|---|---|---|---|
| 1 | Alta VID-004, nombre válido, precio 250.00, stock 5 | Producto agregado | Pendiente de ejecutar |
| 2 | Alta nuevamente VID-004 | Rechazar código duplicado | Pendiente de ejecutar |
| 3 | Buscar VID-002 | Mostrar Audifonos gamer | Pendiente de ejecutar |
| 4 | Recibir 5 unidades a VID-003 (stock 4) | Stock queda en 9 | Pendiente de ejecutar |
| 5 | Recibir 97 unidades a VID-003 (stock 9) | Rechazar porque excede 100 | Pendiente de ejecutar |
| 6 | Vender 3 unidades de VID-001 a $899.90 | Aplicar 10%; total $2,429.73 | Pendiente de ejecutar |
| 7 | Vender 99 unidades de VID-002 con stock 12 | Rechazar por existencias insuficientes | Pendiente de ejecutar |
| 8 | Resumen después de operaciones | Unidades, valor e ingresos correctos | Pendiente de ejecutar |
| 9 | Guardar, cerrar y cargar | Recuperar el mismo catálogo | Pendiente de ejecutar |
| 10 | Intentar cargar archivo ausente o alterado | Mostrar error y conservar catálogo anterior | Pendiente de ejecutar |

**Importante:** la columna “obtenido” debe completarse después de ejecutar cada prueba en el entorno del laboratorio. No se deben presentar resultados esperados como si ya se hubieran comprobado.
