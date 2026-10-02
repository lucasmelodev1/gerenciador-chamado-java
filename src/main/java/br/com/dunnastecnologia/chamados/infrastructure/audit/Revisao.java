package br.com.dunnastecnologia.chamados.infrastructure.audit;

import br.com.dunnastecnologia.chamados.domain.validation.ValidationLimits;
import jakarta.persistence.Column;
import jakarta.persistence.Entity;
import jakarta.persistence.GeneratedValue;
import jakarta.persistence.Id;
import jakarta.persistence.Table;
import lombok.Getter;
import lombok.Setter;
import org.hibernate.envers.RevisionEntity;
import org.hibernate.envers.RevisionNumber;
import org.hibernate.envers.RevisionTimestamp;

import java.util.UUID;

/**
 * Revisao de auditoria do Envers. Guarda o instante (epoch) e um snapshot do ator que executou a
 * alteracao, para que o historico continue legivel mesmo se o usuario for alterado ou removido.
 */
@Entity
@Table(name = "revinfo")
@RevisionEntity(RevisaoListener.class)
@Getter
@Setter
public class Revisao {

    @Id
    @GeneratedValue
    @RevisionNumber
    private int id;

    @RevisionTimestamp
    private long timestamp;

    @Column(name = "usuario_id")
    private UUID usuarioId;

    @Column(name = "usuario_email", length = ValidationLimits.USUARIO_EMAIL_MAX_LENGTH)
    private String usuarioEmail;

    @Column(name = "usuario_role", length = ValidationLimits.REVISAO_USUARIO_ROLE_MAX_LENGTH)
    private String usuarioRole;

}
