import requests
import boto3
import logging

from botocore.exceptions import ClientError
from themoviedb import TMDb
from settings import MEDIA_BUCKET_NAME, THE_MOVIE_DB_API_KEY

logger = logging.getLogger(__name__)


def get_movie_imagery(movie_id: str, movie_title: str, year: int):
    tmdb = TMDb(key=THE_MOVIE_DB_API_KEY)

    movies = tmdb.search().movies(movie_title, year=year).results
    movies.sort(key=lambda movie: movie.popularity, reverse=True)

    if not movies:
        raise LookupError("Could not find a series poster for the movie.")

    movie_poster_url = movies[0].poster_url()
    movie_poster_s3_key = f"images/{movie_id}/poster.jpg"

    if not s3_object_exists(MEDIA_BUCKET_NAME, movie_poster_s3_key):
        s3_put_from_url(movie_poster_url, MEDIA_BUCKET_NAME, movie_poster_s3_key)


def get_tv_imagery(series_id: str, series_title: str, series_year: int, season_id: str, season_number: str, episode_id: str, episode_number: str):
    tmdb = TMDb(key=THE_MOVIE_DB_API_KEY)

    series = tmdb.search().tv(series_title, first_air_date_year=series_year).results
    series.sort(key=lambda result: result.popularity, reverse=True)
    
    if not series:
        raise LookupError("Could not find a TV Series matching the search criterea.")

    logger.info("Matched TV series with TheMovieDB", extra={
        "series_id": series_id,
    })

    movie_db_series_id = series[0].id
    series_poster_url = series[0].poster_url()
    series_poster_s3_key = f"images/{series_id}/poster.jpg"

    logger.info("Found series poster URL", extra={
        "series_id": series_id,
        "url": series_poster_url,
    })

    if not s3_object_exists(MEDIA_BUCKET_NAME, series_poster_s3_key):
        s3_put_from_url(series_poster_url, MEDIA_BUCKET_NAME, series_poster_s3_key)

    season_posters = tmdb.season(movie_db_series_id, season_number).images().posters
    season_posters = [poster for poster in season_posters if poster.iso_639_1 == "en"]
    season_posters.sort(key=lambda poster: poster.vote_average, reverse=True)

    if not season_posters:
        raise LookupError("Could not find a season poster for the TV series.")
    
    season_poster_url = season_posters[0].file_url()
    season_poster_s3_key = f"images/{season_id}/poster.jpg"

    logger.info("Found season poster URL", extra={
        "series_id": series_id,
        "season_id": season_id,
        "url": season_poster_url,
    })

    if not s3_object_exists(MEDIA_BUCKET_NAME, season_poster_s3_key):
        s3_put_from_url(season_poster_url, MEDIA_BUCKET_NAME, season_poster_s3_key)
    
    episode_stills = tmdb.episode(movie_db_series_id, season_number, episode_number).images().stills
    episode_stills.sort(key=lambda image: image.vote_average, reverse=True)

    if not episode_stills:
        raise LookupError("Could not find a episode still for the TV series.")
    
    episode_still_url = episode_stills[0].file_url()
    episode_still_s3_key = f"images/{episode_id}/still.jpg"

    logger.info("Found episode still URL", extra={
        "series_id": series_id,
        "season_id": season_id,
        "episode_id": episode_id,
        "url": episode_still_url,
    })

    if not s3_object_exists(MEDIA_BUCKET_NAME, episode_still_s3_key):
        s3_put_from_url(episode_still_url, MEDIA_BUCKET_NAME, episode_still_s3_key)

    logger.info("All imagery populated", extra={
        "series_id": series_id,
        "season_id": season_id,
        "episode_id": episode_id,
    })


def s3_put_from_url(url: str, bucket: str, key: str):
    s3 = boto3.client("s3")

    poster = requests.get(url, timeout=(5, 60))
    poster.raise_for_status()

    s3.put_object(
        Bucket=bucket,
        Key=key,
        Body=poster.content,
        ContentType=poster.headers.get("Content-Type", "application/octet-stream"),
    )

def s3_object_exists(bucket: str, key: str) -> bool:
    s3 = boto3.client("s3")

    try:
        s3.head_object(Bucket=bucket, Key=key)
        return True
    except ClientError as e:
        error_code = e.response["Error"]["Code"]
        if error_code in ("404", "NoSuchKey"):
            return False
        raise
