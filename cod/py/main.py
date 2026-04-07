import os
import pandas as pd
import numpy as np
import xgboost as xgb
from sklearn.preprocessing import LabelEncoder, StandardScaler
from sklearn.metrics import log_loss, accuracy_score
from scipy.stats import ttest_1samp
import warnings
import matplotlib.pyplot as plt
import seaborn as sns
from matplotlib.ticker import MultipleLocator

# --- Function to compute bootstrapped confidence intervals ---
def bootstrap_confidence_interval(data, n_bootstraps=1000, ci=95):
    boot_means = []
    n = len(data)
    for _ in range(n_bootstraps):
        sample = np.random.choice(data, size=n, replace=True)
        boot_means.append(np.mean(sample))
    lower = np.percentile(boot_means, (100 - ci) / 2)
    upper = np.percentile(boot_means, 100 - (100 - ci) / 2)
    return lower, upper

# --- Function to compute RPS ---
def compute_rps(probs, true_class_idx, n_classes=5):
    if probs.ndim > 1:
        probs = probs.flatten()
    cum_probs = np.cumsum(probs)
    true_cdf = np.zeros(n_classes)
    true_cdf[true_class_idx:] = 1
    return np.sum((cum_probs - true_cdf) ** 2)

# Suppress warnings
warnings.filterwarnings('ignore', category=FutureWarning)
warnings.filterwarnings('ignore', category=RuntimeWarning)

# --- Paths and data ---
data_dir = "/Users/r"  # Adjust path
TARGET_VARIABLE = input("Enter the target variable: ")

try:
    all_files = os.listdir(data_dir)
    train_files = sorted([os.path.join(data_dir, f) for f in all_files if f.startswith("trn_")])
    test_files = sorted([os.path.join(data_dir, f) for f in all_files if f.startswith("tst_")])
    if not train_files or not test_files:
        raise FileNotFoundError("No training or testing files found.")
except FileNotFoundError:
    print(f"Error: Directory or files not found at path '{data_dir}'. Please adjust the path.")
    exit()

sample_train_df = pd.read_csv(train_files[0])

feature_names = ['s1sc-cc', 's1sc-dm', 's1cc-dm',
                 's2sc-cc', 's2sc-dm', 's2cc-dm',
                 's3sc-cc', 's3sc-dm', 's3cc-dm',
                 's4sc-cc', 's4sc-dm', 's4cc-dm']

ordinal_order = ["abs", "min", "mild", "mod", "sev"]
n_classes = len(ordinal_order)
label_encoder = LabelEncoder().fit(ordinal_order)

# --- Dictionaries for RPS drops, p-values, and metrics ---
rps_drops = {feature: [] for feature in feature_names}
p_values_per_fold = {feature: [] for feature in feature_names}
train_logloss_list, train_acc_list = [], []
val_logloss_list, val_acc_list = [], []

# --- LOOCV + LOFO loop ---
for fold in range(len(train_files)):
    print(f"Processing Fold {fold + 1}/{len(train_files)}...")
    train_df = pd.read_csv(train_files[fold])
    test_df = pd.read_csv(test_files[fold])

    y_train = label_encoder.transform(train_df[TARGET_VARIABLE])
    y_test_idx = label_encoder.transform(test_df[TARGET_VARIABLE])[0]

    X_train_all = train_df[feature_names].select_dtypes(include=np.number)
    X_test_all = test_df[feature_names].select_dtypes(include=np.number)

    numeric_feature_names = X_train_all.columns.tolist()
    scaler = StandardScaler()
    X_train_all_scaled = scaler.fit_transform(X_train_all)
    X_test_all_scaled = scaler.transform(X_test_all)

    try:
        # --- Base model ---
        base_model = xgb.XGBClassifier(
            objective='multi:softprob',
            n_estimators=30,  # Increased from 50
            max_depth=2,
            learning_rate=0.04,  # Increased from 0.01
            subsample=0.6,
            colsample_bytree=0.8,
            min_child_weight=5,  # Lowered from 4
            reg_alpha=1,
            reg_lambda=10,  # Lowered from 10
            random_state=42

        )
        base_model.fit(X_train_all_scaled, y_train)

        # Training scores
        train_probs = base_model.predict_proba(X_train_all_scaled)
        train_logloss = log_loss(y_train, train_probs, labels=range(n_classes))
        train_acc = accuracy_score(y_train, np.argmax(train_probs, axis=1))
        train_logloss_list.append(train_logloss)
        train_acc_list.append(train_acc)

        # Validation scores
        val_probs = base_model.predict_proba(X_test_all_scaled)[0].reshape(1, -1)
        val_true = np.array([y_test_idx])
        val_logloss = log_loss(val_true, val_probs, labels=range(n_classes))
        val_acc = accuracy_score(val_true, np.argmax(val_probs, axis=1))
        val_logloss_list.append(val_logloss)
        val_acc_list.append(val_acc)

        # Base RPS
        base_rps = compute_rps(val_probs.flatten(), y_test_idx, n_classes=n_classes)

    except Exception as e:
        print(f"--> FATAL: Base model failed in fold {fold}. Error: {e}. Skipping fold.")
        for feature in numeric_feature_names:
            rps_drops.setdefault(feature, []).append(np.nan)
        continue

    # --- LOFO for each feature ---
    for feature in numeric_feature_names:
        lofo_features = [f for f in numeric_feature_names if f != feature]
        X_train_lofo = train_df[lofo_features].select_dtypes(include=np.number)
        X_test_lofo = test_df[lofo_features].select_dtypes(include=np.number)

        if X_train_lofo.shape[1] == 0:
            rps_drops[feature].append(np.nan)
            continue

        scaler_lofo = StandardScaler()
        X_train_lofo_scaled = scaler_lofo.fit_transform(X_train_lofo)
        X_test_lofo_scaled = scaler_lofo.transform(X_test_lofo)

        try:
            lofo_model = xgb.XGBClassifier(
                objective='multi:softprob',
                n_estimators=30,  # Increased from 50
                max_depth=2,
                learning_rate=0.04,  # Increased from 0.01
                subsample=0.6,
                colsample_bytree=0.8,
                min_child_weight=5,  # Lowered from 4
                reg_alpha=1,
                reg_lambda=10,  # Lowered from 10
                random_state=42
            )
            lofo_model.fit(X_train_lofo_scaled, y_train)

            lofo_probs = lofo_model.predict_proba(X_test_lofo_scaled)[0]
            lofo_rps = compute_rps(lofo_probs, y_test_idx, n_classes=n_classes)

            rps_drops[feature].append(lofo_rps - base_rps)

            # Per-fold p-value heuristic
            p_values_per_fold[feature].append(1 if (lofo_rps - base_rps) > 0 else 0)

        except Exception as e:
            print(f"--> Warning: LOFO model failed for feature '{feature}' in fold {fold}. Error: {e}")
            rps_drops[feature].append(np.nan)

# --- Summarize LOFO results ---
results = []
for feature in rps_drops.keys():
    drops = np.array(rps_drops[feature])
    drops = drops[~np.isnan(drops)]
    if len(drops) > 1:
        mean_drop = np.mean(drops)
        t_stat, p_val_two_sided = ttest_1samp(drops, 0.0, alternative='two-sided')
        p_val_one_sided = p_val_two_sided / 2 if t_stat > 0 else 1 - (p_val_two_sided / 2)
        stability = np.mean(drops > 0) * 100
        lower_ci, upper_ci = bootstrap_confidence_interval(drops)
        sig_count = np.sum(p_values_per_fold[feature])
        results.append([feature, mean_drop, lower_ci, upper_ci, t_stat, p_val_one_sided, stability, sig_count])
    else:
        results.append([feature, np.nan, np.nan, np.nan, np.nan, np.nan, np.nan, np.nan])

results_df = pd.DataFrame(results, columns=[
    "Feature", "RPS Drop Mean", "lower_ci", "upper_ci", "t-statistic",
    "p-value (greater)", "Fold Stability (%)", "Significant Count (<0.05)"
]).sort_values("RPS Drop Mean", ascending=False).reset_index(drop=True)

# --- Save results ---
results_df.to_csv("lofo_rps_results_xgboost_fold_stability.csv", index=False)
pd.DataFrame(rps_drops).to_csv("rps_drops_per_fold.csv", index=False)
pd.DataFrame(p_values_per_fold).to_csv("p_values_per_fold.csv", index=False)

# --- Save training & validation scores ---
pd.DataFrame({
    "train_logloss": train_logloss_list,
    "train_accuracy": train_acc_list,
    "val_logloss": val_logloss_list,
    "val_accuracy": val_acc_list
}).to_csv("train_val_scores.csv", index=False)

# --- Plot RPS drops ---
rps_drop_plot_data = []
for feature, drops in rps_drops.items():
    for drop in drops:
        if not np.isnan(drop):
            rps_drop_plot_data.append({"Feature": feature, "RPS Drop": drop})

plot_df = pd.DataFrame(rps_drop_plot_data)
plt.figure(figsize=(14, 8))
sns.boxplot(data=plot_df, x="Feature", y="RPS Drop")
plt.axhline(0, color='red', linestyle='--', label='Zero Effect Line')
plt.xticks(rotation=45, ha="right")
plt.gca().yaxis.set_major_locator(MultipleLocator(0.1))
plt.title("Distribution of RPS Drops Per Feature (LOOCV-LOFO)")
plt.tight_layout()
plt.show()

print("LOFO and training/validation scores computation completed successfully.")