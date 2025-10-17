-- Ejemplos de prueba para comparar los datos de ambas bd

-- ENTRADAS
-- 1. Total de articulos de Chevrolet con los folios CF000077 y A003938
-- Dentro de AutoPartes
SELECT 
    e.Folio,
    SUM(d.Total) AS Total_Chevrolet
FROM [AutopartesO2025].[dbo].[EntradaEncabezado] e

LEFT JOIN [AutopartesO2025].[dbo].[EntradaDetalle] d
    ON e.Folio = d.Folio
LEFT JOIN [AutopartesO2025].[dbo].[Articulo] a
    ON d.Articulo = a.Clave
LEFT JOIN [AutopartesO2025].[dbo].[ArticuloGrupo] ag
    ON a.ArticuloGrupo = ag.Clave

WHERE
    UPPER(ISNULL(ag.Descripcion, '')) LIKE '%CHEVROLET%'
    AND e.Folio IN ('CF000077', 'A003938')
GROUP BY e.Folio;

-- Dentro de Proyecto_ES
SELECT 
    e.Folio,
    SUM(e.Total_D) AS Total_Chevrolet
FROM [Proyecto_ES].[dbo].[fact_entrada] e

LEFT JOIN [Proyecto_ES].[dbo].[dim_articulo] a
    ON e.ArticuloID = a.ArticuloID

WHERE 
    UPPER(LTRIM(RTRIM(a.Articulo_Grupo))) = 'CHEVROLET'
    AND e.Folio IN ('CF000077', 'A003938')
GROUP BY e.Folio;

-- 2. Total de entradas que hubo el 12 de Agosto de 2017
-- Dentro de AutoPartes
SELECT 
    COUNT(DISTINCT UPPER(TRIM(e.[Folio]))) AS Cantidad_Entradas
FROM [AutoPartesO2025].[dbo].[EntradaEncabezado] e
WHERE 
    CAST(CONVERT(varchar(8), e.[Fecha], 112) AS INT) = 20170812;

-- Dentro de Proyecto_ES
SELECT 
    COUNT(DISTINCT e.Folio) AS Cantidad_Entradas
FROM [Proyecto_ES].[dbo].[fact_entrada] e
JOIN [Proyecto_ES].[dbo].[dim_time] t
    ON e.TimeID = t.TimeID
WHERE 
    t.Dia = 12
    AND t.Mes = 8
    AND t.Anio = 2017;

-- 3. Cantidad de DEFENSA DEL GOLF GTI dentro de la entrada del folio A003933 
-- Dentro de AutoPartes
SELECT 
    UPPER(TRIM(e.[Folio])) AS Folio,
    SUM(d.[Cantidad]) AS Cantidad_Defensa_GTI
FROM [AutoPartesO2025].[dbo].[EntradaEncabezado] e

LEFT JOIN [AutoPartesO2025].[dbo].[EntradaDetalle] d
    ON e.[Folio] = d.[Folio]
LEFT JOIN [AutoPartesO2025].[dbo].[Articulo] a
    ON d.[Articulo] = a.[Clave]

WHERE 
    UPPER(LTRIM(RTRIM(a.[Descripcion]))) LIKE '%DEFENSA%'
    AND UPPER(LTRIM(RTRIM(a.[Descripcion]))) LIKE '%GOLF%'
    AND UPPER(LTRIM(RTRIM(a.[Descripcion]))) LIKE '%GTI%'
    AND UPPER(TRIM(e.[Folio])) = 'A003933'
GROUP BY UPPER(TRIM(e.[Folio]));

-- Dentro de Proyecto_ES
SELECT 
    e.Folio,
    SUM(e.Cantidad) AS Cantidad_Defensa_GTI
FROM [Proyecto_ES].[dbo].[fact_entrada] e

LEFT JOIN [Proyecto_ES].[dbo].[dim_articulo] a
    ON e.ArticuloID = a.ArticuloID

WHERE 
    UPPER(LTRIM(RTRIM(a.Descripcion))) LIKE '%DEFENSA%'
    AND UPPER(LTRIM(RTRIM(a.Descripcion))) LIKE '%GOLF%'
    AND UPPER(LTRIM(RTRIM(a.Descripcion))) LIKE '%GTI%'
    AND e.Folio = 'A003933'
GROUP BY e.Folio;

-- SALIDAS
-- 1. Cantidad de salidas y total en pesos del cliente 5733
-- Dentro de AutoPartes
SELECT 
    UPPER(TRIM(e.[Cliente])) AS ClienteID,
    COUNT(DISTINCT UPPER(TRIM(e.[Folio]))) AS Cantidad_Salidas,
    SUM(d.[Total]) AS Total_Pesos
FROM [AutoPartesO2025].[dbo].[SalidaEncabezado] e
LEFT JOIN [AutoPartesO2025].[dbo].[SalidaDetalle] d
    ON e.[Folio] = d.[Folio]
WHERE 
    UPPER(TRIM(e.[Cliente])) = '5733'
GROUP BY 
    UPPER(TRIM(e.[Cliente]));

-- Dentro de Proyecto_ES
SELECT 
    e.ClienteID,
    COUNT(DISTINCT e.Folio) AS Cantidad_Salidas,
    SUM(e.Total_D) AS Total_Pesos
FROM [Proyecto_ES].[dbo].[fact_salida] e
WHERE 
    e.ClienteID = '5733'
GROUP BY e.ClienteID;

-- 2. Cantidad de parrillas de salida con el folio A0020915
-- Dentro de AutoPartes
SELECT 
    UPPER(TRIM(e.[Folio])) AS Folio,
    SUM(d.[Cantidad]) AS Cantidad_Parrillas
FROM [AutoPartesO2025].[dbo].[SalidaEncabezado] e

LEFT JOIN [AutoPartesO2025].[dbo].[SalidaDetalle] d
    ON e.[Folio] = d.[Folio]
LEFT JOIN [AutoPartesO2025].[dbo].[Articulo] a
    ON d.[Articulo] = a.[Clave]

WHERE 
    UPPER(LTRIM(RTRIM(a.[Descripcion]))) LIKE '%PARRILLA%'
    AND UPPER(TRIM(e.[Folio])) = 'A0020915'
GROUP BY UPPER(TRIM(e.[Folio]));

-- Dentro de Proyecto_ES
SELECT 
    e.Folio,
    SUM(e.Cantidad) AS Cantidad_Parrillas
FROM [Proyecto_ES].[dbo].[fact_salida] e

LEFT JOIN [Proyecto_ES].[dbo].[dim_articulo] a
    ON e.ArticuloID = a.ArticuloID

WHERE 
    UPPER(LTRIM(RTRIM(a.Descripcion))) LIKE '%PARRILLA%'
    AND e.Folio = 'A0020915'
GROUP BY e.Folio;

-- 3. Total en pesos, cantidad de articulos con respecto a Ford 
-- con los folios A0020927, A0020960 y SA0029433
-- Dentro de AutoPartes
SELECT 
    ag.[Descripcion] AS Marca,
    SUM(d.[Cantidad]) AS Cantidad_Articulos,
    SUM(d.[TotalImporte]) AS Total_Pesos
FROM [AutoPartesO2025].[dbo].[SalidaEncabezado] e

LEFT JOIN [AutoPartesO2025].[dbo].[SalidaDetalle] d
    ON e.[Folio] = d.[Folio]
LEFT JOIN [AutoPartesO2025].[dbo].[Articulo] a
    ON d.[Articulo] = a.[Clave]
LEFT JOIN [AutopartesO2025].[dbo].[ArticuloGrupo] ag
    ON a.[ArticuloGrupo] = ag.[Clave]

WHERE 
    UPPER(LTRIM(RTRIM(ag.[Descripcion]))) = 'FORD'
    AND e.[Folio] IN ('A0020927', 'A0020960', 'SA0029433')
GROUP BY ag.[Descripcion];

-- Dentro de Proyecto_ES
SELECT 
    a.Articulo_Grupo AS Marca,
    SUM(s.Cantidad) AS Cantidad_Articulos,
    SUM(s.Total_Importe_D) AS Total_Pesos
FROM [Proyecto_ES].[dbo].[fact_salida] s

LEFT JOIN [Proyecto_ES].[dbo].[dim_articulo] a
    ON s.ArticuloID = a.ArticuloID
    
WHERE 
    UPPER(LTRIM(RTRIM(a.Articulo_Grupo))) = 'FORD'
    AND s.Folio IN ('A0020927', 'A0020960', 'SA0029433')
GROUP BY a.Articulo_Grupo;