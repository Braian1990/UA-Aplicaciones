CREATE OR REPLACE PACKAGE BODY APPS.xx_ar_card_conciliation_pkg AS
 PROCEDURE MAIN (x_error_desc OUT varchar2
                 ,x_error_code OUT varchar2
                 ,p_date_from IN varchar2
                 ,p_date_to IN varchar2)
  IS 
  CURSOR cur_card IS
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
           acr.cash_receipt_id   
   --        acr.attribute12
    FROM ar_cash_receipts acr,
         ar_cash_receipt_history acrh,
         ar_receipt_methods arm,
         fnd_lookup_values_vl flv
    WHERE flv.tag IS NOT NULL  -- metodo de cobro mapeado para presentacion
    AND flv.lookup_type = 'XX_METODOS_COBRO'
    AND arm.attribute13 = flv.lookup_code  
    AND acr.receipt_method_id = arm.receipt_method_id
    AND acr.attribute12 IS NULL --estado presentacion: Si está vacio no se presentó para conciliar
    AND acr.receipt_date >=  fnd_date.canonical_to_date(p_date_from)-- TO_DATE('01/12/2016', 'DD/MM/YYYY')  -- fecha inicio conciliacion de cupones
    AND acr.receipt_date <= fnd_date.canonical_to_date(p_date_to)
    AND acrh.status = 'REMITTED' -- solo selecciona los recibos con el estado REMITIDO
    AND acrh.current_record_flag = 'Y'
    AND acr.cash_receipt_id = acrh.cash_receipt_id
    FOR UPDATE;
    
  
  BEGIN 
  
    FOR c_card IN cur_card LOOP 
       fnd_file.PUT_LINE( fnd_file.OUTPUT,c_card.linea );
       UPDATE ar_cash_receipts SET
               attribute12 = TO_CHAR(SYSDATE)
              ,attribute_category = fnd_profile.VALUE('JGZZ_COUNTRY_CODE')
         WHERE cash_receipt_id = c_card.cash_receipt_id;
--       WHERE CURRENT OF cur_card;
   
    END LOOP;
    COMMIT;
  EXCEPTION
    WHEN OTHERS THEN
       x_error_code := 1;
       x_error_desc := 'Error '|| SQLERRM;
  END;                 
END;
/
