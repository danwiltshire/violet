import os


# DynamoDB Table which stores media metadata.
CATALOG_TABLE_NAME = os.environ["CATALOG_TABLE_NAME"]

# API key for https://www.themoviedb.org
THE_MOVIE_DB_API_KEY = os.environ["THE_MOVIE_DB_API_KEY"]

# The S3 Bucket that stores Violet media and image assets.
MEDIA_BUCKET_NAME = os.environ["MEDIA_BUCKET_NAME"]
