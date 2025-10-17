CREATE GLOBAL CUBE [Cubo_Entrada_Offline]
STORAGE 'C:\Cubo_Entrada.cub'
FROM [Cubo_Entrada]
(
  MEASURE [Cubo_Entrada].[Cantidad],
  MEASURE [Cubo_Entrada].[Cantidad Unidad],
  MEASURE [Cubo_Entrada].[Fact Entrada Count],
  MEASURE [Cubo_Entrada].[Partida],
  MEASURE [Cubo_Entrada].[Pct Descuento],
  MEASURE [Cubo_Entrada].[Pct Descuento Global],
  MEASURE [Cubo_Entrada].[Pct Impuesto],
  MEASURE [Cubo_Entrada].[Precio Unitario],
  MEASURE [Cubo_Entrada].[Total],
  MEASURE [Cubo_Entrada].[Total D],
  MEASURE [Cubo_Entrada].[Total Descuento],
  MEASURE [Cubo_Entrada].[Total Descuento D],
  MEASURE [Cubo_Entrada].[Total Importe],
  MEASURE [Cubo_Entrada].[Total Importe D],
  MEASURE [Cubo_Entrada].[Total Impuesto],
  MEASURE [Cubo_Entrada].[Total Impuesto D],

  DIMENSION [Cubo_Entrada].[Dim Articulo],
  DIMENSION [Cubo_Entrada].[Dim Cliente],
  DIMENSION [Cubo_Entrada].[Dim Entrada],
  DIMENSION [Cubo_Entrada].[Dim Time],
  DIMENSION [Cubo_Entrada].[Dim Vendedor]
);
