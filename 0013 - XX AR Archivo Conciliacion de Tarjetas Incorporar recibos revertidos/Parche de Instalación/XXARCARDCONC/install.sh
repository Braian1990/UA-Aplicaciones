#+=======================================================================+
#|             Universal Assistance - Buenos Aires, ARG                  | 
#|                         All rights reserved.                          | 
#+=======================================================================+
#|                                                                       |
#| FILENAME                                                              |
#|     install.sh  - Instalation Script                                  |
#|                                                                       |
#| DESCRIPTION                                                           |  
#|     Conciliacion de Tarjetas Incorporar recibos revertidos            |
#|                                                                       |
#| HISTORY                                                               |
#|     22-JUN-17         BChristiansen                  Initial Version	 |
#|                                                                       |
#*=======================================================================

echo 'install.sh Begin' 

echo 'Please, enter APPS user: '
read APPS_USER 
echo 'Please, enter APPS PASSWORD: '
stty -echo 
read APPS_PWD 
stty echo 
echo 'Please, enter database SID '
read BASE 
echo 'AOL objects'

echo 'Body Package XX_AR_CARD_CONCILIATION_PKG'

sqlplus $APPS_USER/$APPS_PWD@$BASE @XX_AR_CARD_CONCILIATION_PKG.pkb
  
echo 'Upload'

echo 'install.sh End' 
