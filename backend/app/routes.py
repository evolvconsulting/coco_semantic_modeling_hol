from flask import Blueprint, current_app, jsonify

from app import dealers

bp = Blueprint("routes", __name__)


def _client():
    return current_app.config["SNOWFLAKE_CLIENT"]


@bp.get("/api/dealers")
def list_dealers():
    try:
        return jsonify(dealers.all(_client()))
    except RuntimeError as error:
        return str(error), 500


@bp.get("/api/dealers/<id>/exceptions")
def dealer_exceptions(id):
    try:
        return jsonify(dealers.exceptions(_client(), id))
    except RuntimeError as error:
        return str(error), 500


@bp.get("/api/dealers/<id>/credit-mix")
def dealer_credit_mix(id):
    try:
        return jsonify(dealers.credit_mix(_client(), id))
    except RuntimeError as error:
        return str(error), 500


@bp.get("/api/dealers/<id>/funding")
def dealer_funding(id):
    try:
        return jsonify(dealers.funding(_client(), id))
    except RuntimeError as error:
        return str(error), 500


@bp.get("/api/dealers/<id>/servicing")
def dealer_servicing(id):
    try:
        return jsonify(dealers.servicing(_client(), id))
    except RuntimeError as error:
        return str(error), 500
