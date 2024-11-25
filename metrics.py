import json
import requests
from flask import Flask, Response

app = Flask(__name__)

# Configuration
SPLUNK_URL_CPU_RAM = "http://localhost:8089/services/server/status/resource-usage/hostwide?output_mode=json"
SPLUNK_USER = "root"
SPLUNK_PASSWORD = "Btssio75000"

@app.route('/metrics')
def metrics():
    try:
        # Récupérer la réponse JSON de l'API Splunk
        response = requests.get(SPLUNK_URL_CPU_RAM, auth=(SPLUNK_USER, SPLUNK_PASSWORD), verify=False)
        data = response.json()  # Convertir en dictionnaire Python

        # Accéder aux données nécessaires (dans `entry[0]['content']`)
        content = data.get("entry", [{}])[0].get("content", {})

        cpu_non_utiliser = float(content.get("cpu_idle_pct", 0)) # % Inactivité CPU
        cpu_utiliser = float(content.get("cpu_system_pct", 0)) # % Utilisation du CPU
        ram_total = float(content.get("mem", 0))  # Total mémoire en Mo
        ram_utiliser = float(content.get("mem_used", 0))  # Mémoire utilisée en Mo

        # Générer les métriques au format Prometheus
        metrics_output = (
            f"splunk_cpu_non_utiliser {cpu_non_utiliser}\n"
            f"splunk_cpu_utiliser {cpu_utiliser}\n"

            f"splunk_ram_total {ram_total}\n"
            f"splunk_ram_utiliser {ram_utiliser}\n"
        )

        # Retourner les métriques au format Prometheus
        return Response(metrics_output, mimetype='text/plain')

    except Exception as e:
        return Response(f"# Error: {str(e)}", mimetype='text/plain')

if __name__ == '__main__':
    app.run(host='0.0.0.0', port=8123)