package br.com.dunnastecnologia.chamados.infrastructure.controller.web;

import br.com.dunnastecnologia.chamados.application.Security.AuthenticatedUser;
import br.com.dunnastecnologia.chamados.application.pagination.PageResult;
import br.com.dunnastecnologia.chamados.domain.model.Area;
import br.com.dunnastecnologia.chamados.domain.model.Bloco;
import br.com.dunnastecnologia.chamados.domain.model.Chamado;
import br.com.dunnastecnologia.chamados.domain.model.Comentario;
import br.com.dunnastecnologia.chamados.domain.model.SolicitacaoArea;
import br.com.dunnastecnologia.chamados.domain.model.StatusChamado;
import br.com.dunnastecnologia.chamados.domain.model.TipoChamado;
import br.com.dunnastecnologia.chamados.domain.model.Unidade;
import br.com.dunnastecnologia.chamados.domain.model.Usuario;
import br.com.dunnastecnologia.chamados.infrastructure.exception.UnauthorizedOperationException;
import br.com.dunnastecnologia.chamados.infrastructure.security.adapter.UserDetailsImpl;
import org.springframework.http.ContentDisposition;
import org.springframework.http.HttpHeaders;
import org.springframework.http.MediaType;
import org.springframework.http.ResponseEntity;
import org.springframework.security.authentication.AnonymousAuthenticationToken;
import org.springframework.security.core.Authentication;
import org.springframework.stereotype.Component;
import org.springframework.ui.Model;
import org.springframework.web.multipart.MultipartFile;

import java.time.DayOfWeek;
import java.time.LocalDate;
import java.time.LocalDateTime;
import java.time.format.DateTimeFormatter;
import java.util.ArrayList;
import java.util.Locale;
import java.util.LinkedHashMap;
import java.util.List;
import java.util.Map;
import java.util.UUID;
import java.util.function.Function;

@Component
public class WebControllerSupport {

    private static final int DEFAULT_PAGE = 0;
    private static final int DEFAULT_SIZE = 10;
    private static final int MAX_SIZE = 100;
    private static final DateTimeFormatter DATE_TIME_FORMATTER = DateTimeFormatter.ofPattern("dd/MM/yyyy HH:mm");

    public AuthenticatedUser authenticatedUser(Authentication authentication) {
        if (authentication == null
                || !authentication.isAuthenticated()
                || authentication instanceof AnonymousAuthenticationToken
                || !(authentication.getPrincipal() instanceof UserDetailsImpl userDetails)) {
            throw new UnauthorizedOperationException("Usuario nao autenticado");
        }

        Usuario usuario = userDetails.getUsuario();
        return new AuthenticatedUser(usuario.getId(), usuario.getEmail(), usuario.getRole());
    }

    public boolean isAuthenticated(Authentication authentication) {
        return authentication != null
                && authentication.isAuthenticated()
                && !(authentication instanceof AnonymousAuthenticationToken)
                && authentication.getPrincipal() instanceof UserDetailsImpl;
    }

    public org.springframework.data.domain.PageRequest pageRequest(Integer page, Integer size) {
        int resolvedPage = page == null || page < 0
                ? DEFAULT_PAGE
                : page;

        int resolvedSize = size == null || size <= 0
                ? DEFAULT_SIZE
                : Math.min(size, MAX_SIZE);

        return org.springframework.data.domain.PageRequest.of(resolvedPage, resolvedSize);
    }

    public Map<String, Object> pageMetadata(PageResult<?> pageResult) {
        return Map.of(
                "page", pageResult.page(),
                "size", pageResult.size(),
                "totalElements", pageResult.totalElements(),
                "totalPages", pageResult.totalPages(),
                "hasPrevious", pageResult.page() > 0,
                "hasNext", pageResult.page() + 1 < pageResult.totalPages()
        );
    }

    public String homePathForRole(String role) {
        return switch (role) {
            case "ROLE_ADMINISTRADOR" -> "/admin";
            case "ROLE_COLABORADOR" -> "/colaborador";
            case "ROLE_MORADOR" -> "/morador";
            default -> "/";
        };
    }

    public String roleLabel(String role) {
        return switch (role) {
            case "ROLE_ADMINISTRADOR" -> "Administrador";
            case "ROLE_COLABORADOR" -> "Colaborador";
            case "ROLE_MORADOR" -> "Morador";
            default -> role;
        };
    }

    public String userTypeLabel(Usuario usuario) {
        return roleLabel(usuario.getRole());
    }

    public <T> List<Map<String, Object>> mapContent(List<T> content, Function<T, Map<String, Object>> mapper) {
        return content.stream().map(mapper).toList();
    }

    public Map<String, Object> toBlocoMap(Bloco bloco) {
        return Map.of(
                "id", bloco.getId(),
                "identificacao", bloco.getIdentificacao(),
                "quantidadeAndares", bloco.getQuantidadeAndares(),
                "apartamentosPorAndar", bloco.getApartamentosPorAndar()
        );
    }

    public Map<String, Object> toUnidadeMap(Unidade unidade) {
        Map<String, Object> values = new LinkedHashMap<>();
        values.put("id", unidade.getId());
        values.put("identificacao", unidade.getIdentificacao());
        values.put("andar", unidade.getAndar());
        values.put("blocoId", unidade.getBloco() == null ? null : unidade.getBloco().getId());
        values.put("blocoIdentificacao", unidade.getBloco() == null ? null : unidade.getBloco().getIdentificacao());
        return values;
    }

    public Map<String, Object> toUsuarioMap(Usuario usuario) {
        return Map.of(
                "id", usuario.getId(),
                "nome", usuario.getNome(),
                "email", usuario.getEmail(),
                "role", usuario.getRole(),
                "tipo", userTypeLabel(usuario)
        );
    }

    public Map<String, Object> toAreaMap(Area area) {
        Map<String, Object> values = new LinkedHashMap<>();
        values.put("id", area.getId());
        values.put("nome", area.getNome());
        values.put("status", area.getStatus() == null ? null : area.getStatus().getValor());
        values.put("statusNome", area.getStatus() == null ? null : area.getStatus().name());
        return values;
    }

    public List<Map<String, Object>> areasDasReservas(List<SolicitacaoArea> reservas) {
        Map<UUID, Area> distintas = new LinkedHashMap<>();
        for (SolicitacaoArea reserva : reservas) {
            Area area = reserva.getArea();
            if (area != null) {
                distintas.putIfAbsent(area.getId(), area);
            }
        }
        return mapContent(new ArrayList<>(distintas.values()), this::toAreaMap);
    }

    /**
     * Calcula a janela, a navegacao e o rotulo da agenda/calendario a partir de uma referencia.
     * Visao mensal: primeiro dia do mes, com folga de 7 dias em cada lado para a grade. Visao semanal:
     * domingo a sabado, alinhada ao firstDay padrao do FullCalendar.
     */
    public PeriodoAgenda periodoAgenda(LocalDate inicio, boolean porSemana) {
        LocalDate referencia = inicio == null ? LocalDate.now() : inicio;
        LocalDate periodoReferencia = porSemana
                ? referencia.with(DayOfWeek.SUNDAY)
                : referencia.withDayOfMonth(1);

        LocalDateTime janelaInicio;
        LocalDateTime janelaFim;
        LocalDate anterior;
        LocalDate seguinte;
        String label;
        if (porSemana) {
            janelaInicio = periodoReferencia.atStartOfDay();
            janelaFim = periodoReferencia.plusDays(7).atStartOfDay();
            anterior = periodoReferencia.minusWeeks(1);
            seguinte = periodoReferencia.plusWeeks(1);
            DateTimeFormatter diaMes = DateTimeFormatter.ofPattern("dd/MM");
            label = "Semana de " + periodoReferencia.format(diaMes)
                    + " a " + periodoReferencia.plusDays(6).format(diaMes);
        } else {
            janelaInicio = periodoReferencia.minusDays(7).atStartOfDay();
            janelaFim = periodoReferencia.plusMonths(1).plusDays(7).atStartOfDay();
            anterior = periodoReferencia.minusMonths(1);
            seguinte = periodoReferencia.plusMonths(1);
            DateTimeFormatter formato = DateTimeFormatter.ofPattern("MMMM 'de' yyyy", new Locale("pt", "BR"));
            String rotulo = periodoReferencia.format(formato);
            label = Character.toUpperCase(rotulo.charAt(0)) + rotulo.substring(1);
        }
        return new PeriodoAgenda(
                periodoReferencia, janelaInicio, janelaFim, anterior, seguinte, label, porSemana ? "semana" : "mes");
    }

    public record PeriodoAgenda(
            LocalDate referencia,
            LocalDateTime janelaInicio,
            LocalDateTime janelaFim,
            LocalDate anterior,
            LocalDate seguinte,
            String label,
            String view
    ) {
    }

    public void adicionarPeriodoAgenda(Model model, PeriodoAgenda periodo) {
        model.addAttribute("viewAtual", periodo.view());
        model.addAttribute("periodoReferencia", periodo.referencia());
        model.addAttribute("periodoLabel", periodo.label());
        model.addAttribute("periodoAnterior", periodo.anterior());
        model.addAttribute("periodoSeguinte", periodo.seguinte());
    }

    public Map<String, Object> toTipoChamadoMap(TipoChamado tipoChamado) {
        return Map.of(
                "id", tipoChamado.getId(),
                "titulo", tipoChamado.getTitulo(),
                "prazoHoras", tipoChamado.getPrazoHoras()
        );
    }

    public Map<String, Object> toStatusChamadoMap(StatusChamado statusChamado) {
        return Map.of(
                "id", statusChamado.getId(),
                "nome", statusChamado.getNome(),
                "inicialPadrao", Boolean.TRUE.equals(statusChamado.getInicialPadrao())
        );
    }

    public Map<String, Object> toChamadoMap(Chamado chamado) {
        Map<String, Object> values = new LinkedHashMap<>();
        values.put("id", chamado.getId());
        values.put("descricao", chamado.getDescricao());
        values.put("dataAbertura", chamado.getDataAbertura());
        values.put("dataAberturaFormatada", formatDateTime(chamado.getDataAbertura()));
        values.put("dataFinalizacao", chamado.getDataFinalizacao());
        values.put("dataFinalizacaoFormatada", formatDateTime(chamado.getDataFinalizacao()));
        values.put("finalizado", chamado.getDataFinalizacao() != null);
        values.put("moradorId", chamado.getMorador() == null ? null : chamado.getMorador().getId());
        values.put("moradorNome", chamado.getMorador() == null ? null : chamado.getMorador().getNome());
        values.put("unidadeId", chamado.getUnidade() == null ? null : chamado.getUnidade().getId());
        values.put("unidadeIdentificacao", chamado.getUnidade() == null ? null : chamado.getUnidade().getIdentificacao());
        values.put(
                "blocoIdentificacao",
                chamado.getUnidade() == null || chamado.getUnidade().getBloco() == null
                        ? null
                        : chamado.getUnidade().getBloco().getIdentificacao()
        );
        values.put("tipoChamadoId", chamado.getTipoChamado() == null ? null : chamado.getTipoChamado().getId());
        values.put(
                "tipoChamadoTitulo",
                chamado.getTipoChamado() == null ? null : chamado.getTipoChamado().getTitulo()
        );
        values.put("statusId", chamado.getStatus() == null ? null : chamado.getStatus().getId());
        values.put("statusNome", chamado.getStatus() == null ? null : chamado.getStatus().getNome());
        return values;
    }

    public Map<String, Object> toSolicitacaoAreaMap(SolicitacaoArea solicitacao) {
        Map<String, Object> values = new LinkedHashMap<>();
        values.put("id", solicitacao.getId());
        values.put("areaId", solicitacao.getArea() == null ? null : solicitacao.getArea().getId());
        values.put("areaNome", solicitacao.getArea() == null ? null : solicitacao.getArea().getNome());
        values.put("moradorId", solicitacao.getMorador() == null ? null : solicitacao.getMorador().getId());
        values.put("moradorNome", solicitacao.getMorador() == null ? null : solicitacao.getMorador().getNome());
        values.put("unidadeId", solicitacao.getUnidade() == null ? null : solicitacao.getUnidade().getId());
        values.put(
                "unidadeIdentificacao",
                solicitacao.getUnidade() == null ? null : solicitacao.getUnidade().getIdentificacao()
        );
        values.put("inicio", solicitacao.getInicio());
        values.put("inicioFormatado", formatDateTime(solicitacao.getInicio()));
        values.put("fim", solicitacao.getFim());
        values.put("fimFormatado", formatDateTime(solicitacao.getFim()));
        values.put("status", solicitacao.getStatus() == null ? null : solicitacao.getStatus().getValor());
        values.put("statusNome", solicitacao.getStatus() == null ? null : solicitacao.getStatus().name());
        values.put("motivoNegacao", solicitacao.getMotivoNegacao());
        values.put("createdAt", solicitacao.getCreatedAt());
        return values;
    }

    public Map<String, Object> toComentarioMap(Comentario comentario) {
        Map<String, Object> values = new LinkedHashMap<>();
        values.put("id", comentario.getId());
        values.put("mensagem", comentario.getMensagem());
        values.put("dataCriacao", comentario.getDataCriacao());
        values.put("dataCriacaoFormatada", formatDateTime(comentario.getDataCriacao()));
        values.put("autorId", comentario.getAutor() == null ? null : comentario.getAutor().getId());
        values.put("autorNome", comentario.getAutor() == null ? null : comentario.getAutor().getNome());
        values.put("autorRole", comentario.getAutor() == null ? null : roleLabel(comentario.getAutor().getRole()));
        values.put(
                "anexos",
                comentario.getAnexos().stream()
                        .map(anexo -> {
                            Map<String, Object> anexoValues = new LinkedHashMap<>();
                            anexoValues.put("id", anexo.getId());
                            anexoValues.put("nomeArquivo", anexo.getNomeArquivo());
                            anexoValues.put("contentType", anexo.getContentType());
                            anexoValues.put("tamanhoBytes", anexo.getTamanhoBytes());
                            anexoValues.put("tamanhoFormatado", formatBytes(anexo.getTamanhoBytes()));
                            return anexoValues;
                        })
                        .toList()
        );
        return values;
    }

    public Map<String, Object> toAnexoMap(
            UUID id,
            String nomeArquivo,
            String contentType,
            long tamanhoBytes
    ) {
        Map<String, Object> values = new LinkedHashMap<>();
        values.put("id", id);
        values.put("nomeArquivo", nomeArquivo);
        values.put("contentType", contentType);
        values.put("tamanhoBytes", tamanhoBytes);
        values.put("tamanhoFormatado", formatBytes(tamanhoBytes));
        return values;
    }

    public UploadedFileData optionalUploadedFile(MultipartFile arquivo, String errorMessage) {
        if (arquivo == null || arquivo.isEmpty()) {
            return null;
        }
        return uploadedFile(arquivo, errorMessage);
    }

    public UploadedFileData requiredUploadedFile(
            MultipartFile arquivo,
            String emptyFileMessage,
            String errorMessage
    ) {
        if (arquivo == null || arquivo.isEmpty()) {
            throw new IllegalArgumentException(emptyFileMessage);
        }
        return uploadedFile(arquivo, errorMessage);
    }

    public ResponseEntity<byte[]> downloadResponse(
            String nomeArquivo,
            String contentType,
            long tamanhoBytes,
            byte[] conteudo
    ) {
        MediaType mediaType = MediaType.APPLICATION_OCTET_STREAM;
        if (contentType != null && !contentType.isBlank()) {
            mediaType = MediaType.parseMediaType(contentType);
        }

        return ResponseEntity.ok()
                .header(
                        HttpHeaders.CONTENT_DISPOSITION,
                        ContentDisposition.attachment().filename(nomeArquivo).build().toString()
                )
                .contentType(mediaType)
                .contentLength(tamanhoBytes)
                .body(conteudo);
    }

    private String formatDateTime(LocalDateTime value) {
        if (value == null) {
            return null;
        }
        return DATE_TIME_FORMATTER.format(value);
    }

    private String formatBytes(long bytes) {
        if (bytes < 1024) {
            return bytes + " B";
        }
        double kilobytes = bytes / 1024.0;
        if (kilobytes < 1024) {
            return String.format(Locale.US, "%.1f KB", kilobytes);
        }
        double megabytes = kilobytes / 1024.0;
        return String.format(Locale.US, "%.1f MB", megabytes);
    }

    private UploadedFileData uploadedFile(MultipartFile arquivo, String errorMessage) {
        try {
            return new UploadedFileData(
                    arquivo.getOriginalFilename(),
                    arquivo.getContentType(),
                    arquivo.getSize(),
                    arquivo.getBytes()
            );
        } catch (Exception exception) {
            throw new IllegalArgumentException(errorMessage, exception);
        }
    }

    public record UploadedFileData(
            String nomeArquivo,
            String contentType,
            long tamanhoBytes,
            byte[] conteudo
    ) {
    }
}
