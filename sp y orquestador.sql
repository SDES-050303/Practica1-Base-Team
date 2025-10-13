USE Team_autopartes;
GO

/* =========================================================
   1) Utilidades
   =========================================================*/

-- 1.1 Asegurar miembros -1 y '(NA)' con texto "No espesificado"
CREATE OR ALTER PROCEDURE dbo.usp_Ensure_Unknown_Members_NoEspesificado
AS
BEGIN
  SET NOCOUNT ON;

  DECLARE @txt NVARCHAR(50) = N'No espesificado';

  -- DimCliente
  IF EXISTS (SELECT 1 FROM dbo.DimCliente WHERE ClienteKey=-1)
    UPDATE dbo.DimCliente SET RazonSocial=@txt WHERE ClienteKey=-1;
  ELSE BEGIN
    SET IDENTITY_INSERT dbo.DimCliente ON;
    INSERT dbo.DimCliente(ClienteKey,ClienteNK,RazonSocial,Ciudad,Estado,Pais,Segmento,MonedaPref,CondicionPago)
    VALUES(-1,'-1',@txt,NULL,NULL,NULL,NULL,NULL,NULL);
    SET IDENTITY_INSERT dbo.DimCliente OFF;
  END

  -- DimVendedor
  IF EXISTS (SELECT 1 FROM dbo.DimVendedor WHERE VendedorKey=-1)
    UPDATE dbo.DimVendedor SET Nombre=@txt WHERE VendedorKey=-1;
  ELSE BEGIN
    SET IDENTITY_INSERT dbo.DimVendedor ON;
    INSERT dbo.DimVendedor(VendedorKey,VendedorNK,Nombre) VALUES(-1,'-1',@txt);
    SET IDENTITY_INSERT dbo.DimVendedor OFF;
  END

  -- DimMoneda
  IF EXISTS (SELECT 1 FROM dbo.DimMoneda WHERE MonedaKey=-1)
    UPDATE dbo.DimMoneda SET Nombre=@txt WHERE MonedaKey=-1;
  ELSE BEGIN
    SET IDENTITY_INSERT dbo.DimMoneda ON;
    INSERT dbo.DimMoneda(MonedaKey,MonedaNK,Nombre) VALUES(-1,'N/A',@txt);
    SET IDENTITY_INSERT dbo.DimMoneda OFF;
  END

  -- DimCondicionPago
  IF EXISTS (SELECT 1 FROM dbo.DimCondicionPago WHERE CondicionPagoKey=-1)
    UPDATE dbo.DimCondicionPago SET Descripcion=@txt WHERE CondicionPagoKey=-1;
  ELSE BEGIN
    SET IDENTITY_INSERT dbo.DimCondicionPago ON;
    INSERT dbo.DimCondicionPago(CondicionPagoKey,CondicionPagoNK,Descripcion) VALUES(-1,'N/A',@txt);
    SET IDENTITY_INSERT dbo.DimCondicionPago OFF;
  END

  -- DimMedioEmbarque
  IF EXISTS (SELECT 1 FROM dbo.DimMedioEmbarque WHERE MedioEmbarqueKey=-1)
    UPDATE dbo.DimMedioEmbarque SET Descripcion=@txt WHERE MedioEmbarqueKey=-1;
  ELSE BEGIN
    SET IDENTITY_INSERT dbo.DimMedioEmbarque ON;
    INSERT dbo.DimMedioEmbarque(MedioEmbarqueKey,MedioEmbarqueNK,Descripcion) VALUES(-1,'N/A',@txt);
    SET IDENTITY_INSERT dbo.DimMedioEmbarque OFF;
  END

  -- DimAlmacen
  IF EXISTS (SELECT 1 FROM dbo.DimAlmacen WHERE AlmacenKey=-1)
    UPDATE dbo.DimAlmacen SET Descripcion=@txt WHERE AlmacenKey=-1;
  ELSE BEGIN
    SET IDENTITY_INSERT dbo.DimAlmacen ON;
    INSERT dbo.DimAlmacen(AlmacenKey,AlmacenNK,Descripcion) VALUES(-1,'N/A',@txt);
    SET IDENTITY_INSERT dbo.DimAlmacen OFF;
  END

  -- DimArticulo '(NA)'
  IF EXISTS (SELECT 1 FROM dbo.DimArticulo WHERE ArticuloNK='(NA)' AND IsCurrent=1)
  BEGIN
    UPDATE dbo.DimArticulo
      SET Descripcion=@txt
    WHERE ArticuloNK='(NA)' AND IsCurrent=1;

    IF COL_LENGTH('dbo.DimArticulo','Marca') IS NOT NULL
      UPDATE dbo.DimArticulo
        SET Marca=@txt
      WHERE ArticuloNK='(NA)' AND IsCurrent=1;
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
   2) DimFecha por rango
   =========================================================*/
CREATE OR ALTER PROCEDURE dbo.usp_Load_DimFecha
  @Desde DATE,
  @Hasta DATE
AS
BEGIN
  SET NOCOUNT ON;

  ;WITH d AS (
    SELECT @Desde AS Fecha
    UNION ALL
    SELECT DATEADD(DAY,1,Fecha) FROM d WHERE Fecha < @Hasta
  )
  INSERT INTO dbo.DimFecha(DateKey,Fecha,Anio,Semestre,Cuatrimestre,Trimestre,MesNumero,MesNombre,Dia,DiaSemanaNumero,DiaSemanaNombre)
  SELECT
    CONVERT(INT, CONVERT(CHAR(8), Fecha, 112)) AS DateKey,
    Fecha,
    YEAR(Fecha),
    CASE WHEN MONTH(Fecha)<=6 THEN 1 ELSE 2 END AS Semestre,
    CASE WHEN MONTH(Fecha)<=4 THEN 1 WHEN MONTH(Fecha)<=8 THEN 2 ELSE 3 END AS Cuatrimestre,
    DATEPART(QUARTER, Fecha) AS Trimestre,
    MONTH(Fecha) AS MesNumero,
    DATENAME(MONTH, Fecha) AS MesNombre,
    DAY(Fecha) AS Dia,
    (DATEPART(WEEKDAY, Fecha) + 6) % 7 + 1 AS DiaSemanaNumero, -- 1=lunes
    DATENAME(WEEKDAY, Fecha) AS DiaSemanaNombre
  WHERE NOT EXISTS (
    SELECT 1 FROM dbo.DimFecha x WHERE x.DateKey = CONVERT(INT, CONVERT(CHAR(8), Fecha, 112))
  )
  OPTION (MAXRECURSION 0);
END
GO

/* =========================================================
   3) Dimensiones de catálogo
   =========================================================*/

-- 3.1 Moneda
CREATE OR ALTER PROCEDURE dbo.usp_Load_DimMoneda
AS
BEGIN
  SET NOCOUNT ON;

  MERGE dbo.DimMoneda AS tgt
  USING (
    SELECT DISTINCT LTRIM(RTRIM(m.Clave)) AS MonedaNK, m.Descripcion AS Nombre
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

-- 3.2 CondicionPago
CREATE OR ALTER PROCEDURE dbo.usp_Load_DimCondicionPago
AS
BEGIN
  SET NOCOUNT ON;

  MERGE dbo.DimCondicionPago AS tgt
  USING (
    SELECT DISTINCT LTRIM(RTRIM(c.Clave)) AS NK, c.Descripcion
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

-- 3.3 MedioEmbarque
CREATE OR ALTER PROCEDURE dbo.usp_Load_DimMedioEmbarque
AS
BEGIN
  SET NOCOUNT ON;

  MERGE dbo.DimMedioEmbarque AS tgt
  USING (
    SELECT DISTINCT LTRIM(RTRIM(m.Clave)) AS NK, m.Descripcion
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

-- 3.4 Vendedor
CREATE OR ALTER PROCEDURE dbo.usp_Load_DimVendedor
AS
BEGIN
  SET NOCOUNT ON;

  MERGE dbo.DimVendedor AS tgt
  USING (
    SELECT LTRIM(RTRIM(v.Clave)) AS NK, v.Nombre
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

-- 3.5 Cliente (SCD1 mínima)
CREATE OR ALTER PROCEDURE dbo.usp_Load_DimCliente
AS
BEGIN
  SET NOCOUNT ON;

  MERGE dbo.DimCliente AS tgt
  USING (
    SELECT
      LTRIM(RTRIM(c.Clave))          AS NK,
      c.RazonSocial,
      c.Ciudad,
      c.Estado,
      c.Pais,
      c.ClienteTipo                  AS Segmento,
      c.Moneda                       AS MonedaPref,
      c.CondicionPago
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

-- 3.6 Almacen (derivado de detalles)
CREATE OR ALTER PROCEDURE dbo.usp_Load_DimAlmacen
AS
BEGIN
  SET NOCOUNT ON;

  WITH al AS (
    SELECT DISTINCT LTRIM(RTRIM(Almacen)) AS Almacen
    FROM AutopartesO2025.dbo.EntradaDetalle WHERE LTRIM(RTRIM(ISNULL(Almacen,'')))<>''
    UNION
    SELECT DISTINCT LTRIM(RTRIM(Almacen)) AS Almacen
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
   4) DimArticulo (SCD2 light, Marca derivada por proveedor)
   =========================================================*/
CREATE OR ALTER PROCEDURE dbo.usp_Load_DimArticulo
AS
BEGIN
  SET NOCOUNT ON;

  IF OBJECT_ID('tempdb..#src') IS NOT NULL DROP TABLE #src;

  ;WITH MarcaPrincipal AS (
    -- Toma un proveedor "principal" por artículo (el de menor ProveedorClave, si existe)
    SELECT ap.Articulo,
           p.RazonSocial,
           ROW_NUMBER() OVER (PARTITION BY ap.Articulo ORDER BY ap.ProveedorClave) AS rn
    FROM AutopartesO2025.dbo.ArticuloProveedor ap
    LEFT JOIN AutopartesO2025.dbo.Proveedor p
           ON p.Clave = ap.Proveedor
    WHERE LTRIM(RTRIM(ISNULL(ap.Articulo,'')))<>''
  )
  SELECT
    LTRIM(RTRIM(a.clave))          AS ArticuloNK,
    a.Descripcion                  AS Descripcion,
    CAST(ISNULL(NULLIF(LTRIM(RTRIM(mp.RazonSocial)),''),'No espesificado') AS VARCHAR(100)) AS Marca,
    a.ArticuloGrupo                AS GrupoClave,
    g.Descripcion                  AS GrupoDesc,
    a.ArticuloTipo                 AS TipoClave,
    t.Descripcion                  AS TipoDesc,
    a.ArticuloClase                AS ClaseClave,
    c.Descripcion                  AS ClaseDesc,
    a.UMedInv                      AS UnidadMedida,
    a.Moneda                       AS MonedaArticulo,
    HASHBYTES('MD5',
      CONCAT(
        ISNULL(a.Descripcion,''),'|',
        ISNULL(a.ArticuloGrupo,''),'|',ISNULL(g.Descripcion,''),'|',
        ISNULL(a.ArticuloTipo,''),'|',ISNULL(t.Descripcion,''),'|',
        ISNULL(a.ArticuloClase,''),'|',ISNULL(c.Descripcion,''),'|',
        ISNULL(a.UMedInv,''),'|',ISNULL(a.Moneda,''),'|',
        ISNULL(LTRIM(RTRIM(mp.RazonSocial)),'')
      )
    ) AS NewHash
  INTO #src
  FROM AutopartesO2025.dbo.Articulo a
  LEFT JOIN AutopartesO2025.dbo.ArticuloGrupo g ON g.Clave = a.ArticuloGrupo
  LEFT JOIN AutopartesO2025.dbo.ArticuloTipo  t ON t.Clave = a.ArticuloTipo
  LEFT JOIN AutopartesO2025.dbo.ArticuloClase c ON c.Clave = a.ArticuloClase
  LEFT JOIN MarcaPrincipal mp
         ON mp.Articulo = a.clave AND mp.rn = 1;

  -- Inserta nuevos NK
  INSERT INTO dbo.DimArticulo(ArticuloNK,Descripcion,Marca,GrupoClave,GrupoDesc,TipoClave,TipoDesc,ClaseClave,ClaseDesc,UnidadMedida,MonedaArticulo,ValidFrom,ValidTo,IsCurrent,HashDiff)
  SELECT s.ArticuloNK,s.Descripcion,s.Marca,s.GrupoClave,s.GrupoDesc,s.TipoClave,s.TipoDesc,s.ClaseClave,s.ClaseDesc,s.UnidadMedida,s.MonedaArticulo,SYSUTCDATETIME(),'9999-12-31',1,s.NewHash
  FROM #src s
  LEFT JOIN dbo.DimArticulo d ON d.ArticuloNK = s.ArticuloNK AND d.IsCurrent = 1
  WHERE d.ArticuloNK IS NULL;

  -- Cierra versión si cambió Hash y crea nueva
  ;WITH chg AS (
    SELECT s.*, d.ArticuloKey, d.HashDiff
    FROM #src s
    JOIN dbo.DimArticulo d ON d.ArticuloNK = s.ArticuloNK AND d.IsCurrent = 1
    WHERE d.HashDiff <> s.NewHash
  )
  UPDATE d SET d.ValidTo = SYSUTCDATETIME(), d.IsCurrent = 0
  FROM dbo.DimArticulo d
  JOIN chg ON chg.ArticuloKey = d.ArticuloKey;

  INSERT INTO dbo.DimArticulo(ArticuloNK,Descripcion,Marca,GrupoClave,GrupoDesc,TipoClave,TipoDesc,ClaseClave,ClaseDesc,UnidadMedida,MonedaArticulo,ValidFrom,ValidTo,IsCurrent,HashDiff)
  SELECT ArticuloNK,Descripcion,Marca,GrupoClave,GrupoDesc,TipoClave,TipoDesc,ClaseClave,ClaseDesc,UnidadMedida,MonedaArticulo,SYSUTCDATETIME(),'9999-12-31',1,NewHash
  FROM chg;
END
GO

/* =========================================================
   5) Hechos por rango
   =========================================================*/

-- 5.1 Entradas
CREATE OR ALTER PROCEDURE dbo.usp_Load_FactEntradas
  @Desde DATE = NULL,
  @Hasta DATE = NULL
AS
BEGIN
  SET NOCOUNT ON;

  ;WITH src AS (
    SELECT
      LTRIM(RTRIM(e.Empresa))        AS Empresa,
      LTRIM(RTRIM(e.Folio))          AS Folio,
      e.Fecha                        AS FechaHora,
      CONVERT(INT, CONVERT(CHAR(8), e.Fecha, 112)) AS DateKey,
      NULLIF(LTRIM(RTRIM(e.Cliente)),'')   AS Cliente,
      NULLIF(LTRIM(RTRIM(e.Vendedor)),'')  AS Vendedor,
      NULLIF(LTRIM(RTRIM(e.Moneda)),'')    AS Moneda,
      e.TotalImporte,
      e.TotalDescuento,
      e.TotalImpuesto,
      e.Total,
      d.Partida                      AS Renglon,
      NULLIF(LTRIM(RTRIM(d.Articulo)),'')  AS Articulo,
      NULLIF(LTRIM(RTRIM(d.Almacen)),'')   AS Almacen,
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
    s.TotalImporte,        -- Subtotal tomado como TotalImporte del encabezado
    s.TotalImpuesto,       -- Impuestos
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
  LEFT JOIN dbo.DimArticulo da   ON da.ArticuloNK  = s.Articulo AND da.IsCurrent = 1
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

-- 5.2 Salidas
CREATE OR ALTER PROCEDURE dbo.usp_Load_FactSalidas
  @Desde DATE = NULL,
  @Hasta DATE = NULL
AS
BEGIN
  SET NOCOUNT ON;

  ;WITH src AS (
    SELECT
      LTRIM(RTRIM(s.Empresa))        AS Empresa,
      LTRIM(RTRIM(s.Folio))          AS Folio,
      s.Fecha                        AS FechaHora,
      CONVERT(INT, CONVERT(CHAR(8), s.Fecha, 112)) AS DateKey,
      NULLIF(LTRIM(RTRIM(s.Cliente)),'')        AS Cliente,
      NULLIF(LTRIM(RTRIM(s.Vendedor)),'')       AS Vendedor,
      NULLIF(LTRIM(RTRIM(s.Moneda)),'')         AS Moneda,
      NULLIF(LTRIM(RTRIM(s.CondicionPago)),'')  AS CondicionPago,
      NULLIF(LTRIM(RTRIM(s.MedioEmbarque)),'')  AS MedioEmbarque,
      s.TotalImporte,
      s.TotalDescuento,
      s.TotalImpuesto,
      s.Total,
      d.Partida                      AS Renglon,
      NULLIF(LTRIM(RTRIM(d.Articulo)),'')  AS Articulo,
      NULLIF(LTRIM(RTRIM(d.Almacen)),'')   AS Almacen,
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
    s.TotalImporte,       -- Subtotal
    s.TotalImpuesto,      -- Impuestos
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
  LEFT JOIN dbo.DimArticulo      da ON da.ArticuloNK       = s.Articulo AND da.IsCurrent = 1
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
   6) ORQUESTADOR
   - Si @Desde/@Hasta son NULL, calcula rango [min(fecha)..max(fecha)]
     de Entradas y Salidas en OLTP.
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
    -- Si aún están NULL (no hay datos), usar hoy
    IF @d IS NULL SET @d = CAST(GETDATE() AS DATE);
    IF @h IS NULL SET @h = CAST(GETDATE() AS DATE);
  END

  PRINT CONCAT('Rango detectado: ', CONVERT(varchar(10),@d,120),' .. ', CONVERT(varchar(10),@h,120));

  -- 1) Asegurar miembros desconocidos con "No espesificado"
  EXEC dbo.usp_Ensure_Unknown_Members_NoEspesificado;

  -- 2) DimFecha
  EXEC dbo.usp_Load_DimFecha @Desde=@d, @Hasta=@h;

  -- 3) Dimensiones catálogo
  EXEC dbo.usp_Load_DimMoneda;
  EXEC dbo.usp_Load_DimCondicionPago;
  EXEC dbo.usp_Load_DimMedioEmbarque;
  EXEC dbo.usp_Load_DimVendedor;
  EXEC dbo.usp_Load_DimCliente;
  EXEC dbo.usp_Load_DimAlmacen;
  EXEC dbo.usp_Load_DimArticulo;

  -- 4) Hechos
  EXEC dbo.usp_Load_FactEntradas @Desde=@d, @Hasta=@h;
  EXEC dbo.usp_Load_FactSalidas  @Desde=@d, @Hasta=@h;

  PRINT 'ETL OK.';
END
GO
