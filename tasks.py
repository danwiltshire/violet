import boto3

from pathlib import Path
from invoke import task
from invoke.context import Context

def refresh_lambdas_by_tags(required_tags: dict[str, str]):
    client = boto3.client("lambda")

    paginator = client.get_paginator("list_functions")
    for page in paginator.paginate():
        for fn in page["Functions"]:
            if fn.get("PackageType") != "Image":
                continue

            arn = fn["FunctionArn"]
            tags = client.list_tags(Resource=arn).get("Tags", {})

            if not all(tags.get(k) == v for k, v in required_tags.items()):
                continue

            image_uri = client.get_function(FunctionName=fn["FunctionName"])["Code"]["ImageUri"]

            client.update_function_code(
                FunctionName=fn["FunctionName"],
                ImageUri=image_uri,
                Publish=False,
            )

            print(f"Refreshed {fn['FunctionName']}")

def get_cloudfront_distribution_ids_by_tags(required_tags: dict[str, str]) -> list[str]:
    client = boto3.client("cloudfront")
    paginator = client.get_paginator("list_distributions")
    matches = []

    for page in paginator.paginate():
        for dist in page.get("DistributionList", {}).get("Items", []):
            tag_items = client.list_tags_for_resource(Resource=dist["ARN"]).get("Tags", {}).get("Items", [])
            tag_map = {t["Key"]: t["Value"] for t in tag_items}

            if all(tag_map.get(k) == v for k, v in required_tags.items()):
                matches.append(dist["Id"])

    return matches

@task
def build_and_push_images(context: Context, environment_name: str):
    repository_domain = "426576223955.dkr.ecr.eu-west-2.amazonaws.com"
    repository_name = f"violet-{environment_name}-images"

    image_directories: dict[str, Path] = {
        "violet-lambda": Path("applications") / "violet_lambda_function"
    }

    context.run(f"aws ecr get-login-password --region eu-west-2 | docker login --username AWS --password-stdin {repository_domain}")
    
    for image_name, path in image_directories.items():
        image_tag = f"{repository_domain}/{repository_name}:{image_name}"
        context.run(f"docker build -t {image_tag} {path.as_posix()} --provenance=false")
        context.run(f"docker push {image_tag}")

    refresh_lambdas_by_tags(
        required_tags={
            "app": "violet",
            "env": environment_name,
        },
    )

@task
def build_and_deploy_frontend(context: Context, environment_name: str):
    bucket_name = f"violet-{environment_name}-media"

    with context.cd(Path('applications') / "web_app" ):
        context.run("npm install")
        context.run("npx ng build")

    with context.cd(Path('applications') / "web_app" / "dist" / "violet"):
        context.run(f"aws s3 sync browser/ s3://{bucket_name}/frontend/ --delete")

    distribution_ids = get_cloudfront_distribution_ids_by_tags({
        "app": "violet",
        "env": environment_name,
    })

    for distribution_id in distribution_ids:
        context.run(f"aws cloudfront create-invalidation --distribution-id '{distribution_id}' --paths '/*'")
