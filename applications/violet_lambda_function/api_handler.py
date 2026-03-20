from aws_lambda_powertools.event_handler import LambdaFunctionUrlResolver
from aws_lambda_powertools.utilities.typing import LambdaContext

from catalog import (
    get_tv_series as _get_tv_series,
    get_tv_series_season_episodes as _get_tv_series_season_episodes,
    get_tv_series_seasons as _get_tv_series_seasons,
    get_movies as _get_movies,
)

app = LambdaFunctionUrlResolver()


@app.get("/api/movies")
def get_momvies():
    return _get_movies()


@app.get("/api/tv/series")
def get_tv_series():
    return _get_tv_series()


@app.get("/api/tv/series/<series_slug>")
def get_tv_series_seasons(series_slug: str):
    return _get_tv_series_seasons(series_slug)


@app.get("/api/tv/series/<series_slug>/season/<season_slug>")
def get_tv_series_season_episodes(series_slug: str, season_slug: str):
    return _get_tv_series_season_episodes(series_slug, season_slug)


def lambda_handler(event: dict, context: LambdaContext) -> dict:
    return app.resolve(event, context)
