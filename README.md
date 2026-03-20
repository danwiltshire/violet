## Developing

### Prerequisites

- Python 3.14

### Getting Started

1. `python3 -m venv venv`
2. `source venv/bin/activate`
3. `pip install pre-commit`
4. `pre-commit install --install-hooks`

### Building and Pushing Application Images

1. `export AWS_PROFILE=...`
2. `export AWS_DEFAULT_REGION=eu-west-2`
3. `invoke build-and-push-images --environment-name prod`

### Building and Deploying the Frontend

> You'll need NodeJS 24 or above to complete these steps.

1. `export AWS_PROFILE=...`
2. `export AWS_DEFAULT_REGION=eu-west-2`
3. `invoke build-and-deploy-frontend --environment-name prod`