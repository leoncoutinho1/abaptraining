## Modularização

### Form - subrotina

#### Existem 3 maneiras de passar informações para uma sub-rotina:
- por valor:
    - É realizada uma cópia, sendo assim somente o valor da variável é passado para a subrotina. A variável original é preservada.
    - Exemplo: 
    ```
    * declaro um inteiro fatorial com valor 5
    DATA fatorial TYPE i VALUE 5.

    * declaro um inteiro result com valor 1
    DATA result TYPE i VALUE 1.

    * chamo a subrotina passando somente o valor da variável fatorial (isso é feito usando a keyword VALUE após USING)
    PERFORM calc_fatorial USING * VALUE * fatorial CHANGING result.

    * declaração da sub-rotina
    FORM calc_fatorial  USING    valor      TYPE i 
                        CHANGING resultado  TYPE i.

        IF (valor GT 1).
            WHILE (valor GT 1).
                result = result * (valor - 1).
                valor = valor - 1.
            ENDWHILE.
        ENDIF.

    ENDFORM.

    * no final do while a variável valor será 1 porém a original( fatorial ) será preservada.

    ```
- por valor e resultado:
    - É passada a variável após a keyword CHANGING junto com a keyword VALUE.
    - Neste caso a alteração só será realmente gravada após a conclusão do FORM.

    - Exemplo: 
    ```
    * declaro um inteiro fatorial com valor 5
    DATA fatorial TYPE i VALUE 5.

    * chamo a subrotina passando a variável fatorial para ser modificada
    PERFORM calc_fatorial CHANGING * VALUE * fatorial.

    * declaração da sub-rotina
    FORM calc_fatorial CHANGING fat TYPE i.
        DATA cont TYPE i VALUE fat.

        IF (cont GT 1).
            WHILE (cont GT 1).
                fat = fat * (cont - 1).
                valor = valor - 1.
            ENDWHILE.
        ENDIF.

    ENDFORM.

    * o valor de fat é alterado em cada volta do loop porém so será realmente gravado em fatorial na conclusão do FORM.

    ```


- por referência:
    - É passada a variável após a keyword CHANGING.
    - Neste caso a alteração será realizada diretamente na variável que foi passada.
    - Caso o FORM seja interrompido no meio a variável apresentará o valor que recebeu no momento

    - Exemplo: 
    ```
    * declaro um inteiro fatorial com valor 5
    DATA fatorial TYPE i VALUE 5.

    * chamo a subrotina passando a variável fatorial para ser modificada
    PERFORM calc_fatorial CHANGING fatorial.

    * declaração da sub-rotina
    FORM calc_fatorial CHANGING fat TYPE i.
        DATA cont TYPE i VALUE fat.

        IF (cont GT 1).
            WHILE (cont GT 1).
                fat = fat * (cont - 1).
                valor = valor - 1.
            ENDWHILE.
        ENDIF.

    ENDFORM.

    * o valor de fatorial é alterado em cada volta do loop imediatamente

    ```

* O Form também consegue visualizar as variáveis globais do escopo onde está inserido mas, visando maior desacoplamento e para promover o reaproveitamento de código é desaconselhada essa utilização.