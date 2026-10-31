# Pixel Store — Proyecto de inventario MASM x86

Proyecto individual de Lenguajes de Interfaz, Unidad 2. Sistema de consola en MASM x86 de 32 bits con Irvine32.

## Contenido
- `Proyecto_Inventario/main.asm`: código fuente.
- `Inventario/inventario.dat`: catálogo binario de demostración con tres productos.
- `Documentacion/Informe.md`: informe breve.
- `Documentacion/Tabla_de_pruebas.md`: casos de prueba.
- `Documentacion/Guia_de_explicacion.md`: guía para defensa oral.

## Requisitos
- Visual Studio con carga de trabajo de desarrollo de escritorio con C++.
- Componentes de C++ para Windows y herramientas de MASM.
- Biblioteca Irvine32 instalada y configurada.
- Proyecto Win32/x86 (no x64).

## Configuración en Visual Studio
1. Crear un proyecto vacío de C++ para Windows y seleccionar plataforma Win32/x86.
2. En el Explorador de soluciones, agregar `Proyecto_Inventario/main.asm`.
3. En las propiedades del proyecto, habilitar **Microsoft Macro Assembler** en Build Customizations.
4. En propiedades del archivo `.asm`, establecer Item Type como **Microsoft Macro Assembler**.
5. Agregar la carpeta de Irvine32 a Additional Include Directories.
6. Agregar `Irvine32.lib` y `kernel32.lib` en Linker > Input > Additional Dependencies.
7. Agregar la carpeta que contiene `Irvine32.lib` en Additional Library Directories.
8. Compilar en configuración Debug y plataforma Win32.

## Ejecución
- Copiar `Inventario/inventario.dat` al directorio de trabajo desde el que se ejecuta el `.exe`.
- Ejecutar el programa desde Visual Studio o desde la consola.
- El archivo se busca como `inventario.dat` en el directorio de trabajo actual.

## Regla de negocio
10% de descuento en una venta de 3 o más unidades del mismo producto.

## Aviso de validación
Este paquete incluye una base de proyecto y documentación. Antes de entregar, compila y ejecuta en el equipo con Irvine32 del curso, completa la columna “resultado obtenido” y corrige cualquier ajuste de rutas o configuración que requiera tu instalación. El código usa APIs de archivo de Irvine32 y debe verificarse con la versión instalada por el docente.
