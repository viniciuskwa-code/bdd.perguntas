-- 1: Maior consumo total de energia (kWh) e maior consumo por colaborador:

SELECT 
    f.nome AS filial,
    SUM(rmf.energia_consumida_em_kWh) AS consumo_total_kwh,
    COUNT(DISTINCT func.cpf) AS total_colaboradores,
    ROUND(CAST(SUM(rmf.energia_consumida_em_kWh) / NULLIF(COUNT(DISTINCT func.cpf), 0) AS NUMERIC), 2) AS consumo_por_colaborador
FROM filial f
JOIN registro_mensal_filial rmf ON f.cnpj_filial = rmf.cnpj_filial
LEFT JOIN funcionario func ON f.cnpj_filial = func.cnpj_filial
    AND func.data_contratacao <= '2025-12-31'
    AND (func.data_demissao IS NULL OR func.data_demissao >= '2021-01-01')
WHERE EXTRACT(YEAR FROM rmf.data_registro) BETWEEN 2021 AND 2025
GROUP BY f.cnpj_filial, f.nome
ORDER BY consumo_total_kwh DESC;

-- 2: Maior lucro (receita - custo) e maior margem de lucro (lucro / receita):

SELECT 
    f.nome AS filial,
    SUM(rmf.receita_em_reais - rmf.custo_operacional) AS lucro_total,
    ROUND(
        CAST((SUM(rmf.receita_em_reais - rmf.custo_operacional) / NULLIF(SUM(rmf.receita_em_reais), 0)) * 100 AS NUMERIC), 
        2
    ) AS margem_lucro_percentual
FROM filial f
JOIN registro_mensal_filial rmf ON f.cnpj_filial = rmf.cnpj_filial
WHERE EXTRACT(YEAR FROM rmf.data_registro) BETWEEN 2021 AND 2025
GROUP BY f.cnpj_filial, f.nome
ORDER BY lucro_total DESC;

-- 3 Total de contratações e proporção em relação aos colaboradores:

SELECT 
    f.nome AS filial,
    COUNT(CASE WHEN EXTRACT(YEAR FROM func.data_contratacao) BETWEEN 2021 AND 2025 THEN 1 END) AS total_contratados,
    COUNT(func.cpf) AS total_colaboradores_periodo,
    ROUND(
        CAST((COUNT(CASE WHEN EXTRACT(YEAR FROM func.data_contratacao) BETWEEN 2021 AND 2025 THEN 1 END) * 100.0) / 
        NULLIF(COUNT(func.cpf), 0) AS NUMERIC), 
        2
    ) AS proporcao_contratacao_percentual
FROM filial f
JOIN funcionario func ON f.cnpj_filial = func.cnpj_filial
WHERE func.data_contratacao <= '2025-12-31'
  AND (func.data_demissao IS NULL OR func.data_demissao >= '2021-01-01')
GROUP BY f.cnpj_filial, f.nome
ORDER BY total_contratados DESC;

-- 4 Resíduos reciclados (kg) e taxa de reciclagem:

SELECT 
    f.nome AS filial,
    SUM(rmf.residuos_reciclado_em_kg) AS total_reciclado_kg,
    ROUND(
        CAST((SUM(rmf.residuos_reciclado_em_kg) / NULLIF(SUM(rmf.residuos_gerados_em_kg), 0)) * 100 AS NUMERIC), 
        2
    ) AS taxa_reciclagem_percentual
FROM filial f
JOIN registro_mensal_filial rmf ON f.cnpj_filial = rmf.cnpj_filial
WHERE EXTRACT(YEAR FROM rmf.data_registro) BETWEEN 2021 AND 2025
GROUP BY f.cnpj_filial, f.nome
ORDER BY total_reciclado_kg DESC;

-- 5 Total de mulheres e proporção de mulheres no quadro

WITH anos_serie AS (
    SELECT generate_series(2021, 2025) AS ano
),
quadro_anual AS (
    SELECT 
        f.cnpj_filial,
        f.nome AS filial,
        a.ano,
        COUNT(DISTINCT CASE WHEN func.sexo ILIKE 'Feminino%' OR func.sexo ILIKE 'F' THEN func.cpf END) AS qtd_mulheres,
        COUNT(DISTINCT func.cpf) AS total_quadro
    FROM filial f
    CROSS JOIN anos_serie a
    LEFT JOIN funcionario func ON f.cnpj_filial = func.cnpj_filial
        AND EXTRACT(YEAR FROM func.data_contratacao) <= a.ano
        AND (func.data_demissao IS NULL OR EXTRACT(YEAR FROM func.data_demissao) >= a.ano)
    GROUP BY f.cnpj_filial, f.nome, a.ano
)
SELECT 
    filial,
    ROUND(CAST(AVG(qtd_mulheres) AS NUMERIC), 2) AS media_mulheres_empregadas,
    ROUND(CAST(AVG((qtd_mulheres * 100.0) / NULLIF(total_quadro, 0)) AS NUMERIC), 2) AS proporcao_media_mulheres_percentual
FROM quadro_anual
GROUP BY cnpj_filial, filial
ORDER BY media_mulheres_empregadas DESC;



-- Pergunta 6: Maior acúmulo de horas de treinamento e mais horas por colaborador:


SELECT 
    f.nome AS filial,
    ROUND(CAST(SUM(EXTRACT(EPOCH FROM rmf.horas_treinamento)) / 3600 AS NUMERIC), 2) AS total_horas_treinamento,
    COUNT(DISTINCT func.cpf) AS total_colaboradores,
    ROUND(
        CAST((SUM(EXTRACT(EPOCH FROM rmf.horas_treinamento)) / 3600) / NULLIF(COUNT(DISTINCT func.cpf), 0) AS NUMERIC), 
        2
    ) AS horas_por_colaborador
FROM filial f
JOIN funcionario func ON f.cnpj_filial = func.cnpj_filial
JOIN registro_mensal_funcionario rmf ON func.cpf = rmf.cpf_funcionario
WHERE EXTRACT(YEAR FROM rmf.data_registro) BETWEEN 2021 AND 2025
GROUP BY f.cnpj_filial, f.nome
ORDER BY total_horas_treinamento DESC;


-- Pergunta 7: Maior emissão total de gases de efeito estufa (tCO2e) e por colaborador:

SELECT 
    f.nome AS filial,
    ROUND(CAST(SUM(rmf.emissoes_em_tco2e) AS NUMERIC), 2) AS total_emissoes_tco2e,
    COUNT(DISTINCT func.cpf) AS total_colaboradores,
    ROUND(
        CAST(SUM(rmf.emissoes_em_tco2e) / NULLIF(COUNT(DISTINCT func.cpf), 0) AS NUMERIC), 
        2
    ) AS emissoes_por_colaborador
FROM filial f
JOIN registro_mensal_filial rmf ON f.cnpj_filial = rmf.cnpj_filial
LEFT JOIN funcionario func ON f.cnpj_filial = func.cnpj_filial
    AND func.data_contratacao <= '2025-12-31'
    AND (func.data_demissao IS NULL OR func.data_demissao >= '2021-01-01')
WHERE EXTRACT(YEAR FROM rmf.data_registro) BETWEEN 2021 AND 2025
GROUP BY f.cnpj_filial, f.nome
ORDER BY total_emissoes_tco2e DESC;