#!/bin/bash

# Variables à configurer
SPLUNK_HOST="http://localhost:8089"
USERNAME="xxxx"
PASSWORD="xxxx"
PROMETHEUS_METRICS_FILE="/tmp/metrics.prom"

# Récupération des informations des index
INDEXES=$(curl -s -u "$USERNAME:$PASSWORD" "$SPLUNK_HOST/services/data/indexes?output_mode=json" | jq)

if [ -z "$INDEXES" ]; then
  echo "Erreur : Impossible de récupérer les données des index."
  exit 1
fi

# Création des métriques PrometheusME
echo "# HELP splunk_index_size_bytes Size of Splunk index in bytes" > $PROMETHEUS_METRICS_FILE
echo "# TYPE splunk_index_size_bytes gauge" >> $PROMETHEUS_METRICS_FILE

echo "$INDEXES" | jq -c '.entry[] | {name: .name, size: .content.currentDBSizeMB}' | while read -r index; do
  INDEX_NAME=$(echo $index | jq -r '.name')
  SIZE_MB=$(echo $index | jq -r '.size')
#  SIZE_BYTES=$(echo "$SIZE_MB * 1024 * 1024" | bc)
  echo "splunk_index_size_bytes{name=\"$INDEX_NAME\"} $SIZE_MB" >> $PROMETHEUS_METRICS_FILE
done

echo "Les métriques Splunk ont été mises à jour dans $PROMETHEUS_METRICS_FILE"