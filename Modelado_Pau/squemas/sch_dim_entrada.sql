USE [Proyecto_ES]

CREATE TABLE dim_sub_entrada (
	Folio NVARCHAR (50),
	ClienteID NVARCHAR (50),
	VendedorID NVARCHAR (50),
	TimeID INT,
)

-- Para hacer la relacion entre dim_entrada y fact_entrada ejecute el with,
-- ya que aparecian valores de dim_vendedor vacios o nulos
;WITH Duplicados AS (
    SELECT *,
           ROW_NUMBER() OVER(PARTITION BY Folio ORDER BY (SELECT NULL)) AS rn
    FROM dbo.dim_entrada
)
DELETE FROM Duplicados
WHERE rn > 1;
