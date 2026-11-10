# API UniHub — imagem de produção (Railway/Render/qualquer Docker host)
FROM python:3.12-slim

WORKDIR /app

# Horário de Brasília: check-ins, semanas da meta e virada do mês seguem a hora local
RUN apt-get update && apt-get install -y --no-install-recommends tzdata && rm -rf /var/lib/apt/lists/*
ENV TZ=America/Sao_Paulo

COPY requirements.txt .
RUN pip install --no-cache-dir -r requirements.txt

COPY . .

# Aplica migrations, popula dados de demo só na primeira subida e inicia a API.
# --proxy-headers: atrás do proxy do Railway, repassa o IP real do cliente
# (necessário para o rate limiting por IP funcionar corretamente).
CMD alembic upgrade head && python seed.py --if-empty && uvicorn app.main:app --host 0.0.0.0 --port ${PORT:-8000} --proxy-headers --forwarded-allow-ips="*"
