package br.com.dunnastecnologia.chamados.domain.model;

import br.com.dunnastecnologia.chamados.domain.validation.ValidationLimits;
import jakarta.persistence.Column;
import jakarta.persistence.Convert;
import jakarta.persistence.Entity;
import jakarta.persistence.GeneratedValue;
import jakarta.persistence.Id;
import jakarta.persistence.Table;
import lombok.Getter;
import lombok.Setter;
import org.hibernate.annotations.CreationTimestamp;
import org.hibernate.annotations.SoftDelete;
import org.hibernate.annotations.SoftDeleteType;
import org.hibernate.annotations.UpdateTimestamp;

import java.time.LocalDateTime;
import java.util.UUID;

@Entity
@Table(name = "areas")
@SoftDelete(strategy = SoftDeleteType.TIMESTAMP, columnName = "deleted_at")
@Getter
@Setter
public class Area {

    @Id
    @GeneratedValue
    private UUID id;

    @Column(nullable = false, length = ValidationLimits.AREA_NOME_MAX_LENGTH)
    private String nome;

    @Convert(converter = StatusAreaConverter.class)
    @Column(nullable = false, length = ValidationLimits.AREA_STATUS_MAX_LENGTH)
    private StatusArea status;

    @CreationTimestamp
    @Column(nullable = false, updatable = false)
    private LocalDateTime createdAt;

    @UpdateTimestamp
    @Column(nullable = false)
    private LocalDateTime updatedAt;

}
