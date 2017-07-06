SET VERIFY OFF
WHENEVER SQLERROR EXIT FAILURE ROLLBACK;
spool XX_AR_CARD_CONCILIATION_PKB.log

CREATE OR REPLACE PACKAGE BODY APPS.xx_ar_card_conciliation_pkg AS
 PROCEDURE MAIN (x_error_desc OUT varchar2
                 ,x_error_code OUT varchar2
                 ,p_date_from IN varchar2
                 ,p_date_to IN varchar2)
  IS 
  
  --Cursor de Remitido
  CURSOR cur_card_remitido IS
         SELECT NVL(DECODE(is_numeric(acr.attribute13),
                      0, REPLACE(SUBSTR(acr.attribute13,1, INSTR(acr.attribute13, '-', 1)-1),' ', ''),
                      acr.attribute13), 
               flv.attribute7) ||';'|| --nro_comercio,
           flv.attribute3 ||';'|| --tipo_tarjeta,
           flv.attribute4 ||';'|| --emisor,
           acr.attribute9 ||';'|| --tarjeta,
           TO_CHAR(acr.receipt_date,'YYYYMMDD') ||';'|| --fecha_autorizacion,
           acr.attribute11 ||';'|| --cod_autorizacion,
           REPLACE(acr.amount,',','.') ||';'|| -- monto,
           acr.currency_code ||';'|| --moneda,
           acr.attribute10 ||';'|| --cuotas,
           acr.cash_receipt_id linea, --id recibo
           acr.cash_receipt_id,
           acrh.cash_receipt_history_id
   --        acr.attribute12
    FROM ar_cash_receipts acr,
         ar_cash_receipt_history acrh,
         ar_receipt_methods arm,
         fnd_lookup_values_vl flv
    WHERE flv.tag IS NOT NULL  -- metodo de cobro mapeado para presentacion
    AND flv.lookup_type = 'XX_METODOS_COBRO'
    AND arm.attribute13 = flv.lookup_code  
    AND acr.receipt_method_id = arm.receipt_method_id
	--Inicio. BChristiansen. 20170622. Req 3063
	--AND acr.attribute12 IS NULL
    AND NVL(acrh.attribute1, '#') != 'REMITIDO' --estado presentacion: Si está vacio no se presentó para conciliar
	--Fin. BChristiansen. 20170622. Req 3063
    AND acr.receipt_date >=  fnd_date.canonical_to_date(p_date_from)-- TO_DATE('01/12/2016', 'DD/MM/YYYY')  -- fecha inicio conciliacion de cupones
    AND acr.receipt_date <= fnd_date.canonical_to_date(p_date_to)
    AND acrh.status = 'REMITTED' -- solo selecciona los recibos con el estado REMITIDO
	--Inicio. BChristiansen. 20170622. Req 3063
    --AND acrh.current_record_flag = 'Y'
	--Fin. BChristiansen. 20170622. Req 3063
    AND acr.cash_receipt_id = acrh.cash_receipt_id
    FOR UPDATE;
	
	--Inicio. BChristiansen. 20170622. Req 3063
	--Cursor de Reversado
	  CURSOR cur_card_reversado IS
         SELECT NVL(DECODE(is_numeric(acr.attribute13),
                      0, REPLACE(SUBSTR(acr.attribute13,1, INSTR(acr.attribute13, '-', 1)-1),' ', ''),
                      acr.attribute13), 
               flv.attribute7) ||';'|| --nro_comercio,
           flv.attribute3 ||';'|| --tipo_tarjeta,
           flv.attribute4 ||';'|| --emisor,
           acr.attribute9 ||';'|| --tarjeta,
           TO_CHAR(acr.receipt_date,'YYYYMMDD') ||';'|| --fecha_autorizacion,
           acr.attribute11 ||';'|| --cod_autorizacion,
           REPLACE(acr.amount,',','.') ||';'|| -- monto,
           acr.currency_code ||';'|| --moneda,
           acr.attribute10 ||';'|| --cuotas,
           acr.cash_receipt_id linea, --id recibo
           acr.cash_receipt_id,
           acrh.cash_receipt_history_id
   --        acr.attribute12
    FROM ar_cash_receipts acr,
         ar_cash_receipt_history acrh,
         ar_receipt_methods arm,
         fnd_lookup_values_vl flv
    WHERE flv.tag IS NOT NULL  -- metodo de cobro mapeado para presentacion
    AND flv.lookup_type = 'XX_METODOS_COBRO'
    AND arm.attribute13 = flv.lookup_code  
    AND acr.receipt_method_id = arm.receipt_method_id
    AND NVL(acrh.attribute1, '#') != 'REVERSADO' --estado presentacion: Si está vacio no se presentó para conciliar
    AND acr.receipt_date >=  fnd_date.canonical_to_date(p_date_from)-- TO_DATE('01/12/2016', 'DD/MM/YYYY')  -- fecha inicio conciliacion de cupones
    AND acr.receipt_date <= fnd_date.canonical_to_date(p_date_to)
    AND acrh.status = 'REVERSED' -- solo selecciona los recibos con el estado REMITIDO
    --AND acrh.current_record_flag = 'Y'
    AND acr.cash_receipt_id = acrh.cash_receipt_id
    FOR UPDATE;
    
	--Fin. BChristiansen. 20170622. Req 3063
  
  BEGIN 
  
      --Inicio. BChristiansen. 20170622. Req 3063
  /*
     FOR c_card IN cur_card LOOP 
       fnd_file.PUT_LINE( fnd_file.OUTPUT,c_card.linea );
       UPDATE ar_cash_receipts SET
               attribute12 = TO_CHAR(SYSDATE)
              ,attribute_category = fnd_profile.VALUE('JGZZ_COUNTRY_CODE')
         WHERE cash_receipt_id = c_card.cash_receipt_id;
--       WHERE CURRENT OF cur_card;
   
    END LOOP;
	*/
	
    FOR c_card_remitido IN cur_card_remitido LOOP 
       fnd_file.PUT_LINE( fnd_file.OUTPUT,c_card_remitido.linea );
       UPDATE ar_cash_receipt_history SET
              attribute_category = fnd_profile.VALUE('JGZZ_COUNTRY_CODE')
              , attribute1 = 'REMITIDO'
         WHERE cash_receipt_history_id = c_card_remitido.cash_receipt_history_id;
--       WHERE CURRENT OF cur_card_remitido;
   
    END LOOP;
	
	FOR c_card_reversado IN cur_card_reversado LOOP 
       fnd_file.PUT_LINE( fnd_file.OUTPUT,c_card_reversado.linea );
       UPDATE ar_cash_receipt_history SET
              attribute_category = fnd_profile.VALUE('JGZZ_COUNTRY_CODE')
              , attribute1 = 'REVERSADO'
         WHERE cash_receipt_history_id = c_card_reversado.cash_receipt_history_id;
--       WHERE CURRENT OF cur_card_remitido;

    --Fin. BChristiansen. 20170622. Req 3063
   
    END LOOP;

    COMMIT;
  EXCEPTION
    WHEN OTHERS THEN
       x_error_code := 1;
       x_error_desc := 'Error '|| SQLERRM;
  END;                 
END;
/

SHOW ERRORS
SPOOL OFF
EXIT
/
