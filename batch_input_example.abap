*----------------------------------------------------------------------*
*                              VIVO                                    *
*----------------------------------------------------------------------*
* Author.....: Leonardo Coutinho Gomes                                 *
* Date.......: 25.11.2019 08:37:17                                     *
* Module.....: Treinamento                                             *
* Project....: treinamento ABAP                                        *
* Description: Upload/Download de arquivo                              *
*----------------------------------------------------------------------*
REPORT ZTRN_LCG_ARQUIVO.

**********************************************************************
* Types
**********************************************************************
TYPES: BEGIN OF ty_arq,
         linha TYPE string,
       END OF ty_arq,

       BEGIN OF ty_lay_ent,
         cpf      TYPE ztrn_cli_lcg-cpf,
         nome     TYPE ztrn_cli_lcg-nome,
         dtnasc   TYPE ztrn_cli_lcg-dtnasc,
         sexonasc TYPE ztrn_cli_lcg-sexonasc,
       END OF ty_lay_ent.

**********************************************************************
* Tabela Interna
**********************************************************************
DATA: tg_arq_ent   TYPE TABLE OF ty_arq,          "Recebe linhas de entrada do arquivo texto.
      tg_dados_ent TYPE TABLE OF ty_lay_ent,      "Recebe dados de entrada no mesmo formato do objeto.
      tg_message   TYPE TABLE OF bdcmsgcoll,      "Recebe mensagens para jogar no arquivo que será baixado.
      tg_arq_sai   TYPE TABLE OF ty_arq.          "Receberá as linhas do arquivo que será baixado.
**********************************************************************
* Tela de Seleção
**********************************************************************

SELECTION-SCREEN BEGIN OF BLOCK b_par WITH FRAME TITLE text-000.
  PARAMETERS: p_arqe TYPE rlgrap-filename,  "Campos SAP para arquivos. - Arquivo de entrada.
              p_arqs TYPE rlgrap-filename.  "Arquivo de saída.

  SELECTION-SCREEN SKIP 1.

  PARAMETERS: p_loc RADIOBUTTON GROUP gr1 USER-COMMAND usr01 DEFAULT 'X',
              p_ser RADIOBUTTON GROUP gr1.

SELECTION-SCREEN END OF BLOCK b_par.

START-OF-SELECTION.
  PERFORM: zf_limpar_dados,
           zf_buscar_dados_arq,
           zf_preparar_dados,
           zf_processar_dados,
           zf_preparar_arq_sai,
           zf_download_arq.

**********************************************************************
* Eventos
**********************************************************************
AT SELECTION-SCREEN ON VALUE-REQUEST FOR p_arqe.  "Este evento ativa a pesquisa do parâmetro p_arqe
  PERFORM zf_buscar_arquivo USING p_arqe          " Ao clicar na pesquisa é chamada a função zf_buscar_arquivo passando dois parâmetros: o conteúdo do campo e abap_true.
                                  abap_true.

AT SELECTION-SCREEN ON VALUE-REQUEST FOR p_arqs.
  PERFORM zf_buscar_arquivo USING p_arqs
                                  abap_false.

*&---------------------------------------------------------------------*
*&      Form  ZF_BUSCAR_ARQUIVO
*&---------------------------------------------------------------------*
*       Abre um modal para seleção dos arquivos
*----------------------------------------------------------------------*

FORM ZF_BUSCAR_ARQUIVO USING p_arq
                              p_abrir.

  DATA: vl_fullpath TYPE string. "String que receberá o caminho do arquivo.

  IF p_loc EQ abap_true.
    "Caso esteja marcado o radiobutton para arquivo local

    IF p_abrir EQ abap_true.
      "Caso esteja sendo buscado um arquivo para o campo de entrada
      CALL FUNCTION 'GUI_FILE_LOAD_DIALOG'
        EXPORTING
          window_title      = 'Escolha o arquivo para abrir'
          default_extension = 'csv'
          file_filter       = 'Arquivo CSV (*.csv)|*.CSV| Text Files (*.txt)|*.TXT|' "Formato correto do File_Filter
        IMPORTING
          fullpath          = vl_fullpath.

    ELSE.
      "Caso esteja buscando arquivo para o campo de saída
      CALL FUNCTION 'GUI_FILE_SAVE_DIALOG'
        EXPORTING
          window_title      = 'Escolha o nome do arquivo para salvar '
          default_extension = 'csv'
          file_filter       = 'Arquivo CSV (*.csv)|*.CSV| Text Files (*.txt)|*.TXT|'
        IMPORTING
          fullpath          = vl_fullpath.

    ENDIF.

    p_arq = vl_fullpath. "Atribui o caminho do arquivo ao parâmetro que será retornado para tela de seleção.

  ELSEIF p_ser EQ abap_true.

    "Caso esteja marcado o radiobutton para arquivo no servidor
    CALL FUNCTION 'ZMF_GE_UNIX_DIR_TREE'
      EXPORTING
        input          = 'interfaces'
        show_files     = 'X'
      IMPORTING
        output         = p_arq
      EXCEPTIONS
        internal_error = 1
        wrong_path     = 2
        OTHERS         = 3.

  ENDIF.

ENDFORM.
*&---------------------------------------------------------------------*
*&      Form  ZF_LIMPAR_DADOS
*&---------------------------------------------------------------------*

FORM ZF_LIMPAR_DADOS .

ENDFORM.
*&---------------------------------------------------------------------*
*&      Form  ZF_BUSCAR_DADOS_ARQ
*&---------------------------------------------------------------------*
*       Carrega o arquivo que foi selecionado anteriormente
*----------------------------------------------------------------------*

FORM ZF_BUSCAR_DADOS_ARQ .

  DATA: vl_filename TYPE string,
        wa_arq      TYPE ty_arq.

  IF p_loc EQ abap_true.

    vl_filename = p_arqe.     "Recebe o caminho do arquivo de entrada.

    "Passa o caminho para a função que copia o arquivo e grava na variável tg_arq_ent.
    CALL FUNCTION 'GUI_UPLOAD'
      EXPORTING
        filename                = vl_filename
        filetype                = 'ASC' "ASC - Texto | BIN - Binario
      TABLES
        data_tab                = tg_arq_ent
      EXCEPTIONS
        file_open_error         = 1
        file_read_error         = 2
        no_batch                = 3
        gui_refuse_filetransfer = 4
        invalid_type            = 5
        no_authority            = 6
        unknown_error           = 7
        bad_data_format         = 8
        header_not_allowed      = 9
        separator_not_allowed   = 10
        header_too_long         = 11
        unknown_dp_error        = 12
        access_denied           = 13
        dp_out_of_memory        = 14
        disk_full               = 15
        dp_timeout              = 16
        OTHERS                  = 17.

    IF sy-subrc <> 0.
* Implement suitable error handling here
    ENDIF.

  ELSEIF p_ser EQ 'X'.
    OPEN DATASET p_arqe IN TEXT MODE FOR INPUT ENCODING DEFAULT.

    DO.
      READ DATASET p_arqe INTO wa_arq-linha.
      IF sy-subrc NE 0.
        EXIT.
      ENDIF.

      APPEND wa_arq TO tg_arq_ent.
    ENDDO.

    CLOSE DATASET p_arqe.
  ENDIF.

ENDFORM.
*&---------------------------------------------------------------------*
*&      Form  ZF_PREPARAR_DADOS
*&---------------------------------------------------------------------*
*       Percorre a tabela interna que foi recebida na entrada e grava os dados em uma nova tabela interna
*----------------------------------------------------------------------*

FORM ZF_PREPARAR_DADOS .

  DATA: wa_arq_ent TYPE ty_arq,
        wa_dados   TYPE ty_lay_ent.

  LOOP AT tg_arq_ent INTO wa_arq_ent.
    SPLIT wa_arq_ent-linha AT ';'
         INTO wa_dados-cpf
              wa_dados-nome
              wa_dados-dtnasc
              wa_dados-sexonasc.

    APPEND wa_dados TO tg_dados_ent.

  ENDLOOP.

ENDFORM.

*&---------------------------------------------------------------------*
*&      Form  ZF_PROCESSAR_DADOS
*&---------------------------------------------------------------------*
FORM zf_processar_dados .
  DATA: wa_dados_ent TYPE ty_lay_ent,
        tl_bdcdata   TYPE TABLE OF bdcdata,
        tl_message   TYPE TABLE OF bdcmsgcoll,
        wa_message   TYPE bdcmsgcoll,
        vl_mode      TYPE c VALUE 'N',
        vl_id        TYPE t100-arbgb,
        vl_no        TYPE t100-msgnr,
        vl_msgv1     TYPE balm-msgv1,
        vl_msgv2     TYPE balm-msgv2,
        vl_msgv3     TYPE balm-msgv3,
        vl_msgv4     TYPE balm-msgv4,
        vl_msgtext   TYPE string.

  LOOP AT tg_dados_ent into wa_dados_ent.

    FREE: tl_bdcdata.
    "Construir o caminho do Batch Input
    PERFORM zf_preencher_bdcdata TABLES tl_bdcdata
                                 USING:
              'ZTRN_CADASTRO_LCG'   '9000'    'X'   space                   space,
              ''                    ''        ''    'BDC_OKCODE'            '=BTN9100',
              'ZTRN_CADASTRO_LCG'   '9100'    'X'   ''                      space,
              ''                    ''        ''    'WA_PESSOA-CPF'         wa_dados_ent-cpf,
              ''                    ''        ''    'WA_PESSOA-NOME'        wa_dados_ent-nome,
              ''                    ''        ''    'WA_PESSOA-DTNASC'      wa_dados_ent-dtnasc,
              ''                    ''        ''    'WA_PESSOA-SEXONASC'    wa_dados_ent-sexonasc,
              ''                    ''        ''    'BDC_OKCODE'            '=BTN_SALVAR'.

    "Executar o batch input
    CALL TRANSACTION 'ZTRN_T_CADASTRO_LCG' "Transação executada
      USING tl_bdcdata          "As ações a serem executadas
      MESSAGES INTO tl_message  "Captura todas message da execução
      MODE vl_mode. " A - Exibir todas as telas
    " E - Somente vai exibir se houver message type E
    " N - Background

    "Exibição de erros em modo WRITE.
*    IF sy-subrc NE 0.
*
*      WRITE:/ 'CPF: '.
*
*      WRITE: wa_dados_ent-cpf.
*
*      LOOP AT tl_message INTO wa_message.
*        vl_id    = wa_message-msgid.
*        vl_no    = wa_message-msgnr.
*        vl_msgv1 = wa_message-msgv1.
*        vl_msgv2 = wa_message-msgv2.
*        vl_msgv3 = wa_message-msgv3.
*        vl_msgv4 = wa_message-msgv4.
*
*        MESSAGE ID  vl_id
*                TYPE wa_message-msgtyp
*                NUMBER wa_message-msgnr
*                WITH wa_message-msgv1
*                     wa_message-msgv2
*                     wa_message-msgv3
*                     wa_message-msgv4
*               INTO vl_msgtext.
*
*        CALL FUNCTION 'MESSAGE_PREPARE'
*          EXPORTING
**           language               = sy-langu
*            msg_id                 = vl_id
*            msg_no                 = vl_no
*            msg_var1               = vl_msgv1
*            msg_var2               = vl_msgv2
*            msg_var3               = vl_msgv3
*            msg_var4               = vl_msgv4
*          IMPORTING
*            msg_text               = vl_msgtext
*          EXCEPTIONS
*            function_not_completed = 1
*            message_not_found      = 2
*            OTHERS                 = 3.
*
*        WRITE:/ vl_msgtext.
*
*      ENDLOOP.
*
*
*
*      WRITE:/ space.
*
*    ENDIF.

  " Exibição de erros em arquivo para download.
    LOOP AT tl_message INTO wa_message.
      IF wa_message-MSGTYP = 'I'.
        wa_message-MSGV4 = wa_dados_ent-cpf.
        APPEND wa_message TO tg_message.
      ENDIF.
    ENDLOOP.

    FREE: tl_message.
   " Chamada da função zf_preparar_arq_sai e zf_download_arq no principal

  ENDLOOP.
  " Exporta as mensagens de erro para uma tabela global

ENDFORM.


*&---------------------------------------------------------------------*
*&      Form  ZF_PREENCHER_BDCDATA
*&---------------------------------------------------------------------*
FORM zf_preencher_bdcdata  TABLES   pt_bdcdata STRUCTURE bdcdata
                           USING    p_programa
                                    p_tela
                                    p_inicio
                                    p_nome_campo
                                    p_valor_campo.
  DATA: wa_bdcdata TYPE bdcdata.

  wa_bdcdata-program  = p_programa.
  wa_bdcdata-dynpro   = p_tela.
  wa_bdcdata-dynbegin = p_inicio.
  wa_bdcdata-fnam     = p_nome_campo.
  wa_bdcdata-fval     = p_valor_campo.

  APPEND wa_bdcdata TO pt_bdcdata.
ENDFORM.
*&---------------------------------------------------------------------*
*&      Form  ZF_PREPARAR_ARQ_SAI
*&---------------------------------------------------------------------*

FORM ZF_PREPARAR_ARQ_SAI .
  DATA: wa_message TYPE bdcmsgcoll,
        wa_arq_sai TYPE ty_arq.

  LOOP AT tg_message INTO wa_message.

    CONCATENATE: wa_message-MSGV4
                 wa_message-MSGV1
                 INTO wa_arq_sai-linha
                 SEPARATED BY ' - '.

    APPEND wa_arq_sai to tg_arq_sai.

  ENDLOOP.


ENDFORM.
*&---------------------------------------------------------------------*
*&      Form  ZF_DOWNLOAD_ARQ
*&---------------------------------------------------------------------*

FORM ZF_DOWNLOAD_ARQ .

  DATA: vl_filename TYPE string,
        wa_dados    TYPE ty_arq.

  IF p_loc EQ 'X'.
    vl_filename = p_arqs.
*   CALL METHOD cl_gui_frontend_services=>gui_download
*     EXPORTING
**       bin_filesize              =
*       filename                  =
**       filetype                  = 'ASC'
**       append                    = SPACE
**       write_field_separator     = SPACE
**       header                    = '00'
**       trunc_trailing_blanks     = SPACE
**       write_lf                  = 'X'
**       col_select                = SPACE
**       col_select_mask           = SPACE
**       dat_mode                  = SPACE
**       confirm_overwrite         = SPACE
**       no_auth_check             = SPACE
**       codepage                  = SPACE
**       ignore_cerr               = ABAP_TRUE
**       replacement               = '#'
**       write_bom                 = SPACE
**       trunc_trailing_blanks_eol = 'X'
**       wk1_n_format              = SPACE
**       wk1_n_size                = SPACE
**       wk1_t_format              = SPACE
**       wk1_t_size                = SPACE
**       show_transfer_status      = 'X'
**       fieldnames                =
**       write_lf_after_last_line  = 'X'
**       virus_scan_profile        = '/SCET/GUI_DOWNLOAD'
**     IMPORTING
**       filelength                =
*     changing
*       data_tab                  =
**     EXCEPTIONS
**       file_write_error          = 1
**       no_batch                  = 2
**       gui_refuse_filetransfer   = 3
**       invalid_type              = 4
**       no_authority              = 5
**       unknown_error             = 6
**       header_not_allowed        = 7
**       separator_not_allowed     = 8
**       filesize_not_allowed      = 9
**       header_too_long           = 10
**       dp_error_create           = 11
**       dp_error_send             = 12
**       dp_error_write            = 13
**       unknown_dp_error          = 14
**       access_denied             = 15
**       dp_out_of_memory          = 16
**       disk_full                 = 17
**       dp_timeout                = 18
**       file_not_found            = 19
**       dataprovider_exception    = 20
**       control_flush_error       = 21
**       not_supported_by_gui      = 22
**       error_no_gui              = 23
**       others                    = 24
*           .
*   IF sy-subrc <> 0.
**    Implement suitable error handling here
*   ENDIF.

    CALL FUNCTION 'GUI_DOWNLOAD'
      EXPORTING
        filename                = vl_filename
      TABLES
        data_tab                = tg_arq_sai
      EXCEPTIONS
        file_write_error        = 1
        no_batch                = 2
        gui_refuse_filetransfer = 3
        invalid_type            = 4
        no_authority            = 5
        unknown_error           = 6
        header_not_allowed      = 7
        separator_not_allowed   = 8
        filesize_not_allowed    = 9
        header_too_long         = 10
        dp_error_create         = 11
        dp_error_send           = 12
        dp_error_write          = 13
        unknown_dp_error        = 14
        access_denied           = 15
        dp_out_of_memory        = 16
        disk_full               = 17
        dp_timeout              = 18
        file_not_found          = 19
        dataprovider_exception  = 20
        control_flush_error     = 21
        OTHERS                  = 22.
    IF sy-subrc <> 0.
* Implement suitable error handling here
    ENDIF.

  ELSEIF p_ser EQ 'X'.
    OPEN DATASET p_arqs IN TEXT MODE FOR OUTPUT ENCODING DEFAULT.

    LOOP AT tg_arq_sai INTO wa_dados.
      TRANSFER wa_dados-linha TO p_arqs.
    ENDLOOP.

    CLOSE DATASET p_arqs.
  ENDIF.
ENDFORM.