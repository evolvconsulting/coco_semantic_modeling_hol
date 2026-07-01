use crate::dealers;
use crate::snowflake::SnowflakeClient;
use actix_web::{get, web, HttpResponse, Responder};

#[get("/api/dealers")]
pub async fn list_dealers(client: web::Data<SnowflakeClient>) -> impl Responder {
    match dealers::all(client.get_ref()).await {
        Ok(dealers) => HttpResponse::Ok().json(dealers),
        Err(error) => HttpResponse::InternalServerError().body(error),
    }
}

#[get("/api/dealers/{id}/exceptions")]
pub async fn dealer_exceptions(
    client: web::Data<SnowflakeClient>,
    id: web::Path<String>,
) -> impl Responder {
    match dealers::exceptions(client.get_ref(), &id).await {
        Ok(breakdown) => HttpResponse::Ok().json(breakdown),
        Err(error) => HttpResponse::InternalServerError().body(error),
    }
}

#[get("/api/dealers/{id}/credit-mix")]
pub async fn dealer_credit_mix(
    client: web::Data<SnowflakeClient>,
    id: web::Path<String>,
) -> impl Responder {
    match dealers::credit_mix(client.get_ref(), &id).await {
        Ok(mix) => HttpResponse::Ok().json(mix),
        Err(error) => HttpResponse::InternalServerError().body(error),
    }
}

#[get("/api/dealers/{id}/funding")]
pub async fn dealer_funding(
    client: web::Data<SnowflakeClient>,
    id: web::Path<String>,
) -> impl Responder {
    match dealers::funding(client.get_ref(), &id).await {
        Ok(funding) => HttpResponse::Ok().json(funding),
        Err(error) => HttpResponse::InternalServerError().body(error),
    }
}

#[get("/api/dealers/{id}/servicing")]
pub async fn dealer_servicing(
    client: web::Data<SnowflakeClient>,
    id: web::Path<String>,
) -> impl Responder {
    match dealers::servicing(client.get_ref(), &id).await {
        Ok(servicing) => HttpResponse::Ok().json(servicing),
        Err(error) => HttpResponse::InternalServerError().body(error),
    }
}
