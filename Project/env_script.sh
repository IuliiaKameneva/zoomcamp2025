#!/bin/bash

# Чтение JSON файла и кодирование его в Base64
ENCODED_JSON=$(cat ..//essencial_data/fair-canto-447119-p5-9091e1a7224d.json | base64 -w 0)

# Запись в .env файл
echo "TF_VAR_gcp_creds=${ENCODED_JSON}" > .env
