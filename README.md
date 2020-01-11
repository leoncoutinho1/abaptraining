# abaptraining

## Neste arquivo vou manter alguns links e informações que julgar importantes sobre ABAP e outras coisas relacionadas.

### Função para que trabalha com calendários de fábrica (tabela TFACS).
```
   CALL FUNCTION 'DAY_ATTRIBUTES_GET'
 EXPORTING
   FACTORY_CALENDAR                 = 'BR'
*   HOLIDAY_CALENDAR                 = ' '
   DATE_FROM                        = '01.01.2016'
   DATE_TO                          = '05.02.2016'
   LANGUAGE                         = 'PT'
*   NON_ISO                          = ' '
* IMPORTING
*   YEAR_OF_VALID_FROM               =
*   YEAR_OF_VALID_TO                 =
*   RETURNCODE                       =
  TABLES
    day_attributes                   = t_dias_uteis
* EXCEPTIONS
*   FACTORY_CALENDAR_NOT_FOUND       = 1
*   HOLIDAY_CALENDAR_NOT_FOUND       = 2
*   DATE_HAS_INVALID_FORMAT          = 3
*   DATE_INCONSISTENCY               = 4
*   OTHERS                           = 5
          .   
```
