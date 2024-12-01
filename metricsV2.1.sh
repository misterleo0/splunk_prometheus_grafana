#!/bin/bash

# Variables à configurer
SPLUNK_HOST="http://localhost:8089"
USERNAME="xxx"
PASSWORD="xxx"
PROMETHEUS_METRICS_FILE="/tmp/metrics.prom"

# Récupération des informations des index
INDEXES=$(curl -s -u "$USERNAME:$PASSWORD" "$SPLUNK_HOST/services/data/indexes?output_mode=json" | jq)

if [ -z "$INDEXES" ]; then
  echo "Erreur : Impossible de récupérer les données des index."
  exit 1
fi

# Création des métriques Prometheus
echo "# HELP splunk_index_size_megabytes Size of Splunk index in bytes" > $PROMETHEUS_METRICS_FILE
echo "# TYPE splunk_index_size_megabytes gauge" >> $PROMETHEUS_METRICS_FILE
echo "# HELP splunk_index_max_size_megabytes Maximum size of Splunk index in megabytes" >> $PROMETHEUS_METRICS_FILE
echo "# TYPE splunk_index_max_size_megabytes gauge" >> $PROMETHEUS_METRICS_FILE

echo "$INDEXES" | jq -c '.entry[] | {name: .name, current_size: .content.currentDBSizeMB, max_size: .content.maxTotalDataSizeMB}' | while read -r index; do
  INDEX_NAME=$(echo $index | jq -r '.name')
  CURRENT_SIZE_MB=$(echo $index | jq -r '.current_size')
  MAX_SIZE_MB=$(echo $index | jq -r '.max_size')
  echo "splunk_index_size_megabytes{name=\"$INDEX_NAME\"} $CURRENT_SIZE_MB" >> $PROMETHEUS_METRICS_FILE
  echo "splunk_index_max_size_megabytes{name=\"$INDEX_NAME\"}" $MAX_SIZE_MB >> $PROMETHEUS_METRICS_FILE
done

echo "Les métriques Splunk ont été mises à jour dans $PROMETHEUS_METRICS_FILE"
