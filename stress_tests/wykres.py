import json
import pandas as pd
import seaborn as sns
import matplotlib.pyplot as plt
from pathlib import Path
import matplotlib

matplotlib.use("Agg")
sns.set(style="whitegrid")


def load_metrics(filename):
    if not Path(filename).exists():
        print(f"Nie znaleziono pliku {filename}")
        return None

    with open(filename, "r") as f:
        return json.load(f)


def plot_separated_violin_and_swarm(metrics):
    data = []
    for latency in metrics["latencies"]["write"]:
        data.append({"type": "write", "latency": latency})
    for latency in metrics["latencies"]["read"]:
        data.append({"type": "read", "latency": latency})
    for latency in metrics["latencies"]["write_first"]:
        data.append({"type": "write", "latency": latency})
    for latency in metrics["latencies"]["read_first"]:
        data.append({"type": "read", "latency": latency})
    df = pd.DataFrame(data)

    # Podział na dane typowe i outliery (> 0.2s)
    df_normal = df[df["latency"] <= 0.12]
    df_outliers = df[df["latency"] > 0.12]

    outliers_count = df_outliers.groupby("type").size().to_dict()

    fig, axes = plt.subplots(1, 2, figsize=(9, 5), sharey=False)

    # WYKRES 1 – Dane typowe
    sns.violinplot(x="type", y="latency", data=df_normal, inner=None, palette="pastel", ax=axes[0], order=["write", "read"])
    sns.swarmplot(
        x="type",
        y="latency",
        data=df_normal.sample(n=min(len(df_normal), 1000)),
        color=".25",
        size=2,
        ax=axes[0],
        order=["write", "read"]
    )
    # axes[0].set_ylim(0, df_normal["latency"].quantile(0.98) * 1.1)
    axes[0].set_title("Wartości typowe (≤ 0,1s)")
    axes[0].set_ylabel("Czas (s)")
    axes[0].set_xlabel("Typ operacji")

    # WYKRES 2 – Outliery
    sns.violinplot(x="type", y="latency", data=df_outliers, inner="box", palette="Set2", ax=axes[1], order=["write", "read"])
    sns.swarmplot(
        x="type",
        y="latency",
        data=df_outliers,
        color=".3",
        size=3,
        ax=axes[1],
        order=["write", "read"]
    )
    axes[1].set_title("Wartości odstające (> 0,1s)")
    axes[1].set_ylabel("Czas (s)")
    axes[1].set_xlabel("Typ operacji")

    # Adnotacja z liczbą outlierów
    for op_type in ["write", "read"]:
        count = outliers_count.get(op_type, 0)
        axes[1].text(
            x=["write", "read"].index(op_type),
            y=df_outliers["latency"].max() * 0.95,
            s=f"{count} wartości odstających",
            ha="center",
            fontsize=10,
            color="red"
        )

    plt.suptitle("Czasy wykonywania operacji na bazie Firestore", fontsize=14)
    plt.tight_layout(rect=[0, 0, 1, 0.96])
    plt.savefig("latency_distribution_separated.png")
    print("Wykres zapisany jako latency_distribution_separated.png")


if __name__ == "__main__":
    metrics = load_metrics("metrics.json")
    if metrics:
        plot_separated_violin_and_swarm(metrics)
