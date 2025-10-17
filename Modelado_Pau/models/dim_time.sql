-- Tabla de tiempo que une los tiempos de entrada y salida de c/orden

CREATE PROCEDURE sp_dim_time
AS
BEGIN
	SELECT 
		DISTINCT
		-- Convierte la fecha (valor Date) en Int
		CAST(CONVERT(varchar(8), Fecha, 112) AS INT) as TimeID,

		-- Año
		YEAR(oe.Fecha) as Anio, 

		-- Semestre (Caso 1 = Ene-Jun, Caso 2 = Jul-Dic)
		CASE 
			WHEN MONTH(oe.Fecha) BETWEEN 1 AND 6 THEN '1S'
			ELSE '2S'
		END AS Semestre,

		-- Cuatrimestre (Caso 1 = Ene-Abr, Caso 2 = Mayo-Ago, Caso 3 = Sept-Dic)
		CASE
			WHEN MONTH(oe.Fecha) BETWEEN 5 AND 8 THEN '2C'
			WHEN MONTH(oe.Fecha) BETWEEN 1 AND 4 THEN '1C'
			ELSE '3C'
		END AS Cuatrimestre,

		-- Trimestre (Caso 1 = Ene-Mar, Caso 2 = Abr-Jun, Caso 3 = Jul-Sept, Caso 4 = Oct-Dic)
		CONCAT(DATEPART(QUARTER, oe.Fecha), 'T') as Trimestre,

		-- Mes
		MONTH(oe.Fecha) as Mes,

		-- Dia de la semana
		DATENAME(WEEKDAY, oe.Fecha) AS Dia_semana,

		-- Dia
		DAY(oe.Fecha) as Dia

	FROM [AutopartesO2025].[dbo].[OrdEntradaEncabezado] oe

    UNION

    SELECT 
		DISTINCT
		-- Convierte la fecha (valor Date) en Int
		CAST(CONVERT(varchar(8), Fecha, 112) AS INT) as TimeID,

		-- Año
		YEAR(se.Fecha) as Anio, 

		-- Semestre (Caso 1 = Ene-Jun, Caso 2 = Jul-Dic)
		CASE 
			WHEN MONTH(se.Fecha) BETWEEN 1 AND 6 THEN '1S'
			ELSE '2S'
		END AS Semestre,

		-- Cuatrimestre (Caso 1 = Ene-Abr, Caso 2 = Mayo-Ago, Caso 3 = Sept-Dic)
		CASE
			WHEN MONTH(se.Fecha) BETWEEN 5 AND 8 THEN '2C'
			WHEN MONTH(se.Fecha) BETWEEN 1 AND 4 THEN '1C'
			ELSE '3C'
		END AS Cuatrimestre,

		-- Trimestre (Caso 1 = Ene-Mar, Caso 2 = Abr-Jun, Caso 3 = Jul-Sept, Caso 4 = Oct-Dic)
		CONCAT(DATEPART(QUARTER, se.Fecha), 'T') as Trimestre,

		-- Mes
		MONTH(se.Fecha) as Mes,

		-- Dia de la semana
		DATENAME(WEEKDAY, se.Fecha) AS Dia_semana,

		-- Dia
		DAY(se.Fecha) as Dia

	FROM [AutopartesO2025].[dbo].[OrdSalidaEncabezado] se
END;

