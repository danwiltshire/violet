## Developing

### Prerequisites

- Python 3.14
- Node.js 24
- OpenTofu 1.11.5+

### Getting Started

1. `python3 -m venv venv`
2. `source venv/bin/activate`
3. `pip install -r dev-requirements.txt`
4. `pip install pre-commit`
5. `pre-commit install --install-hooks`
6. `cd applications/web_app && npm install && cd ../..`

### Building and Pushing Application Images

1. `export AWS_PROFILE=...`
2. `export AWS_DEFAULT_REGION=eu-west-2`
3. `invoke build-and-push-images --environment-name prod`

### Building and Deploying the Frontend

1. `export AWS_PROFILE=...`
2. `export AWS_DEFAULT_REGION=eu-west-2`
3. `invoke build-and-deploy-frontend --environment-name prod`

## Architecture

See [ARCHITECTURE.md](ARCHITECTURE.md) for detailed diagrams.
