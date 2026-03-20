import logging

from metadata_guesser import guess_metadata_from_filename
from catalog import put_episode_catalog_item, put_movie_catalog_item
from metadata_guesser import TVEpisodeMetadata, MovieMetadata
from imagery import get_movie_imagery, get_tv_imagery

logger = logging.getLogger()
logger.setLevel(logging.INFO)


def lambda_handler(event: dict, _: dict):
    """
    Extracts media metadata from its filename and puts it into DynamoDB.
    """
    metadata = guess_metadata_from_filename(filename=event["ObjectKey"].split("/")[-1])

    if isinstance(metadata, TVEpisodeMetadata):
        series_id, season_id, episode_id = put_episode_catalog_item(metadata)

        get_tv_imagery(
            series_id=series_id,
            series_title=metadata.series_title,
            series_year=metadata.series_year,
            season_id=season_id,
            season_number=metadata.season,
            episode_id=episode_id,
            episode_number=metadata.episode,
        )

        return {
            "MediaId": episode_id,
        }

    elif isinstance(metadata, MovieMetadata):
        movie_id = put_movie_catalog_item(metadata)

        get_movie_imagery(
            movie_id=movie_id, movie_title=metadata.title, year=metadata.year
        )

        return {
            "MediaId": movie_id,
        }

    else:
        raise ValueError(
            "Not sure how to handle the metatype. Supported: TVEpisodeMetadata, MovieMetadata."
        )
