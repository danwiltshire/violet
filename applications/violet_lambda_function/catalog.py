from metadata_guesser import TVEpisodeMetadata, MovieMetadata
import boto3
import logging

from boto3.dynamodb.conditions import Key, Attr

from uuid import uuid4
from botocore.exceptions import ClientError
from slugify import slugify
from settings import CATALOG_TABLE_NAME

logger = logging.getLogger(__name__)

dynamodb = boto3.resource("dynamodb")
table = dynamodb.Table(CATALOG_TABLE_NAME)


def zpad(n: int, width: int = 4) -> str:
    """Zero-pad an integer so string sorting matches numeric sorting."""
    return str(n).zfill(width)


def generate_media_id():
    return str(uuid4())


def put_if_absent(item: dict[str, any], condition="attribute_not_exists(PK) AND attribute_not_exists(SK)"):
    try:
        table.put_item(
            Item=item,
            ConditionExpression=condition,
            ReturnValuesOnConditionCheckFailure='ALL_OLD',
        )

        return item["Id"]

    except ClientError as e:
        if e.response["Error"]["Code"] == "ConditionalCheckFailedException":
            return e.response.get("Item", {}).get("Id", {}).get("S")
        raise


def put_movie_catalog_item(metadata: MovieMetadata):
    movie_id = put_if_absent({
        "PK": "MOVIE",
        "SK": slugify(metadata.title),
        "Id": generate_media_id(),
        "Title": metadata.title,
        "Year": metadata.year,
    })

    logger.info("Movie metadata saved in DynamoDB", extra={
        "movie_id": movie_id,
    })

    return movie_id


def put_episode_catalog_item(metadata: TVEpisodeMetadata):
    season_title = f"Season {metadata.season}" if metadata.season >= 1 else "Specials"

    series_id = put_if_absent({
        "PK": "SERIES",
        "SK": slugify(metadata.series_title),
        "Id": generate_media_id(),
        "Title": metadata.series_title,
        "Year": metadata.series_year,
    })

    season_id = put_if_absent({
        "PK": f"SEASON#{slugify(metadata.series_title)}",
        "SK": slugify(season_title),
        "Id": generate_media_id(),
        "Title": season_title,
        "SeasonNumber": metadata.season,
    })

    episode_id = put_if_absent({
        "PK": f"EPISODE#{slugify(metadata.series_title)}#{slugify(season_title)}",
        "SK": zpad(metadata.episode),
        "Id": generate_media_id(),
        "Title": metadata.title,
        "EpisodeNumber": metadata.episode,
    })
    
    logger.info("Episode metadata saved in DynamoDB", extra={
        "series_id": series_id,
        "season_id": season_id,
        "episode_id": episode_id,
    })

    return series_id, season_id, episode_id


def get_movies():
    response = table.query(
        Limit=25,
        KeyConditionExpression=Key('PK').eq('MOVIE'),
    )

    items = response["Items"]

    to_return = []

    for item in items:
        to_return.append({
            "title": item["Title"],
            "id": item["Id"],
            "year": item["Year"],
            "slug": item["SK"],
        })
    
    return to_return


def get_tv_series():
    response = table.query(
        Limit=25,
        KeyConditionExpression=Key('PK').eq('SERIES'),
    )

    items = response["Items"]

    to_return = []

    for item in items:
        to_return.append({
            "title": item["Title"],
            "id": item["Id"],
            "year": item["Year"],
            "slug": item["SK"],
        })
    
    return to_return


def get_tv_series_seasons(series_slug: str):
    response = table.query(
        Limit=25,
        KeyConditionExpression=Key('PK').eq(f'SEASON#{series_slug}'),
    )

    items = response["Items"]

    to_return = []

    for item in items:
        to_return.append({
            "title": item["Title"],
            "id": item["Id"],
            "season_number": item["SeasonNumber"],
            "slug": item["SK"],
        })
    
    return to_return


def get_tv_series_season_episodes(series_slug: str, season_slug: str):
    response = table.query(
        Limit=25,
        KeyConditionExpression=Key('PK').eq(f'EPISODE#{series_slug}#{season_slug}'),
    )

    items = response["Items"]

    to_return = []

    for item in items:
        to_return.append({
            "title": item["Title"],
            "id": item["Id"],
            "episode_number": item["EpisodeNumber"],
            # "slug": item["SK"],
        })
    
    return to_return
