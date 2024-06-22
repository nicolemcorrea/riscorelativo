# Análise de Risco Relativo  
  
 Neste projeto, foram utilizadas as ferramentas BigQuery, Google Colab e Looker Studio e a aplicação de testes para a análise de risco relativo sobre uma base de dados de clientes de um banco fictício (Banco Super Caja).

<details>
  <summary><strong style="font-size: 16px;">Contexto</strong></summary>
  
Em um cenário financeiro, a diminuição das taxas de juros levou a um crescimento expressivo na procura por crédito no banco fictício "Super Caixa". No entanto, essa demanda em ascensão tem sobrecarregado a equipe de análise de crédito, que se encontra atualmente envolvida em um processo manual ineficiente e demorado para avaliar as diversas solicitações de empréstimo.
Para resolver essa questão, sugeriu-se a automatização do processo de análise por meio de técnicas avançadas de análise de dados, com o objetivo de aumentar a eficiência, a precisão e a rapidez na avaliação das solicitações de crédito. Além disso, o banco já possui uma métrica para identificar clientes com pagamentos atrasados, o que pode ser uma ferramenta útil a ser incorporada na classificação de risco do novo sistema automatizado.
</details>

<details>
  <summary><strong style="font-size: 16px;">Objetivo</strong></summary>
  
O objetivo deste projeto foi desenvolver um score de crédito utilizando uma análise de dados e a avaliação do risco relativo, capaz de classificar os clientes em diversas categorias de risco com base na probabilidade de inadimplência. Essa classificação dará subsidios para o banco tomar decisões mais precisas sobre a concessão de crédito, diminuindo o risco de não pagamento de empréstimos. Além disso, a inclusão da métrica existente de pagamentos atrasados aumenta a capacidade do modelo de identificar riscos.

Além disso, foram levantadas as seguintes hipóteses a serem respondidas:
Os mais jovens têm um maior risco de inadimplência;
As pessoas com maior quantidade de empréstimos ativos têm maior risco de serem maus pagadores;
As pessoas que atrasam seus pagamentos por mais de 90 dias têm maior risco de serem maus pagadores.
</details>

<details>
 <summary><strong style="font-size: 16px;">Insumos</strong></summary>

Foram utilizadas como fonte de dados as tabelas a seguir:

user_info: dados gerais dos usuários, como idade, sexo, salário e número de dependentes; 
default: dados dos clientes com uma variável (default_flag) para identificar usuários inadimplentes;
loans_detail: dados sobre o número de atrasos de pagamento de empréstimos em relação ao tempo, a taxa de endividamento e uso de linhas de crédito e relação ao seu limite; 
loans_outstanding: Dados sobre a quantidade e tipos de empréstimos por cliente.

</details>

<details>
 <summary><strong style="font-size: 16px;">Processo e Técnicas de Análise</strong></summary>

ETL (Extract, Transform, Load): através de consultas realizadas no ambiente BigQuery, foram realizadas as etapas de limpeza e transformação dos dados inconsistentes, o cálculo de quartis, a segmentação de clientes e a determinação do risco relativo. Também se realizou a conversão de variáveis categóricas em dummy e a classificação de variáveis dummy em um score para bons e maus pagadores;

Avaliação do Modelo de score creditício: avaliado utilizando o modelo de matriz de confusão 

Modelagem Estatística: foi realizada a regressão logística para verificar de forma preditiva o risco de inadimplência.
. 
Visualização de Dados: através de dashboards interativos no Looker Studio. 
</details>

<details>
  <summary><strong style="font-size: 16px;">Ferramentas e Tecnologias</strong></summary>
  
  - BigQuery
  - Google Colab
  - Looker Studio
  - Python
 
</details>


<details>
<summary><strong style="font-size: 16px;">Resultados e Conclusões</strong></summary>

  Com base na análise exploratória dos dados, chegou-se as seguintes conclusões:

- **_Hipótese 1_:** Os clientes mais jovens possuem um maior risco de ser maus pagadores. Assim, a hipótese inicial foi validada;


- **_Hipótese 2_:**   os clientes que possuem um maior número de créditos ativos tem um risco menor de ser maus pagadores, quando comparados com aqueles que possuem um menor número de créditos ativos. Assim, esta hipótese foi refutada.

- **_Hipótese 3_:** os clientes que atrasaram os pagamentos por mais de 90 dias possuem um risco maior de serem maus pagadores. Assim, a hipótese foi validada.

Além disso, a análise da matriz de confusão indicou uma alta sensibilidade do modelo na identificação dos clientes classificados como maus pagadores, porém a baixa precisão do modelo sugere uma tendência em superestimar o risco de inadimplência, classificando erroneamente possíveis bons pagadores.Porém, como o foco desta análise é na avaliação dos clientes potencialmente maus pagadores, o  modelo de classificação desenvolvido demonstrou ser eficaz na identificação de clientes com alto risco de inadimplência.

Já o resultado obtido para a análise da regressão logística evidencia que o modelo preditivo indica que os clientes que receberam um score de crédito acima de 4 tendem a ter um maior risco de serem inadimplentes do que aqueles clientes que receberam scores de crédito menores que 4.

</details>

<details>
<summary><strong style="font-size: 16px;">Recomendações</strong></summary>

Para aqueles clientes que receberam classificações de risco nas variáveis informadas, seria  interessante implementar um sistema de monitoramento contínuo para clientes que apresentaram atrasos significativos nos pagamentos, possibilitando a detecção precoce de sinais de dificuldades financeiras e ação preventiva.

Também poderia ser desenvolvido programas de educação financeira direcionados aos clientes mais jovens e aqueles com histórico de atrasos de pagamento, para ajudar a melhorar a gestão financeira pessoal e reduzir o risco de inadimplência.

Além disso, sugere-se realizar atualizações regulares na classificação de risco relativo, incorporando novos dados e ajustando critérios conforme necessário para melhorar a precisão das previsões.

Já para aqueles clientes que foram classificadas como bons pagadores, a instituição financeira poderia oferecer condições de crédito mais atrativas, como taxas de juros mais baixas ou prazos de pagamento mais flexíveis, para clientes que demonstram bom histórico de pagamento e menor número de empréstimos ativos, também considerar aumentos graduais nos limites de crédito para clientes com bom histórico de pagamento e baixo risco identificado pelo modelo de análise de risco, bem como investir em benefícios e incentivos, 
como descontos em taxas de crédito ou ofertas especiais em novos produtos financeiros.


Além disso, indica-se ao banco manter um processo contínuo de desenvolvimento e refinamento do modelo preditivo e de validação dos resultados, para aprimorar e ajustar as previsões, aumentando assim a confiança no modelo nas previsões de inadimplência dos clientes.

Por fim, assegurar a transparência dos critérios de concessão de crédito aos clientes, fortalecendo a confiança e facilitando a compreensão das expectativas do banco quanto ao pagamento.
  
</details>

