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
from app.core.config import settings
from app.models import Admin, Challenge, CheckIn, Gym, Payout, Plan, Student, Subscription, University
from app.services.challenge_service import create_challenge
from app.services.engagement_service import MONTHS_PT
from app.services.university_service import find_university_for_email, student_price

random.seed(42)  # seed fixo: dados reproduzíveis entre execuções

TODAY = date.today()

STUDENT_PASSWORD = "senha123"
DEMO_STUDENT_EMAIL = "joao.silva@dac.unicamp.br"
GYM_PASSWORD = "academia123"
ADMIN_PASSWORD = "admin123"
IES_EMAIL = "programa@facamp.edu.br"  # login da FACAMP no portal da IES
IES_PASSWORD = "facamp123"

# ---------------------------------------------------------------------------
# Modelo de negócio do TCC (plano de negócio, versão revisada)
# Trocar aqui e rodar o seed de novo para a demo refletir outros números.
# ---------------------------------------------------------------------------
PLAN_PRICE = "130.00"  # preço cheio do plano; o aluno paga isso menos o subsídio
PAYOUT_PER_VISIT = "8.00"  # repasse por check-in (teto de visitas em app/core/config.py)
IES_MONTHLY_FEE = "3000.00"  # taxa fixa por contrato de IES
IES_FEE_PER_STUDENT = "15.00"  # taxa por aluno que assina
IES_SUBSIDY_PER_STUDENT = "10.00"  # subsídio do exemplo do TCC: aluno paga R$ 120

ALL_CATEGORIES = ["musculação", "funcional", "corrida", "pilates", "yoga", "crossfit", "natação", "spinning"]

PLANS = [
    # (tier, preço, cor, categorias incluídas, descrição)
    (1, PLAN_PRICE, "#FF5A1F", ALL_CATEGORIES,
     "Acesso a todas as academias e estúdios parceiros perto do campus e da sua cidade, sem fidelidade."),
]

# ---------------------------------------------------------------------------
# IES conveniadas — o domínio do e-mail define quem pode se cadastrar
# ---------------------------------------------------------------------------
UNIVERSITIES = [
    # (nome, domínios de e-mail)
    ("FACAMP", ["facamp.edu.br"]),
    ("Unicamp", ["unicamp.br"]),
    ("PUC-Campinas", ["puccampinas.edu.br"]),
    ("FATEC Americana", ["fatec.sp.gov.br"]),
    ("FAM Americana", ["fam.br"]),
    ("ESAMC Campinas", ["esamc.br"]),
    ("Mackenzie Campinas", ["mackenzie.br"]),
]

# ---------------------------------------------------------------------------
# Academias — região de Campinas (incl. Barão Geraldo) e Americana
# ---------------------------------------------------------------------------
GYMS = [
    # (nome, email, endereço, lat, lng, modalidades, tier mínimo, repasse, capacidade, horário, cidade)
    ("Academia Campus Fit", "contato@campusfit.com.br",
     "Av. Albino J. B. de Oliveira, 1232 - Barão Geraldo, Campinas/SP",
     -22.8184, -47.0647, ["musculação", "funcional", "corrida"], 1, PAYOUT_PER_VISIT, 180, "06:00–23:00", "campinas"),
    ("Iron House Cambuí", "contato@ironhousecambui.com.br",
     "R. Coronel Quirino, 890 - Cambuí, Campinas/SP",
     -22.8946, -47.0487, ["musculação", "funcional"], 1, PAYOUT_PER_VISIT, 150, "06:00–22:00", "campinas"),
    ("Energia Centro", "contato@energiacentro.com.br",
     "R. Barão de Jaguara, 1100 - Centro, Campinas/SP",
     -22.9056, -47.0608, ["musculação", "spinning"], 1, PAYOUT_PER_VISIT, 120, "06:00–22:00", "campinas"),
    ("Runner Lab Cambuí", "contato@runnerlab.com.br",
     "R. Sampainho, 75 - Cambuí, Campinas/SP",
     -22.8919, -47.0455, ["corrida", "funcional"], 1, PAYOUT_PER_VISIT, 60, "05:30–21:00", "campinas"),
    ("Studio Vida Leve Pilates", "contato@vidalevepilates.com.br",
     "R. Maria Monteiro, 410 - Cambuí, Campinas/SP",
     -22.8902, -47.0521, ["pilates", "yoga"], 1, PAYOUT_PER_VISIT, 40, "07:00–21:00", "campinas"),
    ("CrossBox Barão", "contato@crossboxbarao.com.br",
     "R. Roxo Moreira, 1505 - Barão Geraldo, Campinas/SP",
     -22.8235, -47.0803, ["crossfit", "funcional"], 1, PAYOUT_PER_VISIT, 80, "06:00–21:30", "campinas"),
    ("Aquática Taquaral", "contato@aquaticataquaral.com.br",
     "Av. Heitor Penteado, 320 - Taquaral, Campinas/SP",
     -22.8758, -47.0531, ["natação", "hidroginástica"], 1, PAYOUT_PER_VISIT, 100, "06:00–21:00", "campinas"),
    ("Atlética Gym Americana", "contato@atleticagym.com.br",
     "Av. Brasil, 1450 - Centro, Americana/SP",
     -22.7370, -47.3245, ["musculação", "funcional", "corrida"], 1, PAYOUT_PER_VISIT, 160, "06:00–23:00", "americana"),
    ("Corpo & Mente Pilates", "contato@corpoementeamericana.com.br",
     "R. das Palmeiras, 210 - Jardim Girassol, Americana/SP",
     -22.7441, -47.3262, ["pilates", "yoga"], 1, PAYOUT_PER_VISIT, 35, "07:00–20:30", "americana"),
    ("Box Funcional Americana", "contato@boxfuncional.com.br",
     "R. Sete de Setembro, 677 - Centro, Americana/SP",
     -22.7392, -47.3313, ["crossfit", "funcional"], 1, PAYOUT_PER_VISIT, 70, "06:00–21:00", "americana"),
]

# ---------------------------------------------------------------------------
# Estudantes — universidades da região; João Silva é a credencial de demo
# ---------------------------------------------------------------------------
STUDENTS = [
    # (nome, email, universidade, tier do plano, cidade, curso) — todos no plano único
    ("João Silva", "joao.silva@dac.unicamp.br", "Unicamp", 1, "campinas", "Engenharia"),
    ("Mariana Costa", "mariana.costa@puccampinas.edu.br", "PUC-Campinas", 1, "campinas", "Direito"),
    ("Pedro Almeida", "pedro.almeida@dac.unicamp.br", "Unicamp", 1, "campinas", "Ciência da Computação"),
    ("Ana Beatriz Rocha", "ana.rocha@facamp.edu.br", "FACAMP", 1, "campinas", "Administração"),
    ("Lucas Ferreira", "lucas.ferreira@dac.unicamp.br", "Unicamp", 1, "campinas", "Medicina"),
    ("Camila Souza", "camila.souza@puccampinas.edu.br", "PUC-Campinas", 1, "campinas", "Psicologia"),
    ("Rafael Oliveira", "rafael.oliveira@fatec.sp.gov.br", "FATEC Americana", 1, "americana", "Ciência da Computação"),
    ("Júlia Mendes", "julia.mendes@fam.br", "FAM Americana", 1, "americana", "Design"),
    ("Gabriel Santos", "gabriel.santos@dac.unicamp.br", "Unicamp", 1, "campinas", "Economia"),
    ("Larissa Lima", "larissa.lima@esamc.br", "ESAMC Campinas", 1, "campinas", "Administração"),
    ("Thiago Carvalho", "thiago.carvalho@mackenzie.br", "Mackenzie Campinas", 1, "campinas", "Arquitetura e Urbanismo"),
    ("Isabela Martins", "isabela.martins@puccampinas.edu.br", "PUC-Campinas", 1, "campinas", "Direito"),
    ("Matheus Pereira", "matheus.pereira@fatec.sp.gov.br", "FATEC Americana", 1, "americana", "Engenharia"),
    ("Beatriz Nunes", "beatriz.nunes@dac.unicamp.br", "Unicamp", 1, "campinas", "Medicina"),
    ("Vinícius Araújo", "vinicius.araujo@fam.br", "FAM Americana", 1, "americana", "Comunicação Social"),
    # Mais alunos da FACAMP (piloto), para o portal da IES ter o que mostrar
    ("Bruno Teixeira", "bruno.teixeira@facamp.edu.br", "FACAMP", 1, "campinas", "Economia"),
    ("Carolina Ribeiro", "carolina.ribeiro@facamp.edu.br", "FACAMP", 1, "campinas", "Direito"),
    ("Diego Moraes", "diego.moraes@facamp.edu.br", "FACAMP", 1, "campinas", "Relações Internacionais"),
    ("Fernanda Duarte", "fernanda.duarte@facamp.edu.br", "FACAMP", 1, "campinas", "Administração"),
    # Mais cursos da FACAMP para a copa entre cursos ter disputa
    ("Gustavo Prado", "gustavo.prado@facamp.edu.br", "FACAMP", 1, "campinas", "Economia"),
    ("Helena Castro", "helena.castro@facamp.edu.br", "FACAMP", 1, "campinas", "Direito"),
    ("Igor Batista", "igor.batista@facamp.edu.br", "FACAMP", 1, "campinas", "Relações Internacionais"),
    ("Juliana Freitas", "juliana.freitas@facamp.edu.br", "FACAMP", 1, "campinas", "Administração"),
    ("Leonardo Pires", "leonardo.pires@facamp.edu.br", "FACAMP", 1, "campinas", "Economia"),
]

LOW_FREQUENCY = {
    "helena.castro@facamp.edu.br",
    "igor.batista@facamp.edu.br",
    "leonardo.pires@facamp.edu.br",
    "carolina.ribeiro@facamp.edu.br",
}

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
        for model in (Challenge, CheckIn, Payout, Subscription, Student, University, Gym, Plan, Admin):
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

        # --- IES conveniadas ---
        for name, domains in UNIVERSITIES:
            db.add(
                University(
                    name=name,
                    email_domains=domains,
                    monthly_fee=Decimal(IES_MONTHLY_FEE),
                    fee_per_student=Decimal(IES_FEE_PER_STUDENT),
                    subsidy_per_student=Decimal(IES_SUBSIDY_PER_STUDENT),
                    # Só a FACAMP (piloto) tem acesso ao portal no seed
                    email=IES_EMAIL if name == "FACAMP" else None,
                    password_hash=hash_password(IES_PASSWORD) if name == "FACAMP" else None,
                )
            )
        db.flush()

        # --- Planos ---
        plans: dict[int, Plan] = {}
        for tier, price, color, categories, description in PLANS:
            plan = Plan(
                name="Plano UniHub",
                monthly_price=Decimal(price),
                tier=tier,
                color=color,
                included_categories=categories,
                benefits_description=description,
                has_running_coach=False,
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
            gym.seed_city = city  # atributo auxiliar do seed (não persiste)
            db.add(gym)
            gyms.append(gym)

        db.flush()

        # --- Estudantes + assinaturas ---
        students: list[Student] = []
        student_password_hash = hash_password(STUDENT_PASSWORD)
        for i, (name, email, university, plan_tier, city, course) in enumerate(STUDENTS):
            ies = find_university_for_email(db, email)
            student = Student(
                name=name,
                email=email,
                password_hash=student_password_hash,
                university=ies.name if ies else university,
                university_id=ies.id if ies else None,
                photo_url=f"https://i.pravatar.cc/300?img={i + 10}",
                status="active",
                course=course,
            )
            student.seed_city = city
            student.home_city = city.capitalize()
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
                    amount=student_price(plan.monthly_price, student.university_ref),
                    status="active",
                )
            )

        # --- Check-ins (~200 nos últimos 2 meses) ---
        # Cada aluno frequenta majoritariamente 2 academias "favoritas" da sua
        # cidade (coerência geográfica).
        now = datetime.now()
        month_start = datetime.combine(TODAY.replace(day=1), datetime.min.time())
        planned: list[tuple[Student, Gym, datetime]] = []
        for student in students:
            accessible = [g for g in gyms if g.min_plan_tier <= student.plan_tier]
            local = [g for g in accessible if g.seed_city == student.seed_city]
            pool = local or accessible
            favorites = random.sample(pool, k=min(2, len(pool)))

            student.favorite_gyms = list(favorites)

            if student.email == DEMO_STUDENT_EMAIL:
                # Demo: João é de Americana (cidade natal) e estuda em Campinas;
                # meta de 2 treinos por semana para a sequência aparecer
                student.home_city = "Americana"
                student.weekly_goal = 2
                # João chega à demo com 9 visitas pagas no mês: o próximo
                # check-in é o 10º (pago) e o seguinte já passa do teto.
                for d in random.sample(range(32, 60), k=8):
                    ts = datetime.combine(TODAY - timedelta(days=d), datetime.min.time()).replace(
                        hour=pick_hour(), minute=random.randint(0, 59)
                    )
                    planned.append((student, random.choice(favorites), ts))
                step = (now - timedelta(hours=1) - month_start) / 9
                for k in range(9):
                    # Alterna entre 3 academias para respeitar o anti-fraude de 3h
                    # Horário realista no dia (nada de treino às 2h da manhã)
                    ts = (month_start + step * k).replace(hour=pick_hour(), minute=random.randint(0, 59))
                    ts = min(ts, now - timedelta(hours=4))
                    planned.append((student, pool[k % min(3, len(pool))], ts))
                continue

            # Os últimos alunos da FACAMP treinam pouco: a copa de cursos
            # precisa de turma que não está treinando toda semana
            n_checkins = random.randint(4, 9) if student.email in LOW_FREQUENCY else random.randint(10, 17)
            # Dias distintos: evita ferir a regra anti-fraude (1 por 3h)
            days_ago = random.sample(range(1, 60), k=n_checkins)
            for d in days_ago:
                gym = random.choice(favorites) if random.random() < 0.7 else random.choice(pool)
                ts = datetime.combine(TODAY - timedelta(days=d), datetime.min.time()).replace(
                    hour=pick_hour(), minute=random.randint(0, 59)
                )
                planned.append((student, gym, ts))

        # Aplica o teto de visitas pagas por aluno no mês, em ordem cronológica
        paid_per_student_month: dict[tuple[int, str], int] = {}
        total_checkins = 0
        for student, gym, ts in sorted(planned, key=lambda item: item[2]):
            key = (student.id, ts.strftime("%Y-%m"))
            is_paid = paid_per_student_month.get(key, 0) < settings.max_paid_checkins_per_month
            if is_paid:
                paid_per_student_month[key] = paid_per_student_month.get(key, 0) + 1
            db.add(
                CheckIn(
                    student_id=student.id,
                    gym_id=gym.id,
                    timestamp=ts,
                    plan_tier_at_checkin=student.plan_tier,
                    payout_amount_recorded=gym.checkin_payout_amount if is_paid else Decimal("0"),
                    is_paid=is_paid,
                    # Visitas antigas já passaram pela recepção
                    validated_at=ts + timedelta(minutes=random.randint(1, 5)),
                    # ~60% das visitas avaliadas, quase sempre bem; as visitas do
                    # João desta semana ficam sem nota para a demo mostrar o "Avaliar"
                    rating=(
                        random.choices([5, 4, 3, 2], weights=[50, 35, 10, 5])[0]
                        if random.random() < 0.6 and ts < now - timedelta(days=3)
                        else None
                    ),
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

        # --- Desafios ---
        # Entre faculdades no mês corrente (operação), copa entre cursos da
        # FACAMP (a própria IES) e o desafio do mês passado, já com campeã.
        facamp = db.scalar(select(University).where(University.name == "FACAMP"))
        month_end = (first_of_current + timedelta(days=32)).replace(day=1) - timedelta(days=1)
        create_challenge(
            db,
            title=f"Desafio de {MONTHS_PT[TODAY.month - 1]}: qual faculdade treina mais?",
            description="Pontua a média de check-ins por aluno assinante no mês.",
            scope="universities",
            metric="checkins_per_student",
            start_date=first_of_current,
            end_date=month_end,
            university_id=None,
            created_by="admin",
        )
        create_challenge(
            db,
            title="Copa FACAMP de cursos",
            description="Vence o curso com a maior parte da turma treinando. Prêmio: happy hour da atlética.",
            scope="courses",
            metric="active_share",
            start_date=TODAY - timedelta(days=20),
            end_date=TODAY + timedelta(days=10),
            university_id=facamp.id,
            created_by="ies",
        )
        create_challenge(
            db,
            title=f"Desafio de {MONTHS_PT[last_month_end.month - 1]}: qual faculdade treina mais?",
            description="Pontua a média de check-ins por aluno assinante no mês.",
            scope="universities",
            metric="checkins_per_student",
            start_date=last_month_end.replace(day=1),
            end_date=last_month_end,
            university_id=None,
            created_by="admin",
        )

        # --- Resumo + credenciais de demo ---
        print("Seed concluído com sucesso!")
        print(f"  IES:         {len(UNIVERSITIES)}")
        print(f"  Planos:      {len(PLANS)}")
        print(f"  Academias:   {len(GYMS)}")
        print(f"  Estudantes:  {len(STUDENTS)}")
        print(f"  Check-ins:   {total_checkins}")
        print()
        print("Credenciais de teste:")
        print(f"  Estudante (Unicamp): {DEMO_STUDENT_EMAIL} / {STUDENT_PASSWORD}")
        print(f"  Academia (Campus Fit): contato@campusfit.com.br / {GYM_PASSWORD}")
        print(f"  Admin (Operação UniHub): admin@unihub.com.br / {ADMIN_PASSWORD}")
        print(f"  IES (FACAMP): {IES_EMAIL} / {IES_PASSWORD}")
        print()
        print("Dica de demo: o João já tem 9 visitas pagas no mês. O 10º check-in é pago;")
        print(f"a partir do 11º a academia vê a visita como não remunerada (teto de {settings.max_paid_checkins_per_month}).")
    finally:
        db.close()


if __name__ == "__main__":
    main()
