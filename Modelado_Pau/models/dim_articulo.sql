-- Tabla con todos los articulos

CREATE PROCEDURE dbo.sp_dim_articulo
AS 
BEGIN
	SELECT 
		UPPER(TRIM(a.[clave])) AS ArticuloID,	
		UPPER(TRIM(a.[Descripcion])) AS Descripcion,
		UPPER(TRIM(ISNULL(artt.[Descripcion], 'No proporcionado'))) AS Articulo_Tipo,
		UPPER(TRIM(ISNULL(ag.[Descripcion], 'No proporcionado'))) AS Articulo_Grupo,
		UPPER(TRIM(ISNULL(ac.[Descripcion], 'No proporcionado'))) AS Articulo_Clase,
		a.[Precio]

	FROM [AutopartesO2025].[dbo].[Articulo] a

	LEFT JOIN [AutopartesO2025].[dbo].[ArticuloTipo] artt
		ON a.ArticuloTipo = artt.Clave

	LEFT JOIN [AutopartesO2025].[dbo].[ArticuloGrupo] ag
		ON a.ArticuloGrupo = ag.Clave

	LEFT JOIN [AutopartesO2025].[dbo].[ArticuloClase] ac
		ON a.ArticuloClase = ac.Clave
END;