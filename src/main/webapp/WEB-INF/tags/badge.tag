<%--
    Componente: badge de status (S25, extraido para tag em S26).

    Uso:
        <ui:badge variante="success">Ativo</ui:badge>
        <ui:badge>Sem status</ui:badge>          (variante padrao: neutral)

    CUIDADO ao editar este comentario: NAO escreva a marca de abertura de comentario JSP
    aqui dentro. Um comentario JSP DENTRO de outro termina no primeiro fechamento, e o
    resto do texto vira conteudo da pagina — foi exatamente o que aconteceu na primeira
    versao deste arquivo (o comentario saiu impresso dentro do badge). Por isso
    `scripts/ui-tabelas.sh` reprova qualquer marca de comentario, de diretiva ou de
    expressao nao resolvida que chegue ao HTML renderizado.

    Variantes: `success`, `warning`, `error`, `neutral`, `ghost`, `info` (padrao:
    `neutral`). Sao as cores do tema; a lista fechada vive em `ui-preview.html`, que e a
    safelist explicita do Tailwind — o nome da classe e montado aqui por variavel, e o
    Tailwind NAO extrai classe montada. Por isso `scripts/ui-tabelas.sh` confere, no
    bundle gerado, que toda variante usada no HTML renderizado existe de fato.

    A COR NAO E DECIDIDA AQUI: quem chama escolhe a variante a partir do valor do
    dominio (ex.: `<ui:badge variante="${area.status eq 'Ativo' ? 'success' : 'neutral'}">`).
    O mapeamento tem de ser literal no JSP, que e o mesmo motivo documentado em
    `ui:reserva-status`.
--%>
<%@ tag pageEncoding="UTF-8" trimDirectiveWhitespaces="true" %>
<%@ taglib prefix="c" uri="jakarta.tags.core" %>
<%@ attribute name="variante" required="false" description="success | warning | error | neutral | ghost | info (padrao: neutral)" %>

<c:set var="badgeVariante" value="${empty variante ? 'neutral' : variante}" />
<span class="badge badge-${badgeVariante}"><jsp:doBody /></span>
