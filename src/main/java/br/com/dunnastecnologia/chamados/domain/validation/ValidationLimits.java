package br.com.dunnastecnologia.chamados.domain.validation;

public final class ValidationLimits {

    public static final int DEFAULT_TEXT_MAX_LENGTH = 255;
    public static final int BLOCO_IDENTIFICACAO_MAX_LENGTH = 255;
    public static final int USUARIO_NOME_MAX_LENGTH = 255;
    public static final int USUARIO_EMAIL_MAX_LENGTH = 255;
    public static final int USUARIO_SENHA_MAX_LENGTH = 255;
    public static final int AREA_NOME_MAX_LENGTH = 255;
    public static final int AREA_STATUS_MAX_LENGTH = 255;
    public static final int TIPO_CHAMADO_TITULO_MAX_LENGTH = 255;
    public static final int STATUS_CHAMADO_NOME_MAX_LENGTH = 255;
    public static final int CHAMADO_DESCRICAO_MAX_LENGTH = 255;
    public static final int COMENTARIO_MENSAGEM_MAX_LENGTH = 255;
    public static final int ANEXO_NOME_ARQUIVO_MAX_LENGTH = 255;
    public static final int ANEXO_CONTENT_TYPE_MAX_LENGTH = 255;
    public static final long ANEXO_TAMANHO_MAX_BYTES = 5L * 1024L * 1024L;

    private ValidationLimits() {
    }
}
