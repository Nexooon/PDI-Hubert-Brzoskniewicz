import asyncio
import random
import time
from statistics import mean
from collections import defaultdict
import matplotlib
import json

import firebase_admin
from firebase_admin import credentials, firestore

matplotlib.use('Agg')

# Inicjalizacja Firestore
cred = credentials.Certificate("serviceAccountKey.json")
firebase_admin.initialize_app(cred)
db = firestore.client()

# Parametry testu
USERS = 2400                     # liczba symulowanych użytkowników
ITERATIONS_PER_USER = 20         # ile iteracji wykona każdy
DELAY_BETWEEN_OPS = (0.05, 0.3)  # odstęp między operacjami
COLLECTION_POOL = 100            # ile różnych kolekcji (rozrzucenie obciążenia)
USE_SHARED_DOC_PROB = 0.1        # z jakim prawdopodobieństwem użyć wspólnego dokumentu

latencies = defaultdict(list)
errors = defaultdict(int)


async def simulate_user(user_id):
    written_docs = []

    for i in range(ITERATIONS_PER_USER):
        print(f"Użytkownik {user_id} iteracja {i + 1}/{ITERATIONS_PER_USER}")

        collection = f"coll_{random.randint(0, COLLECTION_POOL - 1)}"
        use_shared_doc = random.random() < USE_SHARED_DOC_PROB
        document_id = f"shared_doc_{random.randint(0, 5)}" if use_shared_doc else f"user_{user_id}_doc_{i}"
        doc_ref = db.collection(collection).document(document_id)

        do_write = (i % 5) in (0, 2)  # tylko w 2 z każdych 5 iteracji

        if do_write:
            write_start = time.perf_counter()
            try:
                doc_ref.set({
                    "user": user_id,
                    "iteration": i,
                    "value": random.randint(1, 100),
                    "timestamp": firestore.SERVER_TIMESTAMP,
                    "structure": {
                        "nested": {
                            "field1": f"val_{random.randint(1, 999)}",
                            "field2": random.random()
                        }
                    }
                }, merge=True)
                latency = time.perf_counter() - write_start
                if i != 0:
                    latencies["write"].append(latency)
                else:
                    latencies["write_first"].append(latency)
                written_docs.append(doc_ref)
            except Exception as e:
                errors['write'] += 1
                print(f"[WRITE ERR] user_{user_id} {collection}/{document_id} | {e}")

            await asyncio.sleep(random.uniform(*DELAY_BETWEEN_OPS))

        # ODCZYT – wybierz istniejący dokument
        read_doc_ref = random.choice(written_docs) if written_docs else doc_ref
        read_start = time.perf_counter()
        try:
            doc = read_doc_ref.get()
            latency = time.perf_counter() - read_start
            if doc.exists and i != 0:
                latencies['read'].append(latency)
            elif doc.exists:
                latencies['read_first'].append(latency)
        except Exception as e:
            errors['read'] += 1
            print(f"[READ ERR] user_{user_id} {read_doc_ref.id} | {e}")

        await asyncio.sleep(random.uniform(*DELAY_BETWEEN_OPS))


async def run_stress_test():
    print("Rozpoczynanie testu Firestore...")
    start_time = time.perf_counter()
    tasks = [simulate_user(i) for i in range(USERS)]
    await asyncio.gather(*tasks)
    total_time = time.perf_counter() - start_time

    print("\n===== RAPORT TESTU FIRESTORE =====")
    print(f"Użytkownicy: {USERS}")
    print(f"Iteracje/użytkownik: {ITERATIONS_PER_USER}")
    print(f"Kolekcje: {COLLECTION_POOL}")
    print(f"Udział wspólnych dokumentów: {USE_SHARED_DOC_PROB * 100:.0f}%")
    print(f"Czas całkowity: {total_time:.2f}s")

    print(f"\nZapisy: {len(latencies['write'])} OK / {errors['write']} błędów")
    print(f"  Średni czas zapisu: {mean(latencies['write']):.4f}s")

    print(f"Odczyty: {len(latencies['read'])} OK / {errors['read']} błędów")
    print(f"  Średni czas odczytu: {mean(latencies['read']):.4f}s")

    save_metrics_to_file()


def save_metrics_to_file(filename="metrics.json"):
    metrics = {
        "params": {
            "users": USERS,
            "iterations_per_user": ITERATIONS_PER_USER,
            "collection_pool": COLLECTION_POOL,
            "use_shared_doc_prob": USE_SHARED_DOC_PROB
        },
        "errors": errors,
        "latencies": {
            "write": latencies["write"],
            "read": latencies["read"],
            "write_first": latencies["write_first"],
            "read_first": latencies["read_first"]
        }
    }

    with open(filename, "w") as f:
        json.dump(metrics, f, indent=2)
    print(f"Metryki zapisane jako {filename}")


if __name__ == "__main__":
    run_stress_test()
