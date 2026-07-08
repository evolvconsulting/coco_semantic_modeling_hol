from dotenv import load_dotenv
from flask import Flask
from flask_cors import CORS
from app.config import SnowflakeConfig
from app.snowflake_client import SnowflakeClient


def create_app() -> Flask:
    load_dotenv()

    app = Flask(__name__)
    CORS(app)

    config = SnowflakeConfig.from_env()
    app.config["SNOWFLAKE_CLIENT"] = SnowflakeClient(config)

    from app.routes import bp

    app.register_blueprint(bp)

    return app
