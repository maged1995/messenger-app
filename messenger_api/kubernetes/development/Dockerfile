FROM python:3

RUN apt-get update \
    && apt-get install -y --no-install-recommends \
        postgresql-client \
    && rm -rf /var/lib/apt/lists/*

WORKDIR /app

ENV VIRTUAL_ENV=/opt/venv
RUN python3 -m venv $VIRTUAL_ENV
ENV PATH="$VIRTUAL_ENV/bin:$PATH"

RUN /opt/venv/bin/python3 -m pip install --upgrade pip

COPY /home/maged/personal/education/cloudDevOpsEngineer/messenger/messenger_api/requirements.txt ./
RUN . /opt/venv/bin/activate && pip install -r requirements.txt
COPY /home/maged/personal/education/cloudDevOpsEngineer/messenger/messenger_api .

EXPOSE 8000
# CMD ["python", "manage.py", "runserver", "0.0.0.0:8000"]