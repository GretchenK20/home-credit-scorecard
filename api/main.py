
import pickle
import numpy as np
import pandas as pd
from fastapi import FastAPI
from pydantic import BaseModel
from typing import Optional

app = FastAPI(title="Home Credit Scorecard API", version="1.0.0")

with open("models/champion_lr.pkl", "rb") as f:
    model = pickle.load(f)
with open("models/binning_process.pkl", "rb") as f:
    binning_process = pickle.load(f)

PDO = 20
BASE_SCORE = 600
BASE_ODDS = 50
FACTOR = PDO / np.log(2)
OFFSET = BASE_SCORE - FACTOR * np.log(BASE_ODDS)
CUTOFF_SCORE = 554

REASON_CODE_MAP = {
    "EXT_SOURCE_WEIGHTED":     "Insufficient external credit score",
    "EXT_SOURCE_MEAN":         "Insufficient external credit score",
    "EXT_SOURCE_3":            "Insufficient external credit score",
    "EXT_SOURCE_2":            "Insufficient external credit score",
    "EXT_SOURCE_1":            "Insufficient external credit score",
    "YEARS_EMPLOYED":          "Insufficient length of employment",
    "DAYS_EMPLOYED":           "Insufficient length of employment",
    "DAYS_EMPLOYED_ANOM":      "Employment status is non-standard",
    "CREDIT_INCOME_RATIO":     "Loan amount is high relative to income",
    "ANNUITY_INCOME_RATIO":    "Monthly payment is high relative to income",
    "CREDIT_TERM":             "Loan term does not meet guidelines",
    "BUREAU_MEAN_DAYS_CREDIT": "Limited credit bureau history",
    "BUREAU_ACTIVE_COUNT":     "Too many active credit obligations",
    "PREV_REFUSED_COUNT":      "Prior credit applications were declined",
    "PREV_APPROVAL_RATE":      "Low prior credit approval rate",
    "INST_LATE_RATE":          "History of late payments on prior loans",
    "INST_MEAN_PAYMENT_DIFF":  "History of underpayment on prior loans",
    "CC_MEAN_BALANCE":         "High revolving credit balances",
    "POS_SERIOUS_DPD_RATE":    "History of serious delinquency",
    "AMT_GOODS_PRICE":         "Loan amount exceeds guidelines",
}

PROTECTED_FEATURES = ["CODE_GENDER", "DAYS_BIRTH", "AGE_YEARS"]

class ApplicantFeatures(BaseModel):
    EXT_SOURCE_1:          Optional[float] = None
    EXT_SOURCE_2:          Optional[float] = None
    EXT_SOURCE_3:          Optional[float] = None
    YEARS_EMPLOYED:        Optional[float] = None
    DAYS_EMPLOYED_ANOM:    Optional[int]   = 0
    AGE_YEARS:             Optional[float] = None
    CREDIT_INCOME_RATIO:   Optional[float] = None
    ANNUITY_INCOME_RATIO:  Optional[float] = None
    CREDIT_TERM:           Optional[float] = None
    BUREAU_MEAN_DAYS_CREDIT: Optional[float] = None
    BUREAU_ACTIVE_COUNT:   Optional[float] = None
    PREV_REFUSED_COUNT:    Optional[float] = None
    PREV_APPROVAL_RATE:    Optional[float] = None
    INST_LATE_RATE:        Optional[float] = None
    INST_MEAN_PAYMENT_DIFF: Optional[float] = None
    CC_MEAN_BALANCE:       Optional[float] = None
    POS_SERIOUS_DPD_RATE:  Optional[float] = None

def scale_score(proba):
    odds = (1 - proba) / (proba + 1e-10)
    score = OFFSET + FACTOR * np.log(odds)
    return int(np.clip(score, 300, 850))

def get_reason_codes(woe_row, feature_names, coef, top_n=4):
    contributions = woe_row * coef
    contrib = pd.Series(contributions, index=feature_names)
    contrib = contrib.drop(
        labels=[f for f in PROTECTED_FEATURES if f in contrib.index],
        errors="ignore"
    )
    top = contrib.nlargest(top_n + 4)
    reasons = []
    for feat in top.index:
        reason = REASON_CODE_MAP.get(feat)
        if reason and reason not in reasons:
            reasons.append(reason)
        if len(reasons) == top_n:
            break
    return reasons

@app.get("/health")
def health():
    return {"status": "ok", "model": "champion_lr", "version": "1.0.0"}

@app.post("/score")
def score_applicant(applicant: ApplicantFeatures):
    input_df = pd.DataFrame([applicant.model_dump()])
    all_features = binning_process.variable_names
    for col in all_features:
        if col not in input_df.columns:
            input_df[col] = np.nan
    input_df = input_df[all_features]
    woe_array = binning_process.transform(input_df, metric="woe")
    proba = model.predict_proba(woe_array)[0][1]
    credit_score = scale_score(proba)
    decision = "APPROVED" if credit_score >= CUTOFF_SCORE else "DECLINED"
    selected = binning_process.get_support(names=True)
    coef = model.coef_[0]
    woe_row = woe_array.values[0] if hasattr(woe_array, "values") else woe_array[0]
    reasons = get_reason_codes(woe_row, list(selected), coef) if decision == "DECLINED" else []
    return {
        "credit_score":       credit_score,
        "decision":           decision,
        "probability_default": round(float(proba), 4),
        "cutoff_score":       CUTOFF_SCORE,
        "adverse_action_reasons": reasons
    }

@app.get("/model-info")
def model_info():
    return {
        "champion_model":    "Logistic Regression",
        "challenger_model":  "XGBoost",
        "champion_auc":      0.7651,
        "challenger_auc":    0.7758,
        "champion_gini":     "53.02%",
        "champion_ks":       "40.10%",
        "decision":          "Champion selected — explainability required for ECOA compliance",
        "pdo":               20,
        "base_score":        600,
        "cutoff_score":      CUTOFF_SCORE,
        "features_used":     93,
        "training_samples":  246008,
        "bad_rate":          "8.07%"
    }
