use rocket::{get, routes, Shutdown};

const PORT: u16 = 19999;

#[tokio::main]
async fn request_shutdown() {
    std::thread::sleep(std::time::Duration::from_millis(200));
    let _ = reqwest::get(format!("http://127.0.0.1:{}/stop", PORT)).await;
}

#[get("/stop")]
pub async fn stop(shutdown: Shutdown) {
    shutdown.notify()
}

fn main() {
    rocket::async_main(async move {
        let rocket_config = rocket::Config::figment()
            .merge(("port", PORT))
            .merge(("shutdown.force", false));
        let rocket = rocket::custom(rocket_config)
            .mount("/", routes!(stop))
            .ignite()
            .await
            .unwrap();
        std::thread::spawn(request_shutdown);
        rocket.launch().await.unwrap();

        println!("################ Did not reproduce the bug (no deadlock), try again. Aborting now. #####################");
        std::process::abort();
    })
}
