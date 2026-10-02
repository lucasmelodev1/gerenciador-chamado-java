package br.com.dunnastecnologia.chamados.infrastructure.config;

import java.util.List;

import org.springframework.beans.factory.annotation.Value;

import br.com.dunnastecnologia.chamados.infrastructure.security.JwtAuthenticationFilter;
import jakarta.servlet.DispatcherType;
import org.springframework.context.annotation.Bean;
import org.springframework.context.annotation.Configuration;
import org.springframework.core.annotation.Order;
import org.springframework.http.HttpMethod;
import org.springframework.http.HttpStatus;
import org.springframework.security.authentication.AuthenticationManager;
import org.springframework.security.authentication.AuthenticationProvider;
import org.springframework.security.authentication.dao.DaoAuthenticationProvider;
import org.springframework.security.config.annotation.authentication.configuration.AuthenticationConfiguration;
import org.springframework.security.config.annotation.method.configuration.EnableMethodSecurity;
import org.springframework.security.config.annotation.web.builders.HttpSecurity;
import org.springframework.security.config.annotation.web.configuration.EnableWebSecurity;
import org.springframework.security.config.annotation.web.configurers.AbstractHttpConfigurer;
import org.springframework.security.config.http.SessionCreationPolicy;
import org.springframework.security.core.userdetails.UserDetailsService;
import org.springframework.security.crypto.bcrypt.BCryptPasswordEncoder;
import org.springframework.security.crypto.password.PasswordEncoder;
import org.springframework.security.web.SecurityFilterChain;
import org.springframework.security.web.authentication.HttpStatusEntryPoint;
import org.springframework.security.web.authentication.UsernamePasswordAuthenticationFilter;
import org.springframework.security.web.csrf.CookieCsrfTokenRepository;
import org.springframework.web.cors.CorsConfiguration;
import org.springframework.web.cors.CorsConfigurationSource;
import org.springframework.web.cors.UrlBasedCorsConfigurationSource;

@Configuration
@EnableWebSecurity
@EnableMethodSecurity
public class SecurityConfig {

    @Bean
    public static PasswordEncoder passwordEncoder() {
        return new BCryptPasswordEncoder();
    }

    @Bean
    public AuthenticationProvider authenticationProvider(UserDetailsService userDetailsService) {
        DaoAuthenticationProvider authProvider = new DaoAuthenticationProvider(userDetailsService);
        authProvider.setPasswordEncoder(passwordEncoder());
        return authProvider;
    }

    @Bean
    public AuthenticationManager authenticationManager(AuthenticationConfiguration configuration) throws Exception {
        return configuration.getAuthenticationManager();
    }

    @Bean
    public static CorsConfigurationSource corsConfigurationSource(
            @Value("${app.cors.allowed-origins:http://localhost:8080,http://localhost:3000,http://127.0.0.1:8080}") List<String> allowedOrigins
    ) {
        CorsConfiguration configuration = new CorsConfiguration();
        configuration.setAllowedOriginPatterns(allowedOrigins);
        configuration.setAllowedMethods(List.of("GET", "POST", "PUT", "PATCH", "DELETE", "OPTIONS"));
        configuration.setAllowedHeaders(List.of("Authorization", "Content-Type", "X-XSRF-TOKEN"));
        configuration.setAllowCredentials(true);

        UrlBasedCorsConfigurationSource source = new UrlBasedCorsConfigurationSource();
        source.registerCorsConfiguration("/**", configuration);
        return source;
    }

    @Configuration
    @Order(1)
    public static class StaticResourcesConfig {

        @Bean
        public SecurityFilterChain staticResourceFilterChain(HttpSecurity http) throws Exception {
            return http
                    .securityMatcher(
                            "/css/**",
                            "/js/**",
                            "/images/**",
                            "/webjars/**",
                            "/favicon.ico",
                            "/swagger-ui.html",
                            "/swagger-ui/**",
                            "/v3/api-docs",
                            "/v3/api-docs/**",
                            "/v3/api-docs.yaml"
                    )
                    .authorizeHttpRequests(auth -> auth.anyRequest().permitAll())
                    .sessionManagement(session -> session.sessionCreationPolicy(SessionCreationPolicy.STATELESS))
                    .csrf(AbstractHttpConfigurer::disable)
                    .build();
        }
    }

    @Configuration
    @Order(2)
    public static class ApiSecurityConfig {

        @Bean
        public SecurityFilterChain apiSecurityFilterChain(
                HttpSecurity http,
                JwtAuthenticationFilter jwtAuthenticationFilter,
                AuthenticationProvider authenticationProvider,
                CorsConfigurationSource corsConfigurationSource
        ) throws Exception {
            http
                    .securityMatcher("/api/**")
                    // A API trabalha sem sessao no servidor e autentica pelo JWT.
                    .csrf(AbstractHttpConfigurer::disable)
                    .cors(cors -> cors.configurationSource(corsConfigurationSource))
                    .authorizeHttpRequests(auth -> auth
                            .requestMatchers("/api/auth/**").permitAll()
                            .requestMatchers(HttpMethod.GET, "/api/public/**").permitAll()
                            .anyRequest().authenticated()
                    )
                    .sessionManagement(session -> session.sessionCreationPolicy(SessionCreationPolicy.STATELESS))
                    .exceptionHandling(exception -> exception
                            .authenticationEntryPoint(new HttpStatusEntryPoint(HttpStatus.UNAUTHORIZED))
                    )
                    .authenticationProvider(authenticationProvider)
                    .addFilterBefore(jwtAuthenticationFilter, UsernamePasswordAuthenticationFilter.class)
                    .formLogin(AbstractHttpConfigurer::disable)
                    .httpBasic(AbstractHttpConfigurer::disable);

            return http.build();
        }
    }

    @Configuration
    @Order(3)
    public static class WebSecurityConfig {

        @Bean
        public SecurityFilterChain webSecurityFilterChain(
                HttpSecurity http,
                AuthenticationProvider authenticationProvider,
                CorsConfigurationSource corsConfigurationSource
        ) throws Exception {
            http
                    .authorizeHttpRequests(auth -> auth
                            .dispatcherTypeMatchers(DispatcherType.FORWARD).permitAll()
                            .requestMatchers(
                                    "/",
                                    "/login",
                                    "/logout",
                                    "/error",
                                    "/public/**",
                                    "/swagger-ui.html",
                                    "/swagger-ui/**",
                                    "/v3/api-docs",
                                    "/v3/api-docs/**",
                                    "/v3/api-docs.yaml"
                            ).permitAll()
                            .anyRequest().authenticated()
                    )
                    .csrf(csrf -> csrf
                            .csrfTokenRepository(CookieCsrfTokenRepository.withHttpOnlyFalse())
                    )
                    .cors(cors -> cors.configurationSource(corsConfigurationSource))
                    .sessionManagement(session -> session.sessionCreationPolicy(SessionCreationPolicy.IF_REQUIRED))
                    .authenticationProvider(authenticationProvider)
                    .formLogin(form -> form
                            .loginPage("/login")
                            .loginProcessingUrl("/login")
                            .successHandler((request, response, authentication) -> {
                                var authorities = authentication.getAuthorities();
                                String targetUrl = "/";

                                if (authorities.stream().anyMatch(authority -> "ROLE_ADMINISTRADOR".equals(authority.getAuthority()))) {
                                    targetUrl = "/admin";
                                } else if (authorities.stream().anyMatch(authority -> "ROLE_COLABORADOR".equals(authority.getAuthority()))) {
                                    targetUrl = "/colaborador";
                                } else if (authorities.stream().anyMatch(authority -> "ROLE_MORADOR".equals(authority.getAuthority()))) {
                                    targetUrl = "/morador";
                                }

                                response.sendRedirect(request.getContextPath() + targetUrl);
                            })
                            .failureHandler((request, response, exception) ->
                                    response.sendRedirect(request.getContextPath() + "/login?error=true")
                            )
                            .permitAll()
                    )
                    .logout(logout -> logout
                            .logoutUrl("/logout")
                            .logoutSuccessUrl("/login?logout=true")
                            .deleteCookies("JSESSIONID", "XSRF-TOKEN")
                            .invalidateHttpSession(true)
                            .clearAuthentication(true)
                            .permitAll()
                    );

            return http.build();
        }
    }
}
