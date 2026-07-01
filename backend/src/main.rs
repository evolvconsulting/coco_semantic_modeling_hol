mod config;
mod dealers;
mod routes;
mod snowflake;

use actix_cors::Cors;
use actix_web::{web, App, HttpServer};
use config::SnowflakeConfig;
use snowflake::SnowflakeClient;

#[actix_web::main]
async fn main() -> std::io::Result<()> {
    dotenvy::dotenv().ok();

    let config = SnowflakeConfig::from_env().expect("config");
    let client = web::Data::new(SnowflakeClient::new(config));

    HttpServer::new(move || {
        App::new()
            .app_data(client.clone())
            .wrap(Cors::permissive())
            .service(routes::list_dealers)
            .service(routes::dealer_exceptions)
            .service(routes::dealer_credit_mix)
            .service(routes::dealer_funding)
            .service(routes::dealer_servicing)
    })
    .bind(("127.0.0.1", 8080))?
    .run()
    .await
}
