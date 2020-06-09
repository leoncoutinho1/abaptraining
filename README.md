### abaptraining

#### Neste arquivo vou manter alguns links e informações que julgar importantes sobre ABAP e outras coisas relacionadas.

##### Função que trabalha com _calendários de fábrica_(tabela TFACS).
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
- Passando um peŕíodo como parâmetro está função retorna uma tabela com os dias do intervalo informado.
- A tabela segue o seguinte formato:
   
   | DATE | FREEDAY | HOLIDAY | HOLIDAY_ID | TXT_SHORT | TXT_LONG | WEEKDAY | WEEKDAY_S | WEEKDAY_L | DAY_STRING |
   
- Existe a possibilidade de passar também um calendário de feriados (do tipo da tabela THOCS).
- Para encontrar o primeiro dia útil após uma data pode-se utilzar a função passando um período a partir da data desejada. Após o retorno da função deve-se eliminar as linhas que possuem o campo holiday marcado.

- Função para somar dias à uma data.
```
CALL FUNCTION 'RP_CALC_DATE_IN_INTERVAL'
    EXPORTING
      date      = lw_date
      days      = 5
      months    = 0
      signum    = '+'    " Signum : "+" or "-" to add or remove
      years     = 0
    IMPORTING
      calc_date = lw_processed_date.
```

###### Validação de valor de um campo com Field Exits
http://abap4life.blogspot.com/2012/06/field-exits-como-validar-programas_412.html

