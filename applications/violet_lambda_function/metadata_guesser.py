from dataclasses import dataclass
from guessit import guessit
from themoviedb import TMDb
from settings import THE_MOVIE_DB_API_KEY


@dataclass
class TVEpisodeMetadata:
    series_title: str
    season: int
    episode: int
    title: str
    series_year: int


@dataclass
class MovieMetadata:
    title: str
    year: str


def guess_metadata_from_filename(filename: str):
    guessed_metadata = guessit(filename)
    type = guessed_metadata.get("type")

    if type == "episode":
        return TVEpisodeMetadata(
            series_title=guessed_metadata.get("title"),
            season=guessed_metadata.get("season"),
            episode=guessed_metadata.get("episode"),
            title=guessed_metadata.get("episode_title"),
            series_year=guessed_metadata.get("year"),
        )

    elif type == "movie":
        return MovieMetadata(
            title=guessed_metadata.get("title"), year=str(guessed_metadata.get("year"))
        )

    else:
        raise ValueError(
            f"The response from GuessIt returned an expected type '{type}', expected 'episode' or 'movie'."
        )


def search_external_movie_metadata(title: str, year: int):
    tmdb = TMDb(key=THE_MOVIE_DB_API_KEY)

    movies = tmdb.search().movies(title, year=year).results

    if not movies:
        return None

    movies.sort(key=lambda movie: movie.popularity, reverse=True)

    return movies[0]
