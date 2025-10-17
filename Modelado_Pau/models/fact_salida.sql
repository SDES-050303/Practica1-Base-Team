-- Tabla fact principal, registra las salidas

CREATE PROCEDURE sp_fact_salida
AS
BEGIN
    SELECT 
        UPPER(TRIM(e.[Folio])) AS Folio,
        UPPER(TRIM(ISNULL(e.[Cliente], 'No proporcionado'))) AS ClienteID,
        UPPER(TRIM(ISNULL(e.[Vendedor], 'No proporcionado'))) AS VendedorID,
        UPPER(TRIM(d.[Articulo])) AS ArticuloID,
        UPPER(TRIM(ISNULL(d.[DescripcionArticulo], 'No proporcionado'))) AS Descripcion_Articulo,
        UPPER(TRIM(ISNULL(e.[MedioEmbarque], 'No proporcionado'))) AS Embarque,
        CAST(CONVERT(varchar(8), Fecha, 112) AS INT) AS TimeID,

        UPPER(TRIM(e.[Empresa])) AS Empresa,
        UPPER(TRIM(d.[Almacen])) AS Almacen,
        UPPER(TRIM(d.[Ubicacion])) AS Ubicacion,
        d.[Partida],

        UPPER(TRIM(ISNULL(e.[CondicionPago], 'No proporcionado'))) AS Condicion_Pago,
        UPPER(TRIM(e.[Moneda])) AS Moneda,
        d.[Cantidad],
        d.[Precio] AS Precio_Unitario,
        UPPER(TRIM(d.[UMedPartida])) AS Unidad,
        d.[CantidadUMedInv] AS Cantidad_Unidad,

        d.[pctDescuento] AS Pct_Descuento, 
        ISNULL(e.[pctDescuentoGlobal], 0) AS Pct_Descuento_Global,
        d.[pctImpuesto] AS Pct_Impuesto,

        e.[TotalDescuento] AS Total_Descuento,
        d.[TotalDescuento] AS Total_Descuento_D,

        e.[TotalImporte] AS Total_Importe,
        d.[TotalImporte] AS Total_Importe_D,

        e.[TotalImpuesto] AS Total_Impuesto,
        d.[TotalImpuesto] AS Total_Impuesto_D,

        e.[Total] AS Total,
        d.[Total] AS Total_D,

        1 AS Contar_Partidas

    FROM [AutopartesO2025].[dbo].[SalidaEncabezado] e

    LEFT JOIN [AutopartesO2025].[dbo].[SalidaDetalle] d
        ON e.Folio = d.Folio
END;