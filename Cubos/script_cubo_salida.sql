CREATE GLOBAL CUBE [Cubo_Salida_Offline]
STORAGE 'C:\Cubo_Salida.cub'
FROM [Cubo_Salida]
(
  MEASURE [Cubo_Salida].[Cantidad],
  MEASURE [Cubo_Salida].[Cantidad Unidad],
  MEASURE [Cubo_Salida].[Fact Salida Count],
  MEASURE [Cubo_Salida].[Partida],
  MEASURE [Cubo_Salida].[Pct Descuento],
  MEASURE [Cubo_Salida].[Pct Descuento Global],
  MEASURE [Cubo_Salida].[Pct Impuesto],
  MEASURE [Cubo_Salida].[Precio Unitario],
  MEASURE [Cubo_Salida].[Total],
  MEASURE [Cubo_Salida].[Total D],
  MEASURE [Cubo_Salida].[Total Descuento],
  MEASURE [Cubo_Salida].[Total Descuento D],
  MEASURE [Cubo_Salida].[Total Importe],
  MEASURE [Cubo_Salida].[Total Importe D],
  MEASURE [Cubo_Salida].[Total Impuesto],
  MEASURE [Cubo_Salida].[Total Impuesto D],

  DIMENSION [Cubo_Salida].[Dim Articulo],
  DIMENSION [Cubo_Salida].[Dim Cliente],
  DIMENSION [Cubo_Salida].[Dim Embarque],
  DIMENSION [Cubo_Salida].[Dim Sub Salida],
  DIMENSION [Cubo_Salida].[Dim Time],
  DIMENSION [Cubo_Salida].[Dim Vendedor]
);
