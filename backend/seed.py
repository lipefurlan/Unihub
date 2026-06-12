"""Popula o banco com dados fictícios realistas para o POC UniHub.

Uso (depois de `alembic upgrade head`):
    python seed.py              # limpa e recria tudo
    python seed.py --if-empty   # só popula se o banco estiver vazio (deploy)

O script é idempotente: limpa as tabelas e recria tudo do zero.
"""

import random
import sys
from datetime import date, datetime, timedelta
from decimal import Decimal

from sqlalchemy import select

from app.core.database import SessionLocal
from app.core.security import hash_password
from app.models import Admin, CheckIn, Gym, Payout, Plan, Student, Subscription

random.seed(42)  # seed fixo: dados reproduzíveis entre execuções

TODAY = date.today()

STUDENT_PASSWORD = "senha123"
GYM_PASSWORD = "academia123"
ADMIN_PASSWORD = "admin123"

# ---------------------------------------------------------------------------
# Planos — tiers crescentes estilo Wellhub, com benefícios cumulativos
# ---------------------------------------------------------------------------
PLANS = [
    # (tier, preço, cor, categorias incluídas, descrição)
    (1, "79.90", "#B0B0B0", ["musculação"],
     "Acesso a academias de musculação parceiras."),
    (2, "109.90", "#8C8C8C", ["musculação", "funcional", "corrida"],
     "Benefícios do Plano 1 + treino funcional e grupos de corrida."),
    (3, "139.90", "#6B6B6B", ["musculação", "funcional", "corrida"],
     "Benefícios do Plano 2 + 1 plano de treino mensal com assessoria de corrida."),
    (4, "169.90", "#4A4A4A", ["musculação", "funcional", "corrida", "pilates", "yoga"],
     "Benefícios do Plano 3 + estúdios de pilates e yoga."),
    (5, "199.90", "#FF8A5C", ["musculação", "funcional", "corrida", "pilates", "yoga", "crossfit"],
     "Benefícios do Plano 4 + boxes de crossfit."),
    (6, "224.90", "#FF5A1F", ["musculação", "funcional", "corrida", "pilates", "yoga", "crossfit", "natação"],
     "Benefícios do Plano 5 + natação e hidroginástica."),
    (7, "249.90", "#C8431A", ["musculação", "funcional", "corrida", "pilates", "yoga", "crossfit", "natação", "spinning"],
     "Acesso total: todas as modalidades e academias parceiras UniHub."),
]

# ---------------------------------------------------------------------------
# Academias — região de Campinas (incl. Barão Geraldo) e Americana
# ---------------------------------------------------------------------------
GYMS = [
    # (nome, email, endereço, lat, lng, modalidades, tier mínimo, repasse, capacidade, horário, cidade)
    ("Academia Campus Fit", "contato@campusfit.com.br",
     "Av. Albino J. B. de Oliveira, 1232 - Barão Geraldo, Campinas/SP",
     -22.8184, -47.0647, ["musculação", "funcional", "corrida"], 1, "8.00", 180, "06:00–23:00", "campinas"),
    ("Iron House Cambuí", "contato@ironhousecambui.com.br",
     "R. Coronel Quirino, 890 - Cambuí, Campinas/SP",
     -22.8946, -47.0487, ["musculação", "funcional"], 1, "8.50", 150, "06:00–22:00", "campinas"),
    ("Energia Centro", "contato@energiacentro.com.br",
     "R. Barão de Jaguara, 1100 - Centro, Campinas/SP",
     -22.9056, -47.0608, ["musculação", "spinning"], 2, "10.00", 120, "06:00–22:00", "campinas"),
    ("Runner Lab Cambuí", "contato@runnerlab.com.br",
     "R. Sampainho, 75 - Cambuí, Campinas/SP",
     -22.8919, -47.0455, ["corrida", "funcional"], 3, "12.00", 60, "05:30–21:00", "campinas"),
    ("Studio Vida Leve Pilates", "contato@vidalevepilates.com.br",
     "R. Maria Monteiro, 410 - Cambuí, Campinas/SP",
     -22.8902, -47.0521, ["pilates", "yoga"], 4, "15.00", 40, "07:00–21:00", "campinas"),
    ("CrossBox Barão", "contato@crossboxbarao.com.br",
     "R. Roxo Moreira, 1505 - Barão Geraldo, Campinas/SP",
     -22.8235, -47.0803, ["crossfit", "funcional"], 5, "18.00", 80, "06:00–21:30", "campinas"),
    ("Aquática Taquaral", "contato@aquaticataquaral.com.br",
     "Av. Heitor Penteado, 320 - Taquaral, Campinas/SP",
     -22.8758, -47.0531, ["natação", "hidroginástica"], 6, "20.00", 100, "06:00–21:00", "campinas"),
    ("Atlética Gym Americana", "contato@atleticagym.com.br",
     "Av. Brasil, 1450 - Centro, Americana/SP",
     -22.7370, -47.3245, ["musculação", "funcional", "corrida"], 1, "9.00", 160, "06:00–23:00", "americana"),
    ("Corpo & Mente Pilates", "contato@corpoementeamericana.com.br",
     "R. das Palmeiras, 210 - Jardim Girassol, Americana/SP",
     -22.7441, -47.3262, ["pilates", "yoga"], 4, "14.00", 35, "07:00–20:30", "americana"),
    ("Box Funcional Americana", "contato@boxfuncional.com.br",
     "R. Sete de Setembro, 677 - Centro, Americana/SP",
     -22.7392, -47.3313, ["crossfit", "funcional"], 5, "16.50", 70, "06:00–21:00", "americana"),
]

# ---------------------------------------------------------------------------
# Estudantes — universidades da região; João Silva é a credencial de demo
# ---------------------------------------------------------------------------
STUDENTS = [
    # (nome, email, universidade, tier do plano, cidade)
    ("João Silva", "joao.silva@dac.unicamp.br", "Unicamp", 3, "campinas"),
    ("Mariana Costa", "mariana.costa@puccampinas.edu.br", "PUC-Campinas", 5, "campinas"),
    ("Pedro Almeida", "pedro.almeida@dac.unicamp.br", "Unicamp", 1, "campinas"),
    ("Ana Beatriz Rocha", "ana.rocha@facamp.edu.br", "FACAMP", 4, "campinas"),
    ("Lucas Ferreira", "lucas.ferreira@dac.unicamp.br", "Unicamp", 7, "campinas"),
    ("Camila Souza", "camila.souza@puccampinas.edu.br", "PUC-Campinas", 2, "campinas"),
    ("Rafael Oliveira", "rafael.oliveira@fatec.sp.gov.br", "FATEC Americana", 5, "americana"),
    ("Júlia Mendes", "julia.mendes@fam.br", "FAM Americana", 1, "americana"),
    ("Gabriel Santos", "gabriel.santos@dac.unicamp.br", "Unicamp", 6, "campinas"),
    ("Larissa Lima", "larissa.lima@esamc.br", "ESAMC Campinas", 3, "campinas"),
    ("Thiago Carvalho", "thiago.carvalho@mackenzie.br", "Mackenzie Campinas", 2, "campinas"),
    ("Isabela Martins", "isabela.martins@puccampinas.edu.br", "PUC-Campinas", 4, "campinas"),
    ("Matheus Pereira", "matheus.pereira@fatec.sp.gov.br", "FATEC Americana", 7, "americana"),
    ("Beatriz Nunes", "beatriz.nunes@dac.unicamp.br", "Unicamp", 1, "campinas"),
    ("Vinícius Araújo", "vinicius.araujo@fam.br", "FAM Americana", 2, "americana"),
]

# Pesos das faixas de horário dos check-ins (pico de manhã cedo e fim de tarde)
HOUR_WEIGHTS = [
    (range(6, 9), 25),
    (range(9, 12), 10),
    (range(12, 15), 10),
    (range(15, 18), 15),
    (range(18, 21), 30),
    (range(21, 23), 10),
]


def pick_hour() -> int:
    ranges, weights = zip(*HOUR_WEIGHTS)
    chosen = random.choices(ranges, weights=weights)[0]
    return random.choice(list(chosen))


def main() -> None:
    db = SessionLocal()
    try:
        # Modo deploy: não sobrescreve um banco que já tem dados
        if "--if-empty" in sys.argv and db.query(Plan).first() is not None:
            print("Banco já populado — seed ignorado (--if-empty).")
            return

        # Limpeza (ordem respeita as FKs)
        for model in (CheckIn, Payout, Subscription, Student, Gym, Plan, Admin):
            db.query(model).delete()
        db.commit()

        # --- Operação UniHub (admin do backoffice) ---
        db.add(
            Admin(
                name="Operação UniHub",
                email="admin@unihub.com.br",
                password_hash=hash_password(ADMIN_PASSWORD),
            )
        )

        # --- Planos ---
        plans: dict[int, Plan] = {}
        for tier, price, color, categories, description in PLANS:
            plan = Plan(
                name=f"Plano {tier}",
                monthly_price=Decimal(price),
                tier=tier,
                color=color,
                included_categories=categories,
                benefits_description=description,
                has_running_coach=tier >= 3,  # Plano 3+ inclui assessoria de corrida
            )
            db.add(plan)
            plans[tier] = plan

        # --- Academias ---
        gyms: list[Gym] = []
        gym_password_hash = hash_password(GYM_PASSWORD)
        for i, (name, email, address, lat, lng, modalities, min_tier, payout, capacity, hours, city) in enumerate(GYMS):
            gym = Gym(
                name=name,
                email=email,
                password_hash=gym_password_hash,
                address=address,
                latitude=lat,
                longitude=lng,
                modalities=modalities,
                min_plan_tier=min_tier,
                checkin_payout_amount=Decimal(payout),
                capacity=capacity,
                opening_hours=hours,
                photo_url=f"https://picsum.photos/seed/unihub-gym-{i}/640/360",
            )
            gym.city = city  # atributo auxiliar do seed (não persiste)
            db.add(gym)
            gyms.append(gym)

        db.flush()

        # --- Estudantes + assinaturas ---
        students: list[Student] = []
        student_password_hash = hash_password(STUDENT_PASSWORD)
        for i, (name, email, university, plan_tier, city) in enumerate(STUDENTS):
            student = Student(
                name=name,
                email=email,
                password_hash=student_password_hash,
                university=university,
                photo_url=f"https://i.pravatar.cc/300?img={i + 10}",
                status="active",
            )
            student.city = city
            student.plan_tier = plan_tier
            db.add(student)
            students.append(student)
        db.flush()

        for student in students:
            plan = plans[student.plan_tier]
            start = TODAY - timedelta(days=random.randint(45, 150))
            # Renovação mensal ancorada no dia da contratação
            renewal = start
            while renewal <= TODAY:
                renewal += timedelta(days=30)
            db.add(
                Subscription(
                    student_id=student.id,
                    plan_id=plan.id,
                    start_date=start,
                    renewal_date=renewal,
                    amount=plan.monthly_price,
                    status="active",
                )
            )

        # --- Check-ins (~200 nos últimos 2 meses) ---
        # Cada aluno frequenta majoritariamente 2 academias "favoritas" da sua
        # cidade (coerência geográfica), respeitando o tier do plano.
        total_checkins = 0
        for student in students:
            accessible = [g for g in gyms if g.min_plan_tier <= student.plan_tier]
            local = [g for g in accessible if g.city == student.city]
            pool = local or accessible
            favorites = random.sample(pool, k=min(2, len(pool)))

            n_checkins = random.randint(10, 17)
            # Dias distintos: evita ferir a regra anti-fraude (1 por 3h)
            days_ago = random.sample(range(1, 60), k=n_checkins)
            for d in days_ago:
                gym = random.choice(favorites) if random.random() < 0.7 else random.choice(pool)
                ts = datetime.combine(TODAY - timedelta(days=d), datetime.min.time()).replace(
                    hour=pick_hour(), minute=random.randint(0, 59)
                )
                db.add(
                    CheckIn(
                        student_id=student.id,
                        gym_id=gym.id,
                        timestamp=ts,
                        plan_tier_at_checkin=student.plan_tier,
                        payout_amount_recorded=gym.checkin_payout_amount,
                    )
                )
                total_checkins += 1

        db.flush()

        # --- Payouts dos meses fechados ---
        # Mês retrasado: pago. Mês passado: pendente. Mês corrente: calculado ao vivo.
        first_of_current = TODAY.replace(day=1)
        last_month_end = first_of_current - timedelta(days=1)
        prev_month = last_month_end.strftime("%Y-%m")
        prev_prev_month = last_month_end.replace(day=1) - timedelta(days=1)
        prev_prev = prev_prev_month.strftime("%Y-%m")

        for gym in gyms:
            for month, status, paid_at in (
                (prev_prev, "paid", datetime.combine(first_of_current - timedelta(days=25), datetime.min.time()).replace(hour=10)),
                (prev_month, "pending", None),
            ):
                start_m = datetime.strptime(month + "-01", "%Y-%m-%d")
                end_m = (start_m + timedelta(days=32)).replace(day=1)
                month_checkins = db.scalars(
                    select(CheckIn).where(
                        CheckIn.gym_id == gym.id,
                        CheckIn.timestamp >= start_m,
                        CheckIn.timestamp < end_m,
                    )
                ).all()
                if not month_checkins:
                    continue
                db.add(
                    Payout(
                        gym_id=gym.id,
                        reference_month=month,
                        total_checkins=len(month_checkins),
                        total_amount=sum(c.payout_amount_recorded for c in month_checkins),
                        status=status,
                        paid_at=paid_at,
                    )
                )

        db.commit()

        # --- Resumo + credenciais de demo ---
        print("Seed concluído com sucesso!")
        print(f"  Planos:      {len(PLANS)}")
        print(f"  Academias:   {len(GYMS)}")
        print(f"  Estudantes:  {len(STUDENTS)}")
        print(f"  Check-ins:   {total_checkins}")
        print()
        print("Credenciais de teste:")
        print(f"  Estudante (Plano 3): joao.silva@dac.unicamp.br / {STUDENT_PASSWORD}")
        print(f"  Academia (Campus Fit): contato@campusfit.com.br / {GYM_PASSWORD}")
        print(f"  Admin (Operação UniHub): admin@unihub.com.br / {ADMIN_PASSWORD}")
        print()
        print("Dica de demo: o CrossBox Barão exige Plano 5 — o João (Plano 3)")
        print("verá o bloqueio de check-in por tier insuficiente.")
    finally:
        db.close()


if __name__ == "__main__":
    main()
