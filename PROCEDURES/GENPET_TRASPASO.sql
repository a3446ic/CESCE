CREATE OR REPLACE PROCEDURE "EXT"."GENPET_TRASPASO" (IN pCASEID VARCHAR(10)) LANGUAGE SQLSCRIPT AS
BEGIN

	DECLARE io_contador Number := 0;
	DECLARE i_Tenant VARCHAR(127);
	DECLARE cVersion VARCHAR(2) := '07';
    DECLARE cReportTable CONSTANT VARCHAR(50) := 'GENPET_TRASPASO' || '_' || cVersion;
	
	DECLARE vPorc_Emision DECIMAL(6,3);
	DECLARE vPorc_Renovacion DECIMAL(6,3);
	DECLARE vPorc_Emision_DEF DECIMAL(6,3);
	DECLARE vPorc_Renovacion_DEF DECIMAL(6,3);
	DECLARE vIdProduct NVARCHAR(127);
	DECLARE vModalidad DECIMAL(3);
	DECLARE vSubmodalidad NVARCHAR(20);
	DECLARE vNumExpediente BIGINT;
	DECLARE vError NVARCHAR(255);
	DECLARE vFechaInicio DATE;
	DECLARE vFechaFin DATE;
	
-- ----------------------------------------------------------------------------------------------------
-- Cursor para Obtener las entradas de las solicitudes de traspaso, menos cuando es traspaso total de caucion, en ese caso solo se obtiene el registro total.
-- ----------------------------------------------------------------------------------------------------

	DECLARE CURSOR cur_solicitudes FOR
	SELECT *
		FROM EXT.SOLICITUD_TRASPASO st
		WHERE st.CASEID = :pCASEID
		AND (
		    /* --- CREDITO: siempre se manda --- */
		    st.RAMO = 'CREDITO'
		
		    /* --- CAUCION PARCIAL: se manda --- */
		    OR (
		        st.RAMO = 'CAUCION'
		        AND st.TIPO_TRASPASO = 'P'
		        AND NOT EXISTS (
		            SELECT 1
		            FROM EXT.SOLICITUD_TRASPASO st2
		            WHERE st2.CASEID = st.CASEID
		              AND st2.RAMO IN ('CAUCION','')
		              AND st2.TIPO_TRASPASO = 'T'
		        )
		    )
		
		    /* --- CAUCION TOTAL: solo T --- */
		    OR (
		        st.RAMO = 'CAUCION'
		        AND st.TIPO_TRASPASO = 'T'
		    )
		);


-- Versiones --
-- v02 - Cambiada consulta obtener product id: (NUM_AVAL_HOST = cur_row.COD_AVAL OR NUM_AVAL_HOST IS NULL)
-- v03 - Añadida condición en la asignación de porcentajes especiales para que no sobreescriba ambos valores si uno es 0
-- v04 - Se ignora la búsqueda de porcentajes por defecto.
-- v05 - Se añade a la busqueda del id de producto la condicion AND RAMO = cur_row.RAMO
-- v06 - Modificación del procedimiento de acuerdo a los cambios y mejorar del evolutivo PPM-14896 (??)
-- v07 - Modificación del procedimiento del evolutivo PPM-17703
--     * Cambios en Peticiones cambio cartera - Fecha inicio
/*          'traspaso_con_derechos_y_obligaciones': 'I',
            'sin_derechos_y_obligaciones_a_la_renovacin': 'R',
            'sin_derechos_y_obligaciones_al_inicio_de_la_anuali':'A',
            'aplicar':'C',
            'finalizar':'F'
*/
-- v08 - Modificación de obtención de los porcentajes Plan comisionamiento (mediador y principal)
-- V09 - Añadir condición or IDPRODUCT = '0' para inicializar vIdProduct, and vIdProduct <> '0' en sección de errores, incluir solo registro total en traspaso caucion
-- ----------------------------- HANDLER EXCEPTION -------------------------
	DECLARE EXIT HANDLER FOR SQLEXCEPTION
		BEGIN
			CALL EXT.LIB_GLOBAL_CESCE:w_debug (i_Tenant, 'SQL ERROR_MESSAGE: ' ||
						IFNULL(::SQL_ERROR_MESSAGE,'') || '. SQL_ERROR_CODE: ' || ::SQL_ERROR_CODE, cReportTable, io_contador);
			RESIGNAL;
		END;
-- ---------------------------------------------------------------------------

	SELECT EXT.LIB_GLOBAL_CESCE:getTenantID() INTO i_Tenant FROM DUMMY;

	CALL EXT.LIB_GLOBAL_CESCE:w_debug (i_Tenant, 'INICIO PROCEDIMIENTO with SESSION_USER '|| SESSION_USER, cReportTable, io_contador);

	-- Borrar Peticiones previas en Estado PENDIENTE
	CALL EXT.LIB_GLOBAL_CESCE:w_debug (i_Tenant, 'Borrar Peticiones previas en Estado PENDIENTE para la solicitud CASEID: ' || TO_VARCHAR(pCASEID), cReportTable, io_contador);

	DELETE  FROM "EXT"."PETICIONES_CAMBIO_CARTERA"
	WHERE CASEID=TO_VARCHAR(pCASEID) 
		  AND ESTADOREG='PENDIENTE'; 

	CALL EXT.LIB_GLOBAL_CESCE:w_debug (i_Tenant, 'Registros Borrados de PETICIONES_CAMBIO_CARTERA: ' || TO_VARCHAR(::ROWCOUNT), cReportTable, io_contador);

	CALL EXT.LIB_GLOBAL_CESCE:w_debug (i_Tenant, 'Buscar en EXT.SOLICITUD_TRASPASO para la solicitud CASEID: ' || TO_VARCHAR(pCASEID), cReportTable, io_contador);

	FOR cur_row AS cur_solicitudes
	DO
		-- Inicializar variables
		Select null, null, null, null, null, null, null
		into vIdProduct,vModalidad,vSubmodalidad, vNumExpediente,vPorc_Emision_DEF,vPorc_Renovacion_DEF, vError
		FROM DUMMY;
		
		CALL EXT.LIB_GLOBAL_CESCE:w_debug (i_Tenant, 'Poliza:' || IFNULL(TO_VARCHAR(cur_row.NUM_POLIZA),'') 
			|| ' Aval:' ||  IFNULL(TO_VARCHAR(cur_row.COD_AVAL),'')
			|| ' Mediador:' ||  LPAD(cur_row.COD_MEDIADOR_RECEPTOR,4,'0') || '-' || LPAD(cur_row.SUBCLAVE_RECEPTOR,4,'0'), cReportTable, io_contador);

			-- OBTENER PRODUCT ID: Si no hay IDPRODUCT se usa IDMODALIDAD, Si no hay NUM_EXPEDIENTE se usa NUM_POLIZA
			SELECT TOP 1 
			case when IDPRODUCT is null or IDPRODUCT ='' or IDPRODUCT = '0' then LPAD(IDMODALIDAD,3,'0') else IDPRODUCT end as IDPRODUCT, 
			case when NUM_EXPEDIENTE is null or NUM_EXPEDIENTE ='0' then LPAD(NUM_POLIZA,8,'0') else NUM_EXPEDIENTE end as NUM_EXPEDIENTE
			INTO vIdProduct, vNumExpediente DEFAULT NULL, NULL  
			FROM EXT.CARTERA 
			WHERE 
				NUM_POLIZA = cur_row.NUM_POLIZA 
                AND (NUM_AVAL_HOST = cur_row.COD_AVAL OR NUM_AVAL_HOST IS NULL)
                AND RAMO = cur_row.RAMO
                AND COD_MEDIADOR = LPAD(cur_row.COD_MEDIADOR_RECEPTOR,4,'0')  --v07
                AND COD_SUBCLAVE = LPAD(cur_row.SUBCLAVE_RECEPTOR,4,'0')  --v07
				--AND FECHA_INICIO <= cur_row.FECHA_EFECTO_SOLICITUD 
				and FECHA_FIN > cur_row.FECHA_EFECTO_SOLICITUD;
			-- Para Peticiones de traspaso TOTALES
			IF vIdProduct is null and cur_row.TIPO_TRASPASO ='T' THEN
				vIdProduct = ''; -- asignamos producto vacio
			END IF;
			
			SELECT TOP 1 P_EMISION_DEF, P_RENOVACION_DEF, MODALIDAD, COBERTURA 
						 INTO vPorc_Emision_DEF, vPorc_Renovacion_DEF, vModalidad, vSubmodalidad
						 DEFAULT 0.0, 0.0, Null, Null
			FROM EXT.PRODUCTOS_VW
			WHERE IDPRODUCT = vIdProduct;
			
			CALL EXT.LIB_GLOBAL_CESCE:w_debug (i_Tenant, 'Producto ' || IFNULL(vIdProduct,'') || ' Modalidad:' || 
			IFNULL(To_varchar(vModalidad),'') || ' Cobertura/submodalidad:' || IFNULL(vSubmodalidad,''), cReportTable, io_contador);  ----- COMENTARIO TEMPORAL 


		-- -------------------------------------------------------------------------------------------------------------------
		-- Obtener porcentajes comisionamiento: Especial o Plan Conmpesación Mediador, Principal o Por Defecto Producto
		-- -------------------------------------------------------------------------------------------------------------------
		-- Comprobar si no hay porcentaje especial de emision o renovacion
		IF (cur_row.P_ESPECIAL_EMISION is NULL OR cur_row.P_ESPECIAL_EMISION = 0
			OR cur_row.P_ESPECIAL_RENOVACION is NULL OR cur_row.P_ESPECIAL_RENOVACION = 0) THEN

			CALL EXT.LIB_GLOBAL_CESCE:w_debug (i_Tenant, 'No hay Algun P_ESPECIAL' , cReportTable, io_contador);----- COMENTARIO TEMPORAL 

			-- OBTENER Porcentajes del plan de comisionamiento para el mediador/Producto/Fecha traspaso
			SELECT TOP 1 P_EMISION, P_RENOVACION INTO vPorc_Emision, vPorc_Renovacion DEFAULT 0.0, 0.0
			FROM EXT.PLAN_COMISIONAMIENTO 
			WHERE 
				POSITIONNAME = LPAD(cur_row.COD_MEDIADOR_RECEPTOR,4,'0') || '-' || LPAD(cur_row.SUBCLAVE_RECEPTOR,4,'0')
				AND IDPRODUCT = vIdProduct
				AND EFFECTIVESTARTDATE <= cur_row.FECHA_EFECTO_SOLICITUD AND EFFECTIVEENDDATE > cur_row.FECHA_EFECTO_SOLICITUD;

				CALL EXT.LIB_GLOBAL_CESCE:w_debug (i_Tenant, 'PLAN COMISIONAMIENTO vPorc_Emision:' || TO_VARCHAR(vPorc_Emision) || ' vPorc_Renovacion:' || TO_VARCHAR(vPorc_Renovacion) , cReportTable, io_contador);  ----- COMENTARIO TEMPORAL 

		-- Si no se encuentran porcentajes en el plan de comisionamiento del mediador y es subclave, se buscan los del principal
			IF (:vPorc_Emision = 0 or :vPorc_Renovacion = 0) and LPAD(cur_row.SUBCLAVE_RECEPTOR,4,'0') <> '0000' THEN  -- v08
				-- OBTENER Porcentajes del plan de comisionamiento para el mediador/Producto/Fecha traspaso
				SELECT TOP 1 P_EMISION, P_RENOVACION INTO vPorc_Emision, vPorc_Renovacion DEFAULT 0.0, 0.0
				FROM EXT.PLAN_COMISIONAMIENTO 
				WHERE 
					POSITIONNAME = LPAD(cur_row.COD_MEDIADOR_RECEPTOR,4,'0') || '-' || '0000'
					AND IDPRODUCT = vIdProduct
					AND EFFECTIVESTARTDATE <= cur_row.FECHA_EFECTO_SOLICITUD AND EFFECTIVEENDDATE > cur_row.FECHA_EFECTO_SOLICITUD;

				CALL EXT.LIB_GLOBAL_CESCE:w_debug (i_Tenant, 'PLAN COMISIONAMIENTO PRINCIPAL vPorc_Emision:' || TO_VARCHAR(vPorc_Emision) || ' vPorc_Renovacion:' || TO_VARCHAR(vPorc_Renovacion) , cReportTable, io_contador);  ----- COMENTARIO TEMPORAL 

			END IF;
			-- Si no se encuentran porcentajes en el plan de comisionamiento del mediador subclave o principal, se asignan los porcentajes por defecto del producto

			IF :vPorc_Emision = 0 or :vPorc_Renovacion = 0 THEN
			
				select vPorc_Emision_DEF, vPorc_Renovacion_DEF INTO vPorc_Emision, vPorc_Renovacion FROM DUMMY;

				CALL EXT.LIB_GLOBAL_CESCE:w_debug (i_Tenant, 'Valores por Defecto vPorc_Emision:' || TO_VARCHAR(vPorc_Emision) || ' vPorc_Renovacion:' || TO_VARCHAR(vPorc_Renovacion) , cReportTable, io_contador);  ----- COMENTARIO TEMPORAL 

			END IF;
			
			vPorc_Emision := CASE WHEN cur_row.P_ESPECIAL_EMISION is NULL OR cur_row.P_ESPECIAL_EMISION = 0 THEN vPorc_Emision ELSE cur_row.P_ESPECIAL_EMISION END;
			vPorc_Renovacion := CASE WHEN cur_row.P_ESPECIAL_RENOVACION is NULL OR cur_row.P_ESPECIAL_RENOVACION = 0 THEN vPorc_Renovacion ELSE cur_row.P_ESPECIAL_RENOVACION END;

		ELSE
			vPorc_Emision := cur_row.P_ESPECIAL_EMISION;
			vPorc_Renovacion := cur_row.P_ESPECIAL_RENOVACION;
			CALL EXT.LIB_GLOBAL_CESCE:w_debug (i_Tenant, 'ESPECIAL vPorc_Emision:' || TO_VARCHAR(vPorc_Emision) || ' vPorc_Renovacion:' || TO_VARCHAR(vPorc_Renovacion) , cReportTable, io_contador);  ----- COMENTARIO TEMPORAL 

		END IF;	
		-- -------------------------------------------------------------------------------------------------------------------
		-- Traspaso entre subclaves se asignan fechas por defecto para que se envien a blanco y porcentaje en blanco --v08 
		-- -------------------------------------------------------------------------------------------------------------------
		IF cur_row.TIPO_MOVIMIENTO = '8' THEN  
			vFechaInicio = '1990-12-31';
			vFechaFin = '2200-01-01';	
			vPorc_Emision := null;
			vPorc_Renovacion := null;
		ELSE
			vFechaInicio = cur_row.FECHA_INICIO;
			vFechaFin = cur_row.FECHA_FIN;
		END IF;
		
		-- -------------------------------------------------------------------------------------------------------------------
		-- ERRORES
		-- -------------------------------------------------------------------------------------------------------------------
		IF vIdProduct is null THEN
			vError := 'Producto no encontrado.';
		ELSEIF (:vPorc_Emision = 0 or :vPorc_Renovacion = 0) and (vIdProduct <> '' and vIdProduct <> '0') THEN --v09
			vError := 'Porcentajes de Emision o Renovacion no definidos';
		END IF;

		-- ----------------------------------------------------------------------------------------------------
		-- Se Inserta la Petición de Traspaso
		-- ----------------------------------------------------------------------------------------------------
		INSERT INTO "EXT"."PETICIONES_CAMBIO_CARTERA" (
			RAMO,
			IDPRODUCT,
			NUM_POLIZA,
			IDMODALIDAD,
			IDSUBMODALIDAD,
			NUM_FIANZA,
			NUM_EXPEDIENTE,
			NUM_ANUALIDAD,
			COD_MEDIADOR_CEDENTE,
			COD_SUBCLAVE_CEDENTE,
			COD_MEDIADOR_RECEPTOR,
			COD_SUBCLAVE_RECEPTOR,
			P_INTERMEDIACION,
			INICIO_PERIODO,
			FECHA_EFECTO_TRASPASO,
			FECHA_INICIO,
			FECHA_FIN,
			USUARIO,
			EMAIL,
			TIPO_CAMBIO,
			TIPO_TRASPASO,
			P_EMISION,
			P_RENOVACION,
			IND_COMISION,
			ESTADOREG,
			CASEID,
			ERROR,
			MODIF_DATE,
			NOTIF_EMAIL
		)
            --FECHA_INICIO_OPESP, --v06
            --FECHA_FIN_OPESP) --v06
		VALUES(
			cur_row.RAMO,
			vIdProduct,
            --cur_row.IDPRODUCT, --v06
			cur_row.NUM_POLIZA,  --NUM_POLIZA
			vModalidad,
			vSubmodalidad,
			cur_row.COD_AVAL,  --NUM_FIANZA
			vNumExpediente,
			0,  --NUM_ANUALIDAD --no se especifica en las llamadas a los Webservices
			cur_row.COD_MEDIADOR_CEDENTE,
			cur_row.SUBCLAVE_CEDENTE,
			cur_row.COD_MEDIADOR_RECEPTOR,
			cur_row.SUBCLAVE_RECEPTOR,
			cur_row.INTERMEDIACION_RECEPTOR,
			--cur_row.FECHA_INICIO_TRASPASO,  --INICIO_PERIODO
			CASE WHEN cur_row.FECHA_INICIO_TRASPASO in ('I', 'A', 'C','F') THEN 'I' ELSE 'R' END,  --INICIO_PERIODO
			cur_row.FECHA_EFECTO_SOLICITUD,  -- FECHA_EFECTO_TRASPASO
			cur_row.FECHA_INICIO,
			cur_row.FECHA_FIN,
			cur_row.USUARIO,
			cur_row.EMAIL,
			CASE WHEN cur_row.FECHA_INICIO_TRASPASO IN ('I','C','F') THEN 'C' ELSE 'S' END, --TIPO_CAMBIO C con derechos , S sin derechos
            --cur_row.FECHA_INICIO_TRASPASO, --v06
			CASE WHEN cur_row.TIPO_TRASPASO = 'T' THEN 'N' ELSE 'S' END, --TIPO_TRASPASO S si es parcial, N si es completo
--            cur_row.TIPO_TRASPASO, --v06
			vPorc_Emision, --P_EMISION --v08
			vPorc_Renovacion, --P_RENOVACION --v08
			CASE WHEN cur_row.FECHA_INICIO_TRASPASO IN ('I','C','F') THEN 'S' ELSE 'N' END, -- IND_COMISION S si es con derechos y N si es sin derechos
            --cur_row.FECHA_INICIO_TRASPASO, --v06
			CASE WHEN vError is null THEN 'PENDIENTE' ELSE 'ERROR' END, --ESTADOREG
			cur_row.CASEID,
			vError,
			CURRENT_TIMESTAMP,
			0 -- NOTIF_EMAIL  (Defecto 1, NOTIF_EMAIL - notifica por email al usuario)
            --cur_row.FECHA_INICIO_OPESP, --v06
            --cur_row.FECHA_FIN_OPESP --v06
			);

	END FOR;
	
	CALL EXT.LIB_GLOBAL_CESCE:w_debug (i_Tenant, 'FIN PROCEDIMIENTO ', cReportTable, io_contador);

-- Fin procedimiento
END