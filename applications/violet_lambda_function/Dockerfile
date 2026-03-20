# checkov:skip=CKV_DOCKER_3: AWS Lambda manages the user.
# checkov:skip=CKV_DOCKER_2: Healthcheck not required in AWS Lambda.

FROM public.ecr.aws/lambda/python:3.14

COPY requirements.txt ${LAMBDA_TASK_ROOT}

RUN pip install -r requirements.txt

COPY . ${LAMBDA_TASK_ROOT}
