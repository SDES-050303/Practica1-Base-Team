USE Team_autopartes;
GO

/* =========================================================
   0) Utilidad: asegurar miembros "No espesificado"
   =========================================================*/
CREATE OR ALTER PROCEDURE dbo.usp_Ensure_Unknown_Members_NoEspesificado
AS
BEGIN
  SET NOCOUNT ON;
  DECLARE @txt NVARCHAR(50) = N'No espesificado';

  -- Cliente -1
  IF EXISTS (SELECT 1 FROM dbo.DimCliente WHERE ClienteKey=-1)
    UPDATE dbo.DimCliente SET RazonSocial=@txt WHERE ClienteKey=-1;
  ELSE BEGIN
    SET IDENTITY_INSERT dbo.DimCliente ON;
    INSERT dbo.DimCliente(ClienteKey,ClienteNK,RazonSocial,Ciudad,Estado,Pais,Segmento,MonedaPref,CondicionPago)
    VALUES(-1,'-1',@txt,NULL,NULL,NULL,NULL,NULL,NULL);
    SET IDENTITY_INSERT dbo.DimCliente OFF;
  END

  -- Vendedor -1
  IF EXISTS (SELECT 1 FROM dbo.DimVendedor WHERE VendedorKey=-1)
    UPDATE dbo.DimVendedor SET Nombre=@txt WHERE VendedorKey=-1;
  ELSE BEGIN
    SET IDENTITY_INSERT dbo.DimVendedor ON;
    INSERT dbo.DimVendedor(VendedorKey,VendedorNK,Nombre) VALUES(-1,'-1',@txt);
    SET IDENTITY_INSERT dbo.DimVendedor OFF;
  END

  -- Moneda -1
  IF EXISTS (SELECT 1 FROM dbo.DimMoneda WHERE MonedaKey=-1)
    UPDATE dbo.DimMoneda SET Nombre=@txt WHERE MonedaKey=-1;
  ELSE BEGIN
    SET IDENTITY_INSERT dbo.DimMoneda ON;
    INSERT dbo.DimMoneda(MonedaKey,MonedaNK,Nombre) VALUES(-1,'N/A',@txt);
    SET IDENTITY_INSERT dbo.DimMoneda OFF;
  END

  -- CondicionPago -1
  IF EXISTS (SELECT 1 FROM dbo.DimCondicionPago WHERE CondicionPagoKey=-1)
    UPDATE dbo.DimCondicionPago SET Descripcion=@txt WHERE CondicionPagoKey=-1;
  ELSE BEGIN
    SET IDENTITY_INSERT dbo.DimCondicionPago ON;
    INSERT dbo.DimCondicionPago(CondicionPagoKey,CondicionPagoNK,Descripcion) VALUES(-1,'N/A',@txt);
    SET IDENTITY_INSERT dbo.DimCondicionPago OFF;
  END

  -- MedioEmbarque -1
  IF EXISTS (SELECT 1 FROM dbo.DimMedioEmbarque WHERE MedioEmbarqueKey=-1)
    UPDATE dbo.DimMedioEmbarque SET Descripcion=@txt WHERE MedioEmbarqueKey=-1;
  ELSE BEGIN
    SET IDENTITY_INSERT dbo.DimMedioEmbarque ON;
    INSERT dbo.DimMedioEmbarque(MedioEmbarqueKey,MedioEmbarqueNK,Descripcion) VALUES(-1,'N/A',@txt);
    SET IDENTITY_INSERT dbo.DimMedioEmbarque OFF;
  END

  -- Almacen -1
  IF EXISTS (SELECT 1 FROM dbo.DimAlmacen WHERE AlmacenKey=-1)
    UPDATE dbo.DimAlmacen SET Descripcion=@txt WHERE AlmacenKey=-1;
  ELSE BEGIN
    SET IDENTITY_INSERT dbo.DimAlmacen ON;
    INSERT dbo.DimAlmacen(AlmacenKey,AlmacenNK,Descripcion) VALUES(-1,'N/A',@txt);
    SET IDENTITY_INSERT dbo.DimAlmacen OFF;
  END

  -- Artículo '(NA)' vigente
  IF EXISTS (SELECT 1 FROM dbo.DimArticulo WHERE ArticuloNK='(NA)' AND IsCurrent=1)
  BEGIN
    UPDATE dbo.DimArticulo SET Descripcion=@txt WHERE ArticuloNK='(NA)' AND IsCurrent=1;
    IF COL_LENGTH('dbo.DimArticulo','Marca') IS NOT NULL
      UPDATE dbo.DimArticulo SET Marca=@txt WHERE ArticuloNK='(NA)' AND IsCurrent=1;
  END
  ELSE
  BEGIN
    IF COL_LENGTH('dbo.DimArticulo','Marca') IS NOT NULL
      INSERT dbo.DimArticulo(ArticuloNK,SKU,Descripcion,Marca,ValidFrom,ValidTo,IsCurrent)
      VALUES('(NA)',NULL,@txt,@txt,SYSUTCDATETIME(),'9999-12-31',1);
    ELSE
      INSERT dbo.DimArticulo(ArticuloNK,SKU,Descripcion,ValidFrom,ValidTo,IsCurrent)
      VALUES('(NA)',NULL,@txt,SYSUTCDATETIME(),'9999-12-31',1);
  END
END
GO

/* =========================================================
   1) DimFecha (sin recursión)
   =========================================================*/
CREATE OR ALTER PROCEDURE dbo.usp_Load_DimFecha
  @Desde DATE,
  @Hasta DATE
AS
BEGIN
  SET NOCOUNT ON;
  IF @Desde IS NULL OR @Hasta IS NULL
  BEGIN
    RAISERROR('Debe indicar @Desde y @Hasta',16,1);
    RETURN;
  END

  DECLARE @oldDF INT = @@DATEFIRST;
  SET DATEFIRST 1; -- 1=lunes

  ;WITH N AS (
    SELECT TOP (DATEDIFF(DAY,@Desde,@Hasta)+1)
           ROW_NUMBER() OVER (ORDER BY (SELECT NULL)) - 1 AS n
    FROM sys.all_objects a CROSS JOIN sys.all_objects b
  )
  INSERT INTO dbo.DimFecha
    (DateKey,Fecha,Anio,Semestre,Cuatrimestre,Trimestre,MesNumero,MesNombre,Dia,DiaSemanaNumero,DiaSemanaNombre)
  SELECT
    CONVERT(INT, CONVERT(CHAR(8), DATEADD(DAY,n,@Desde), 112)),
    DATEADD(DAY,n,@Desde),
    YEAR(DATEADD(DAY,n,@Desde)),
    CASE WHEN MONTH(DATEADD(DAY,n,@Desde))<=6 THEN 1 ELSE 2 END,
    CASE WHEN MONTH(DATEADD(DAY,n,@Desde))<=4 THEN 1 WHEN MONTH(DATEADD(DAY,n,@Desde))<=8 THEN 2 ELSE 3 END,
    DATEPART(QUARTER, DATEADD(DAY,n,@Desde)),
    MONTH(DATEADD(DAY,n,@Desde)),
    DATENAME(MONTH, DATEADD(DAY,n,@Desde)),
    DAY(DATEADD(DAY,n,@Desde)),
    DATEPART(WEEKDAY, DATEADD(DAY,n,@Desde)),
    DATENAME(WEEKDAY, DATEADD(DAY,n,@Desde))
  FROM N
  WHERE NOT EXISTS (
    SELECT 1 FROM dbo.DimFecha x
    WHERE x.DateKey = CONVERT(INT, CONVERT(CHAR(8), DATEADD(DAY,n,@Desde), 112))
  );

  SET DATEFIRST @oldDF;
END
GO

/* =========================================================
   2) Dimensiones de catálogo (con COLLATE)
   =========================================================*/
CREATE OR ALTER PROCEDURE dbo.usp_Load_DimMoneda
AS
BEGIN
  SET NOCOUNT ON;
  MERGE dbo.DimMoneda AS tgt
  USING (
    SELECT DISTINCT
      LTRIM(RTRIM(m.Clave))               COLLATE DATABASE_DEFAULT AS MonedaNK,
      CAST(m.Descripcion AS VARCHAR(100)) COLLATE DATABASE_DEFAULT AS Nombre
    FROM AutopartesO2025.dbo.Moneda m
    WHERE LTRIM(RTRIM(ISNULL(m.Clave,'')))<>''
  ) src
  ON (tgt.MonedaNK = src.MonedaNK)
  WHEN NOT MATCHED BY TARGET THEN
    INSERT (MonedaNK,Nombre) VALUES (src.MonedaNK,src.Nombre)
  WHEN MATCHED AND ISNULL(tgt.Nombre,'')<>ISNULL(src.Nombre,'') THEN
    UPDATE SET Nombre = src.Nombre;
END
GO

CREATE OR ALTER PROCEDURE dbo.usp_Load_DimCondicionPago
AS
BEGIN
  SET NOCOUNT ON;
  MERGE dbo.DimCondicionPago AS tgt
  USING (
    SELECT DISTINCT
      LTRIM(RTRIM(c.Clave))               COLLATE DATABASE_DEFAULT AS NK,
      CAST(c.Descripcion AS VARCHAR(100)) COLLATE DATABASE_DEFAULT AS Descripcion
    FROM AutopartesO2025.dbo.CondicionPago c
    WHERE LTRIM(RTRIM(ISNULL(c.Clave,'')))<>''
  ) src
  ON (tgt.CondicionPagoNK = src.NK)
  WHEN NOT MATCHED BY TARGET THEN
    INSERT (CondicionPagoNK,Descripcion) VALUES (src.NK,src.Descripcion)
  WHEN MATCHED AND ISNULL(tgt.Descripcion,'')<>ISNULL(src.Descripcion,'') THEN
    UPDATE SET Descripcion = src.Descripcion;
END
GO

CREATE OR ALTER PROCEDURE dbo.usp_Load_DimMedioEmbarque
AS
BEGIN
  SET NOCOUNT ON;
  MERGE dbo.DimMedioEmbarque AS tgt
  USING (
    SELECT DISTINCT
      LTRIM(RTRIM(m.Clave))               COLLATE DATABASE_DEFAULT AS NK,
      CAST(m.Descripcion AS VARCHAR(100)) COLLATE DATABASE_DEFAULT AS Descripcion
    FROM AutopartesO2025.dbo.MedioEmbarque m
    WHERE LTRIM(RTRIM(ISNULL(m.Clave,'')))<>''
  ) src
  ON (tgt.MedioEmbarqueNK = src.NK)
  WHEN NOT MATCHED BY TARGET THEN
    INSERT (MedioEmbarqueNK,Descripcion) VALUES (src.NK,src.Descripcion)
  WHEN MATCHED AND ISNULL(tgt.Descripcion,'')<>ISNULL(src.Descripcion,'') THEN
    UPDATE SET Descripcion = src.Descripcion;
END
GO

CREATE OR ALTER PROCEDURE dbo.usp_Load_DimVendedor
AS
BEGIN
  SET NOCOUNT ON;
  MERGE dbo.DimVendedor AS tgt
  USING (
    SELECT
      LTRIM(RTRIM(v.Clave))               COLLATE DATABASE_DEFAULT AS NK,
      CAST(v.Nombre AS VARCHAR(100))      COLLATE DATABASE_DEFAULT AS Nombre
    FROM AutopartesO2025.dbo.Vendedor v
    WHERE LTRIM(RTRIM(ISNULL(v.Clave,'')))<>''
  ) src
  ON (tgt.VendedorNK = src.NK)
  WHEN NOT MATCHED BY TARGET THEN
    INSERT (VendedorNK,Nombre) VALUES (src.NK,src.Nombre)
  WHEN MATCHED AND ISNULL(tgt.Nombre,'')<>ISNULL(src.Nombre,'') THEN
    UPDATE SET Nombre = src.Nombre;
END
GO

CREATE OR ALTER PROCEDURE dbo.usp_Load_DimCliente
AS
BEGIN
  SET NOCOUNT ON;
  MERGE dbo.DimCliente AS tgt
  USING (
    SELECT
      LTRIM(RTRIM(c.Clave))               COLLATE DATABASE_DEFAULT AS NK,
      CAST(c.RazonSocial   AS VARCHAR(100)) COLLATE DATABASE_DEFAULT AS RazonSocial,
      CAST(c.Ciudad        AS VARCHAR(100)) COLLATE DATABASE_DEFAULT AS Ciudad,
      CAST(c.Estado        AS CHAR(20))     COLLATE DATABASE_DEFAULT AS Estado,
      CAST(c.Pais          AS CHAR(20))     COLLATE DATABASE_DEFAULT AS Pais,
      CAST(c.ClienteTipo   AS CHAR(20))     COLLATE DATABASE_DEFAULT AS Segmento,
      CAST(c.Moneda        AS CHAR(20))     COLLATE DATABASE_DEFAULT AS MonedaPref,
      CAST(c.CondicionPago AS CHAR(20))     COLLATE DATABASE_DEFAULT AS CondicionPago
    FROM AutopartesO2025.dbo.Cliente c
    WHERE LTRIM(RTRIM(ISNULL(c.Clave,'')))<>''
  ) src
  ON (tgt.ClienteNK = src.NK)
  WHEN NOT MATCHED BY TARGET THEN
    INSERT (ClienteNK,RazonSocial,Ciudad,Estado,Pais,Segmento,MonedaPref,CondicionPago)
    VALUES (src.NK,src.RazonSocial,src.Ciudad,src.Estado,src.Pais,src.Segmento,src.MonedaPref,src.CondicionPago)
  WHEN MATCHED AND (
    ISNULL(tgt.RazonSocial,'')<>ISNULL(src.RazonSocial,'') OR
    ISNULL(tgt.Ciudad,'')<>ISNULL(src.Ciudad,'') OR
    ISNULL(tgt.Estado,'')<>ISNULL(src.Estado,'') OR
    ISNULL(tgt.Pais,'')<>ISNULL(src.Pais,'') OR
    ISNULL(tgt.Segmento,'')<>ISNULL(src.Segmento,'') OR
    ISNULL(tgt.MonedaPref,'')<>ISNULL(src.MonedaPref,'') OR
    ISNULL(tgt.CondicionPago,'')<>ISNULL(src.CondicionPago,'')
  )
  THEN UPDATE SET
    RazonSocial = src.RazonSocial,
    Ciudad      = src.Ciudad,
    Estado      = src.Estado,
    Pais        = src.Pais,
    Segmento    = src.Segmento,
    MonedaPref  = src.MonedaPref,
    CondicionPago = src.CondicionPago;
END
GO

CREATE OR ALTER PROCEDURE dbo.usp_Load_DimAlmacen
AS
BEGIN
  SET NOCOUNT ON;
  WITH al AS (
    SELECT DISTINCT LTRIM(RTRIM(Almacen)) COLLATE DATABASE_DEFAULT AS Almacen
    FROM AutopartesO2025.dbo.EntradaDetalle WHERE LTRIM(RTRIM(ISNULL(Almacen,'')))<>''
    UNION
    SELECT DISTINCT LTRIM(RTRIM(Almacen)) COLLATE DATABASE_DEFAULT AS Almacen
    FROM AutopartesO2025.dbo.SalidaDetalle  WHERE LTRIM(RTRIM(ISNULL(Almacen,'')))<>''
  )
  MERGE dbo.DimAlmacen AS tgt
  USING (SELECT Almacen AS NK FROM al) src
  ON (tgt.AlmacenNK = src.NK)
  WHEN NOT MATCHED BY TARGET THEN
    INSERT (AlmacenNK,Descripcion) VALUES (src.NK,NULL);
END
GO

/* =========================================================
   3) DimArticulo (SCD2) con COLLATE
   =========================================================*/
CREATE OR ALTER PROCEDURE dbo.usp_Load_DimArticulo
AS
BEGIN
  SET NOCOUNT ON;

  IF OBJECT_ID('tempdb..#src') IS NOT NULL DROP TABLE #src;

  ;WITH MarcaPrincipal AS (
    SELECT ap.Articulo,
           p.RazonSocial,
           ROW_NUMBER() OVER (PARTITION BY ap.Articulo ORDER BY ap.ProveedorClave) AS rn
    FROM AutopartesO2025.dbo.ArticuloProveedor ap
    LEFT JOIN AutopartesO2025.dbo.Proveedor p ON p.Clave = ap.Proveedor
    WHERE LTRIM(RTRIM(ISNULL(ap.Articulo,'')))<>''
  )
  SELECT
    LTRIM(RTRIM(a.clave))                        COLLATE DATABASE_DEFAULT AS ArticuloNK,
    CAST(a.Descripcion AS VARCHAR(100))          COLLATE DATABASE_DEFAULT AS Descripcion,
    CAST(ISNULL(NULLIF(LTRIM(RTRIM(mp.RazonSocial)),''),'No espesificado') AS VARCHAR(100)) COLLATE DATABASE_DEFAULT AS Marca,
    CAST(a.ArticuloGrupo AS CHAR(20))            COLLATE DATABASE_DEFAULT AS GrupoClave,
    CAST(g.Descripcion   AS VARCHAR(100))        COLLATE DATABASE_DEFAULT AS GrupoDesc,
    CAST(a.ArticuloTipo  AS CHAR(20))            COLLATE DATABASE_DEFAULT AS TipoClave,
    CAST(t.Descripcion   AS VARCHAR(100))        COLLATE DATABASE_DEFAULT AS TipoDesc,
    CAST(a.ArticuloClase AS CHAR(20))            COLLATE DATABASE_DEFAULT AS ClaseClave,
    CAST(c.Descripcion   AS VARCHAR(100))        COLLATE DATABASE_DEFAULT AS ClaseDesc,
    CAST(a.UMedInv       AS CHAR(20))            COLLATE DATABASE_DEFAULT AS UnidadMedida,
    CAST(a.Moneda        AS CHAR(20))            COLLATE DATABASE_DEFAULT AS MonedaArticulo,
    HASHBYTES('MD5',
      CONCAT(
        ISNULL(CAST(a.Descripcion   AS VARCHAR(100)) COLLATE DATABASE_DEFAULT,''),'|',
        ISNULL(CAST(a.ArticuloGrupo AS CHAR(20))     COLLATE DATABASE_DEFAULT,''),'|',ISNULL(CAST(g.Descripcion AS VARCHAR(100)) COLLATE DATABASE_DEFAULT,''),'|',
        ISNULL(CAST(a.ArticuloTipo  AS CHAR(20))     COLLATE DATABASE_DEFAULT,''),'|',ISNULL(CAST(t.Descripcion AS VARCHAR(100)) COLLATE DATABASE_DEFAULT,''),'|',
        ISNULL(CAST(a.ArticuloClase AS CHAR(20))     COLLATE DATABASE_DEFAULT,''),'|',ISNULL(CAST(c.Descripcion AS VARCHAR(100)) COLLATE DATABASE_DEFAULT,''),'|',
        ISNULL(CAST(a.UMedInv       AS CHAR(20))     COLLATE DATABASE_DEFAULT,''),'|',
        ISNULL(CAST(a.Moneda        AS CHAR(20))     COLLATE DATABASE_DEFAULT,''),'|',
        ISNULL(CAST(LTRIM(RTRIM(mp.RazonSocial)) AS VARCHAR(100)) COLLATE DATABASE_DEFAULT,'')
      )
    ) AS NewHash
  INTO #src
  FROM AutopartesO2025.dbo.Articulo a
  LEFT JOIN AutopartesO2025.dbo.ArticuloGrupo g ON g.Clave = a.ArticuloGrupo
  LEFT JOIN AutopartesO2025.dbo.ArticuloTipo  t ON t.Clave = a.ArticuloTipo
  LEFT JOIN AutopartesO2025.dbo.ArticuloClase c ON c.Clave = a.ArticuloClase
  LEFT JOIN MarcaPrincipal mp ON mp.Articulo = a.clave AND mp.rn = 1;

  /* Nuevos NK */
  INSERT INTO dbo.DimArticulo
    (ArticuloNK,Descripcion,Marca,GrupoClave,GrupoDesc,TipoClave,TipoDesc,ClaseClave,ClaseDesc,UnidadMedida,MonedaArticulo,ValidFrom,ValidTo,IsCurrent,HashDiff)
  SELECT s.ArticuloNK,s.Descripcion,s.Marca,s.GrupoClave,s.GrupoDesc,s.TipoClave,s.TipoDesc,s.ClaseClave,s.ClaseDesc,s.UnidadMedida,s.MonedaArticulo,
         SYSUTCDATETIME(),'9999-12-31',1,s.NewHash
  FROM #src s
  LEFT JOIN dbo.DimArticulo d ON d.ArticuloNK = s.ArticuloNK AND d.IsCurrent = 1
  WHERE d.ArticuloNK IS NULL;

  /* Cambios -> usar #chg */
  IF OBJECT_ID('tempdb..#chg') IS NOT NULL DROP TABLE #chg;
  SELECT s.*, d.ArticuloKey, d.HashDiff
  INTO #chg
  FROM #src s
  JOIN dbo.DimArticulo d ON d.ArticuloNK = s.ArticuloNK AND d.IsCurrent = 1
  WHERE d.HashDiff <> s.NewHash;

  -- Cierra versión actual
  UPDATE d
    SET d.ValidTo = SYSUTCDATETIME(),
        d.IsCurrent = 0
  FROM dbo.DimArticulo d
  JOIN #chg ch ON ch.ArticuloKey = d.ArticuloKey;

  -- Inserta nueva versión
  INSERT INTO dbo.DimArticulo
    (ArticuloNK,Descripcion,Marca,GrupoClave,GrupoDesc,TipoClave,TipoDesc,ClaseClave,ClaseDesc,UnidadMedida,MonedaArticulo,ValidFrom,ValidTo,IsCurrent,HashDiff)
  SELECT ArticuloNK,Descripcion,Marca,GrupoClave,GrupoDesc,TipoClave,TipoDesc,ClaseClave,ClaseDesc,UnidadMedida,MonedaArticulo,
         SYSUTCDATETIME(),'9999-12-31',1,NewHash
  FROM #chg;
END
GO

/* =========================================================
   4) Hechos (Entradas / Salidas)
   =========================================================*/
CREATE OR ALTER PROCEDURE dbo.usp_Load_FactEntradas
  @Desde DATE = NULL,
  @Hasta DATE = NULL
AS
BEGIN
  SET NOCOUNT ON;

  ;WITH src AS (
    SELECT
      LTRIM(RTRIM(e.Empresa))        COLLATE DATABASE_DEFAULT AS Empresa,
      LTRIM(RTRIM(e.Folio))          COLLATE DATABASE_DEFAULT AS Folio,
      e.Fecha                        AS FechaHora,
      CONVERT(INT, CONVERT(CHAR(8), e.Fecha, 112))            AS DateKey,
      NULLIF(LTRIM(RTRIM(e.Cliente))  COLLATE DATABASE_DEFAULT,'') AS Cliente,
      NULLIF(LTRIM(RTRIM(e.Vendedor)) COLLATE DATABASE_DEFAULT,'') AS Vendedor,
      NULLIF(LTRIM(RTRIM(e.Moneda))   COLLATE DATABASE_DEFAULT,'') AS Moneda,
      e.TotalImporte,
      e.TotalDescuento,
      e.TotalImpuesto,
      e.Total,
      d.Partida                      AS Renglon,
      NULLIF(LTRIM(RTRIM(d.Articulo)) COLLATE DATABASE_DEFAULT,'') AS Articulo,
      NULLIF(LTRIM(RTRIM(d.Almacen))  COLLATE DATABASE_DEFAULT,'') AS Almacen,
      d.CantidadUMedInv              AS Cantidad_d,
      d.Precio                       AS PrecioUnitario_d,
      d.TotalDescuento               AS Descuento_d,
      d.TotalImpuesto                AS Impuesto_d,
      d.Total                        AS Importe_d
    FROM AutopartesO2025.dbo.EntradaEncabezado e
    JOIN AutopartesO2025.dbo.EntradaDetalle   d ON d.Folio = e.Folio
    WHERE (@Desde IS NULL OR CAST(e.Fecha AS DATE) >= @Desde)
      AND (@Hasta IS NULL OR CAST(e.Fecha AS DATE) <= @Hasta)
  )
  INSERT INTO dbo.FactEntradas
    (DateKey,ArticuloKey,AlmacenKey,ClienteKey,VendedorKey,MonedaKey,
     Empresa,Folio,FechaHora,Subtotal,Impuestos,TotalImporte,TotalDescuento,Total,
     Renglon,Cantidad_d,PrecioUnitario_d,Descuento_d,Impuesto_d,Importe_d)
  SELECT
    s.DateKey,
    ISNULL(da.ArticuloKey, (SELECT TOP 1 ArticuloKey FROM dbo.DimArticulo WHERE ArticuloNK='(NA)' AND IsCurrent=1)),
    ISNULL(al.AlmacenKey, -1),
    ISNULL(cl.ClienteKey, -1),
    ISNULL(ve.VendedorKey, -1),
    ISNULL(mo.MonedaKey, -1),
    s.Empresa,
    s.Folio,
    s.FechaHora,
    s.TotalImporte,        -- Subtotal (encabezado)
    s.TotalImpuesto,       -- Impuestos (encabezado)
    s.TotalImporte,
    s.TotalDescuento,
    s.Total,
    s.Renglon,
    s.Cantidad_d,
    s.PrecioUnitario_d,
    s.Descuento_d,
    s.Impuesto_d,
    s.Importe_d
  FROM src s
  LEFT JOIN dbo.DimArticulo da   ON da.ArticuloNK  = ISNULL(s.Articulo,'(NA)') AND da.IsCurrent = 1
  LEFT JOIN dbo.DimAlmacen  al   ON al.AlmacenNK   = ISNULL(s.Almacen,'N/A')
  LEFT JOIN dbo.DimCliente  cl   ON cl.ClienteNK   = ISNULL(s.Cliente,'-1')
  LEFT JOIN dbo.DimVendedor ve   ON ve.VendedorNK  = ISNULL(s.Vendedor,'-1')
  LEFT JOIN dbo.DimMoneda   mo   ON mo.MonedaNK    = ISNULL(s.Moneda,'N/A')
  WHERE NOT EXISTS (
    SELECT 1 FROM dbo.FactEntradas f
    WHERE f.Empresa = s.Empresa AND f.Folio = s.Folio AND f.Renglon = s.Renglon
  );
END
GO

CREATE OR ALTER PROCEDURE dbo.usp_Load_FactSalidas
  @Desde DATE = NULL,
  @Hasta DATE = NULL
AS
BEGIN
  SET NOCOUNT ON;

  ;WITH src AS (
    SELECT
      LTRIM(RTRIM(s.Empresa))         COLLATE DATABASE_DEFAULT AS Empresa,
      LTRIM(RTRIM(s.Folio))           COLLATE DATABASE_DEFAULT AS Folio,
      s.Fecha                         AS FechaHora,
      CONVERT(INT, CONVERT(CHAR(8), s.Fecha, 112))            AS DateKey,
      NULLIF(LTRIM(RTRIM(s.Cliente))        COLLATE DATABASE_DEFAULT,'') AS Cliente,
      NULLIF(LTRIM(RTRIM(s.Vendedor))       COLLATE DATABASE_DEFAULT,'') AS Vendedor,
      NULLIF(LTRIM(RTRIM(s.Moneda))         COLLATE DATABASE_DEFAULT,'') AS Moneda,
      NULLIF(LTRIM(RTRIM(s.CondicionPago))  COLLATE DATABASE_DEFAULT,'') AS CondicionPago,
      NULLIF(LTRIM(RTRIM(s.MedioEmbarque))  COLLATE DATABASE_DEFAULT,'') AS MedioEmbarque,
      s.TotalImporte,
      s.TotalDescuento,
      s.TotalImpuesto,
      s.Total,
      d.Partida                      AS Renglon,
      NULLIF(LTRIM(RTRIM(d.Articulo)) COLLATE DATABASE_DEFAULT,'') AS Articulo,
      NULLIF(LTRIM(RTRIM(d.Almacen))  COLLATE DATABASE_DEFAULT,'') AS Almacen,
      d.CantidadUMedInv              AS Cantidad_d,
      d.Precio                       AS PrecioUnitario_d,
      d.TotalDescuento               AS Descuento_d,
      d.TotalImpuesto                AS Impuesto_d,
      d.Total                        AS Importe_d
    FROM AutopartesO2025.dbo.SalidaEncabezado s
    JOIN AutopartesO2025.dbo.SalidaDetalle   d ON d.Folio = s.Folio
    WHERE (@Desde IS NULL OR CAST(s.Fecha AS DATE) >= @Desde)
      AND (@Hasta IS NULL OR CAST(s.Fecha AS DATE) <= @Hasta)
  )
  INSERT INTO dbo.FactSalidas
    (DateKey,ArticuloKey,AlmacenKey,ClienteKey,VendedorKey,MonedaKey,CondicionPagoKey,MedioEmbarqueKey,
     Empresa,Folio,FechaHora,Subtotal,Impuestos,TotalImporte,TotalDescuento,Total,
     Renglon,Cantidad_d,PrecioUnitario_d,Descuento_d,Impuesto_d,Importe_d)
  SELECT
    s.DateKey,
    ISNULL(da.ArticuloKey, (SELECT TOP 1 ArticuloKey FROM dbo.DimArticulo WHERE ArticuloNK='(NA)' AND IsCurrent=1)),
    ISNULL(al.AlmacenKey, -1),
    ISNULL(cl.ClienteKey, -1),
    ISNULL(ve.VendedorKey, -1),
    ISNULL(mo.MonedaKey, -1),
    ISNULL(cp.CondicionPagoKey, -1),
    ISNULL(me.MedioEmbarqueKey, -1),
    s.Empresa,
    s.Folio,
    s.FechaHora,
    s.TotalImporte,
    s.TotalImpuesto,
    s.TotalImporte,
    s.TotalDescuento,
    s.Total,
    s.Renglon,
    s.Cantidad_d,
    s.PrecioUnitario_d,
    s.Descuento_d,
    s.Impuesto_d,
    s.Importe_d
  FROM src s
  LEFT JOIN dbo.DimArticulo      da ON da.ArticuloNK       = ISNULL(s.Articulo,'(NA)') AND da.IsCurrent = 1
  LEFT JOIN dbo.DimAlmacen       al ON al.AlmacenNK        = ISNULL(s.Almacen,'N/A')
  LEFT JOIN dbo.DimCliente       cl ON cl.ClienteNK        = ISNULL(s.Cliente,'-1')
  LEFT JOIN dbo.DimVendedor      ve ON ve.VendedorNK       = ISNULL(s.Vendedor,'-1')
  LEFT JOIN dbo.DimMoneda        mo ON mo.MonedaNK         = ISNULL(s.Moneda,'N/A')
  LEFT JOIN dbo.DimCondicionPago cp ON cp.CondicionPagoNK  = ISNULL(s.CondicionPago,'N/A')
  LEFT JOIN dbo.DimMedioEmbarque me ON me.MedioEmbarqueNK  = ISNULL(s.MedioEmbarque,'N/A')
  WHERE NOT EXISTS (
    SELECT 1 FROM dbo.FactSalidas f
    WHERE f.Empresa = s.Empresa AND f.Folio = s.Folio AND f.Renglon = s.Renglon
  );
END
GO

/* =========================================================
   5) ORQUESTADOR
   =========================================================*/
CREATE OR ALTER PROCEDURE dbo.usp_Run_ETL_Autopartes
  @Desde DATE = NULL,
  @Hasta DATE = NULL
AS
BEGIN
  SET NOCOUNT ON;
  SET XACT_ABORT ON;

  DECLARE @d DATE = @Desde, @h DATE = @Hasta;

  IF @d IS NULL OR @h IS NULL
  BEGIN
    ;WITH r AS (
      SELECT MIN(Fecha) AS fmin, MAX(Fecha) AS fmax FROM AutopartesO2025.dbo.EntradaEncabezado
      UNION ALL
      SELECT MIN(Fecha), MAX(Fecha)         FROM AutopartesO2025.dbo.SalidaEncabezado
    )
    SELECT
      @d = ISNULL(@d, (SELECT MIN(fmin) FROM r WHERE fmin IS NOT NULL)),
      @h = ISNULL(@h, (SELECT MAX(fmax) FROM r WHERE fmax IS NOT NULL));
    IF @d IS NULL SET @d = CAST(GETDATE() AS DATE);
    IF @h IS NULL SET @h = CAST(GETDATE() AS DATE);
  END

  PRINT CONCAT('Rango: ', CONVERT(varchar(10),@d,120),' .. ', CONVERT(varchar(10),@h,120));

  EXEC dbo.usp_Ensure_Unknown_Members_NoEspesificado;

  EXEC dbo.usp_Load_DimFecha @Desde=@d, @Hasta=@h;
  EXEC dbo.usp_Load_DimMoneda;
  EXEC dbo.usp_Load_DimCondicionPago;
  EXEC dbo.usp_Load_DimMedioEmbarque;
  EXEC dbo.usp_Load_DimVendedor;
  EXEC dbo.usp_Load_DimCliente;
  EXEC dbo.usp_Load_DimAlmacen;
  EXEC dbo.usp_Load_DimArticulo;

  EXEC dbo.usp_Load_FactEntradas @Desde=@d, @Hasta=@h;
  EXEC dbo.usp_Load_FactSalidas  @Desde=@d, @Hasta=@h;

  PRINT 'ETL OK.';
END
GO
