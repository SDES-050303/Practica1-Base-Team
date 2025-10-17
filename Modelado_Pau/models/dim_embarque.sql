-- Tabla de embarque que muestras los nombres completos de c/embarque

ALTER PROCEDURE dbo.sp_dim_embarque
AS
BEGIN
	SELECT DISTINCT 
		UPPER(TRIM(ISNULL(e.[Descripcion], 'No proporcionado'))) AS Embarque
	FROM [AutopartesO2025].[dbo].[MedioEmbarque] e

	UNION

	SELECT DISTINCT 
		UPPER(TRIM(ISNULL(se.[MedioEmbarque], 'No proporcionado'))) AS Embarque
	FROM [AutopartesO2025].[dbo].[SalidaEncabezado] se
END;
