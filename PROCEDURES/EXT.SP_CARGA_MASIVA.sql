CREATE OR REPLACE PROCEDURE "EXT"."SP_CARGA_MASIVA" (IN_FILENAME Varchar(120)) LANGUAGE SQLSCRIPT SQL SECURITY DEFINER DEFAULT SCHEMA "EXT" AS
BEGIN

-- Versiones --------------------------------------------------------------------------------------------------------
-- v01 - Versión inicial
---------------------------------------------------------------------------------------------------------------------


    --Declaración de variables
    DECLARE io_contador Number := 0;
    DECLARE i_Tenant VARCHAR(127);
    DECLARE cVersion CONSTANT VARCHAR(2) := '01';
    DECLARE cReportTable CONSTANT VARCHAR(50) := 'SP_CARGA_MASIVA';
    DECLARE i_rev Number := 0; -- Número de ejecución

    --Gestión de errores
    DECLARE EXIT HANDLER FOR SQLEXCEPTION 
    BEGIN 
        
        CALL LIB_GLOBAL_CESCE :w_debug (
            i_Tenant,
            cReportTable || '. SQL ERROR_MESSAGE: ' || IFNULL( ::SQL_ERROR_MESSAGE, '') || '. SQL_ERROR_CODE: ' ||  ::SQL_ERROR_CODE,
            cReportTable,
            io_contador
        );
        RESIGNAL;

    END;


    --Obtenemos tenant
    SELECT TENANTID INTO i_Tenant FROM CS_TENANT;

    CALL LIB_GLOBAL_CESCE :w_debug(
        i_Tenant,
        'STARTING with SESSION_USER: ' || SESSION_USER || ' version ' || cVersion,
        cReportTable,
        io_contador
    );

    CALL LIB_GLOBAL_CESCE :w_debug (
        i_Tenant,
        'COMIENZA Tratamiento fichero ' || IN_FILENAME,
        cReportTable,
        io_contador
    );


    --COMPROBACION CAMPOS CLAVE NO NULOS
        
    INSERT INTO EXT.EXT_CARGA_MASIVA_NO_VALIDADAS
    SELECT A.*, 'Algun campo clave es nulo'
    FROM EXT.EXT_CARGA_MASIVA_LOAD A
    WHERE A.BATCHNAME = IN_FILENAME
    AND (A.NUM_POLIZA IS NULL OR LENGTH(TRIM(A.NUM_POLIZA)) = 0
    OR A.CLIENT IS NULL OR LENGTH(TRIM(A.CLIENT)) = 0
    OR A.ESTADO IS NULL OR LENGTH(TRIM(A.ESTADO)) = 0
    OR A.COMPANYIA IS NULL OR LENGTH(TRIM(A.COMPANYIA)) = 0
    OR A.EFECTO IS NULL OR LENGTH(TRIM(A.EFECTO)) = 0
    OR A.FECHA_VENCIMIENTO IS NULL OR LENGTH(TRIM(A.FECHA_VENCIMIENTO)) = 0
    OR A.FECHA_CREACION IS NULL OR LENGTH(TRIM(A.FECHA_CREACION)) = 0
    OR A.TIPOLOGIA IS NULL OR LENGTH(TRIM(A.TIPOLOGIA)) = 0
    OR A.FECHA_CONTRATACION IS NULL OR LENGTH(TRIM(A.FECHA_CONTRATACION)) = 0
    OR A.PRIMA_NETA IS NULL OR LENGTH(TRIM(A.PRIMA_NETA)) = 0
    OR A.RIESGO_POLIZA IS NULL OR LENGTH(TRIM(A.RIESGO_POLIZA)) = 0
    OR A.COLABORADOR IS NULL OR LENGTH(TRIM(A.COLABORADOR)) = 0
    OR A.CLIENTE_COLABORADOR IS NULL OR LENGTH(TRIM(A.CLIENTE_COLABORADOR)) = 0);

    CALL EXT.LIB_GLOBAL_CESCE:w_debug (i_Tenant,
        'Se han movido '  || To_VARCHAR(::ROWCOUNT) || ' registros con -Algun campo clave es nulo- a EXT_CARGA_MASIVA_NO_VALIDADAS', cReportTable, io_contador);

    DELETE FROM EXT.EXT_CARGA_MASIVA_LOAD A
    WHERE A.BATCHNAME = IN_FILENAME
    AND (A.NUM_POLIZA IS NULL OR LENGTH(TRIM(A.NUM_POLIZA)) = 0
    OR A.CLIENT IS NULL OR LENGTH(TRIM(A.CLIENT)) = 0
    OR A.ESTADO IS NULL OR LENGTH(TRIM(A.ESTADO)) = 0
    OR A.COMPANYIA IS NULL OR LENGTH(TRIM(A.COMPANYIA)) = 0
    OR A.EFECTO IS NULL OR LENGTH(TRIM(A.EFECTO)) = 0
    OR A.FECHA_VENCIMIENTO IS NULL OR LENGTH(TRIM(A.FECHA_VENCIMIENTO)) = 0
    OR A.FECHA_CREACION IS NULL OR LENGTH(TRIM(A.FECHA_CREACION)) = 0
    OR A.TIPOLOGIA IS NULL OR LENGTH(TRIM(A.TIPOLOGIA)) = 0
    OR A.FECHA_CONTRATACION IS NULL OR LENGTH(TRIM(A.FECHA_CONTRATACION)) = 0
    OR A.PRIMA_NETA IS NULL OR LENGTH(TRIM(A.PRIMA_NETA)) = 0
    OR A.RIESGO_POLIZA IS NULL OR LENGTH(TRIM(A.RIESGO_POLIZA)) = 0
    OR A.COLABORADOR IS NULL OR LENGTH(TRIM(A.COLABORADOR)) = 0
    OR A.CLIENTE_COLABORADOR IS NULL OR LENGTH(TRIM(A.CLIENTE_COLABORADOR)) = 0);


    --COMPROBACION FORMATO DE FECHAS
	
	CALL EXT.LIB_GLOBAL_CESCE:w_debug (i_Tenant, 'COMPROBACION CAMPOS FECHAS VALIDAS', cReportTable, io_contador);
	
	INSERT INTO EXT.EXT_CARGA_MASIVA_NO_VALIDADAS	
	SELECT A.*,  'Alguna fecha con formato incorrecto'
	FROM EXT.EXT_CARGA_MASIVA_LOAD A
	WHERE A.BATCHNAME = IN_FILENAME
    AND (LENGTH(LTRIM(A.FECHA_VENCIMIENTO, '0123456789-/')) != 0
	OR LENGTH(LTRIM(A.FECHA_CREACION, '0123456789-/')) != 0
	OR LENGTH(LTRIM(A.FECHA_CONTRATACION, '0123456789-/')) != 0);
	

	CALL EXT.LIB_GLOBAL_CESCE:w_debug (i_Tenant,
        'Se han movido '  || To_VARCHAR(::ROWCOUNT) || ' registros con -Alguna fecha con formato incorrecto- a EXT_CARGA_MASIVA_NO_VALIDADAS', cReportTable, io_contador);
		
	DELETE FROM EXT.EXT_CARGA_MASIVA_LOAD A
	WHERE A.BATCHNAME = IN_FILENAME
    AND (LENGTH(LTRIM(A.FECHA_VENCIMIENTO, '0123456789-/')) != 0
	OR LENGTH(LTRIM(A.FECHA_CREACION, '0123456789-/')) != 0
	OR LENGTH(LTRIM(A.FECHA_CONTRATACION, '0123456789-/')) != 0);

	--TODAS LA VALIDACIONES FINALIZADAS
	--INSERTAMOS HIST
	CALL EXT.LIB_GLOBAL_CESCE:w_debug (i_Tenant, 'INSERCION EN EXT.EXT_CARGA_MASIVA_HIST', cReportTable, io_contador);
	
	INSERT INTO EXT.EXT_CARGA_MASIVA_HIST
	SELECT *,'PENDIENTE' AS ESTADOREG FROM EXT.EXT_CARGA_MASIVA_LOAD
	WHERE BATCHNAME = IN_FILENAME
	AND NOT EXISTS(SELECT * FROM EXT.EXT_CARGA_MASIVA_HIST WHERE BATCHNAME = IN_FILENAME);
	
	CALL EXT.LIB_GLOBAL_CESCE:w_debug (i_Tenant,
        'Se han insertado '  || To_VARCHAR(::ROWCOUNT) || ' registros en EXT_CARGA_MASIVA_HIST', cReportTable, io_contador);

    CALL LIB_GLOBAL_CESCE :w_debug (
        i_Tenant,
        'FIN Tratamiento fichero ' || IN_FILENAME,
        cReportTable,
        io_contador
    );

END; --FIN PROCEDIMIENTO
