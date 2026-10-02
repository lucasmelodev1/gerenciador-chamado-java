package br.com.dunnastecnologia.chamados.infrastructure.config;

import io.swagger.v3.oas.annotations.OpenAPIDefinition;
import io.swagger.v3.oas.annotations.tags.Tag;
import io.swagger.v3.oas.models.OpenAPI;
import io.swagger.v3.oas.models.info.Info;
import io.swagger.v3.oas.models.servers.Server;
import org.springdoc.core.models.GroupedOpenApi;
import org.springframework.context.annotation.Bean;
import org.springframework.context.annotation.Configuration;

@Configuration
@OpenAPIDefinition(tags = {
        @Tag(name = "01 - Publico Web - Paginas", description = "Paginas publicas e pontos de entrada da interface web."),
        @Tag(name = "02 - Admin Web - Paginas", description = "Paginas da interface web disponiveis para administrador."),
        @Tag(name = "03 - Admin Web - Blocos", description = "Operacoes de blocos disponiveis para administrador."),
        @Tag(name = "04 - Admin Web - Usuarios", description = "Operacoes de usuarios disponiveis para administrador."),
        @Tag(name = "05 - Admin Web - Moradores", description = "Operacoes de moradores disponiveis para administrador."),
        @Tag(name = "06 - Admin Web - Colaboradores", description = "Operacoes de colaboradores disponiveis para administrador."),
        @Tag(name = "07 - Admin Web - Tipos de Chamado", description = "Operacoes de tipos de chamado disponiveis para administrador."),
        @Tag(name = "08 - Admin Web - Status de Chamado", description = "Operacoes de status de chamado disponiveis para administrador."),
        @Tag(name = "09 - Admin Web - Chamados", description = "Operacoes de chamados disponiveis para administrador."),
        @Tag(name = "10 - Colaborador Web - Paginas", description = "Paginas da interface web disponiveis para colaborador."),
        @Tag(name = "11 - Colaborador Web - Chamados", description = "Operacoes de chamados disponiveis para colaborador."),
        @Tag(name = "12 - Morador Web - Paginas", description = "Paginas da interface web disponiveis para morador."),
        @Tag(name = "13 - Morador Web - Chamados", description = "Operacoes de chamados disponiveis para morador."),
        @Tag(name = "14 - Admin Web - Areas", description = "Operacoes de areas disponiveis para administrador.")
})
public class OpenApiConfig {

    @Bean
    public OpenAPI gerenciadorChamadosOpenApi() {
        return new OpenAPI()
                .info(new Info()
                        .title("Gerenciador de Chamados")
                        .version("1.0.0")
                        .description("Documentacao OpenAPI dos endpoints web do sistema de gerenciamento de chamados."))
                .addServersItem(new Server().url("/").description("Servidor atual"));
    }

    @Bean
    public GroupedOpenApi webControllersOpenApi() {
        return GroupedOpenApi.builder()
                .group("web")
                .pathsToMatch("/**")
                .pathsToExclude(
                        "/error",
                        "/css/**",
                        "/js/**",
                        "/images/**",
                        "/webjars/**",
                        "/swagger-ui/**",
                        "/swagger-ui.html",
                        "/v3/api-docs/**",
                        "/v3/api-docs",
                        "/v3/api-docs.yaml"
                )
                .build();
    }
}
