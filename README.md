# Home Credit Default Risk — Production Credit Scorecard

A production-grade probability of default (PD) scorecard built on 307,511 loan applications, mirroring the end-to-end modeling workflow at consumer fintech lenders. Built to demonstrate credit risk modeling, feature engineering at scale, and compliant model deployment.

## Dashboard
[📊 Scorecard Validation Dashboard (Tableau Public)](https://public.tableau.com/app/profile/gretchen.kolthoff/viz/HomeCreditDefaultRiskScorecardValidationDashboard/Dashboard1)

Interactive visualization of model validation results — feature importance by IV, bad rate by EXT_SOURCE decile, payment behavior risk, bureau segment risk, and employment risk stratification.
---

## Results

| Metric | Champion (Logistic Regression) | Challenger (XGBoost) |
|---|---|---|
| AUC | 0.7651 | 0.7758 |
| Gini | 53.02% | 55.17% |
| KS | 40.10% | 41.69% |

**Champion selected:** Logistic regression — the 2.14% Gini gap does not justify replacing an explainable scorecard with a black-box model in a regulated lending environment requiring ECOA adverse action compliance.

---

## Live Demo

<!-- PLACEHOLDER: Streamlit app link -->
<!-- PLACEHOLDER: Tableau Public dashboard -->

**API (local):**
```bash
uvicorn api.main:app --reload --port 8001
```

```bash
curl -X POST http://localhost:8001/score \
  -H "Content-Type: application/json" \
  -d '{"EXT_SOURCE_1": 0.5, "EXT_SOURCE_2": 0.6, "EXT_SOURCE_3": 0.7,
       "YEARS_EMPLOYED": 5.0, "CREDIT_INCOME_RATIO": 3.2,
       "ANNUITY_INCOME_RATIO": 0.15, "CREDIT_TERM": 24.0}'
```

```json
{
  "credit_score": 576,
  "decision": "APPROVED",
  "probability_default": 0.0425,
  "cutoff_score": 554,
  "adverse_action_reasons": []
}
```

---

## Project Structurehome-credit-scorecard/
 notebooks/
│  01_eda.ipynb # Exploratory data analysis
│  02_feature_engineering.ipynb # Feature engineering across 6 tables
│ 03_scorecard_model.ipynb # WOE/IV, modeling, evaluation, monitoring
api/
│  main.py # FastAPI scoring endpoint
 src/ # Utility scripts
---

## The Problem

Home Credit serves borrowers underserved by traditional financial institutions. The goal is to predict which applicants will default on a loan — without using protected class attributes — so the lender can price risk appropriately and extend credit responsibly.

- **307,511** loan applications
- **8.07% bad rate** — 1 in 12 borrowers defaults
- **11.4:1 class imbalance** between good and bad borrowers

---

## Approach

### 1. Exploratory Data Analysis
- Identified DAYS_EMPLOYED anomaly: 55,374 records (18%) had a placeholder value indicating pensioners, who default at 5.40% vs 8.66% for employed borrowers — preserved as a binary risk feature rather than imputed away
- Excluded CODE_GENDER despite predictive power — ECOA fair lending compliance documented
- EXT_SOURCE decile analysis showed near-perfectly monotonic bad rate: 20% to 3.2%

### 2. Feature Engineering — 27M+ Rows Across 6 Tables

| Source | Features | Key Signal |
|---|---|---|
| Application (main) | 131 | EXT_SOURCE scores, employment, income ratios |
| Bureau | 17 | Credit history length, active obligations, mortgage flag |
| Previous Applications | 14 | Refusal count, approval rate |
| Installments | 10 | Late payment rate, payment shortfall |
| Credit Card | 8 | Mean balance, months active |
| POS Cash | 9 | Serious delinquency rate, loan count |

All tables joined via left join on SK_ID_CURR — preserves all 307,511 training rows, with NaN after join treated as no history in WOE binning.

### 3. WOE/IV Feature Selection
- 189 features evaluated via optbinning
- 93 features selected (IV >= 0.02)
- 96 features dropped
- EXT_SOURCE_WEIGHTED IV = 0.6292 (strongest predictor)

### 4. Champion/Challenger Modeling
- **Champion:** Logistic regression on WOE-transformed features — fully explainable, zero overfitting (train/test AUC gap: 0.0002)
- **Challenger:** XGBoost with early stopping at tree 487 — 2.14% Gini lift at the cost of explainability
- **Scorecard scaling:** PDO=20, base score=600 — every 20 points doubles the odds of being a good borrower

### 5. Score Bands

| Score Band | Applicants | Bad Rate |
|---|---|---|
| 300-499 | 712 | 49.02% |
| 500-549 | 14,688 | 18.04% |
| 550-599 | 37,062 | 4.94% |
| 600-649 | 9,001 | 1.50% |
| 650+ | 40 | 0.00% |

### 6. ECOA Adverse Action Reason Codes
- Top 4 decline factors generated per applicant
- Protected class features (gender, age) explicitly excluded from reason code generation
- 18,001 declined applicants (29.3% of test set) in production cutoff simulation

### 7. PSI Model Monitoring
- Score PSI: 0.0002 (stable)
- All key features stable across train/test split
- Interactive drift report generated via Evidently

### 8. FastAPI Deployment
- /health — health check
- /score — real-time applicant scoring
- /model-info — champion/challenger summary for credit committee

---

## Tech Stack

Python · pandas · numpy · scikit-learn · optbinning · XGBoost · FastAPI · Evidently · matplotlib · Jupyter

---

## Key Modeling Decisions

**Why logistic regression over XGBoost as champion?**
ECOA requires lenders to provide specific, plain-language reasons for adverse action. Logistic regression coefficients map directly to feature contributions, making reason code generation straightforward and auditable. XGBoost's 2.14% Gini lift does not justify the compliance overhead of SHAP-based reason codes in a production lending environment.

**Why left joins throughout feature engineering?**
Preserving all 307,511 training rows ensures the model learns from thin-file applicants rather than dropping them. In consumer lending, thin-file applicants are a core segment — not an edge case.

**Why exclude CODE_GENDER despite predictive power?**
ECOA prohibits using sex as a factor in credit decisions. Even where a feature is predictive, using it exposes the lender to fair lending liability. Documented exclusion is preferable to post-hoc disparate impact analysis.

---

## Setup

```bash
git clone https://github.com/GretchenK20/home-credit-scorecard
cd home-credit-scorecard
python -m venv venv
source venv/bin/activate
pip install -r requirements.txt
```

Data source: Kaggle — Home Credit Default Risk
https://www.kaggle.com/c/home-credit-default-risk/data

---

## About

Built by Gretchen Kolthoff — MS Data Analytics candidate, B.S. Mathematics (SLU).
Targeting analytics engineering and data science roles in fintech and consumer lending.

LinkedIn: https://www.linkedin.com/in/gretchen-kolthoff/
GitHub: https://github.com/GretchenK20
