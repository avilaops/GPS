// Device Location Tracker - 100% usando ecossistema Arxis
// ZERO dependências externas! 🦀🚀

use avila_json::JsonValue;
use avila_geo::Coordinate;
use std::collections::HashMap;
use std::fs;
use std::io::{BufRead, BufReader, Write};
use std::net::{TcpListener, TcpStream};
use std::sync::{Arc, Mutex};
use std::thread;
use std::path::Path;

#[derive(Debug, Clone)]
struct Location {
    latitude: f64,
    longitude: f64,
    accuracy: Option<f64>,
    timestamp: String,
    device_name: String,
}

impl Location {
    fn to_json(&self) -> JsonValue {
        let mut map = HashMap::new();
        map.insert("latitude".to_string(), JsonValue::Number(self.latitude));
        map.insert("longitude".to_string(), JsonValue::Number(self.longitude));

        if let Some(acc) = self.accuracy {
            map.insert("accuracy".to_string(), JsonValue::Number(acc));
        } else {
            map.insert("accuracy".to_string(), JsonValue::Null);
        }

        map.insert("timestamp".to_string(), JsonValue::String(self.timestamp.clone()));
        map.insert("device_name".to_string(), JsonValue::String(self.device_name.clone()));

        JsonValue::Object(map)
    }

    fn from_json(json: &JsonValue) -> Option<Self> {
        if let JsonValue::Object(map) = json {
            Some(Location {
                latitude: map.get("latitude")?.as_f64()?,
                longitude: map.get("longitude")?.as_f64()?,
                accuracy: map.get("accuracy").and_then(|v| v.as_f64()),
                timestamp: map.get("timestamp")?.as_str()?.to_string(),
                device_name: map.get("device_name")?.as_str()?.to_string(),
            })
        } else {
            None
        }
    }
}

#[derive(Debug, Clone)]
struct LocationHistory {
    locations: Vec<Location>,
}

impl LocationHistory {
    fn to_json(&self) -> JsonValue {
        let locations_array: Vec<JsonValue> = self.locations
            .iter()
            .map(|loc| loc.to_json())
            .collect();

        let mut map = HashMap::new();
        map.insert("locations".to_string(), JsonValue::Array(locations_array));
        JsonValue::Object(map)
    }

    fn from_json(json: &JsonValue) -> Option<Self> {
        if let JsonValue::Object(map) = json {
            if let Some(JsonValue::Array(arr)) = map.get("locations") {
                let locations: Vec<Location> = arr
                    .iter()
                    .filter_map(Location::from_json)
                    .collect();
                return Some(LocationHistory { locations });
            }
        }
        None
    }
}

struct AppState {
    current_location: Mutex<Option<Location>>,
    history: Mutex<LocationHistory>,
}

const HISTORY_FILE: &str = "location_history.json";

impl AppState {
    fn new() -> Self {
        let history = if Path::new(HISTORY_FILE).exists() {
            if let Ok(data) = fs::read_to_string(HISTORY_FILE) {
                if let Ok(json) = avila_json::parse(&data) {
                    LocationHistory::from_json(&json).unwrap_or(LocationHistory {
                        locations: Vec::new(),
                    })
                } else {
                    LocationHistory {
                        locations: Vec::new(),
                    }
                }
            } else {
                LocationHistory {
                    locations: Vec::new(),
                }
            }
        } else {
            LocationHistory {
                locations: Vec::new(),
            }
        };

        AppState {
            current_location: Mutex::new(None),
            history: Mutex::new(history),
        }
    }

    fn save_history(&self) {
        if let Ok(history) = self.history.lock() {
            let json = history.to_json();
            let json_str = json.to_string();
            let _ = fs::write(HISTORY_FILE, json_str);
        }
    }
}

fn handle_client(mut stream: TcpStream, state: Arc<AppState>) {
    let buf_reader = BufReader::new(&stream);
    let mut lines = buf_reader.lines();

    // Parse request line
    if let Some(Ok(request_line)) = lines.next() {
        let parts: Vec<&str> = request_line.split_whitespace().collect();
        if parts.len() < 2 {
            send_response(&mut stream, 400, "text/plain", b"Bad Request");
            return;
        }

        let method = parts[0];
        let path = parts[1];

        // Skip headers até linha vazia
        let mut content_length = 0;
        while let Some(Ok(line)) = lines.next() {
            if line.is_empty() {
                break;
            }
            if line.to_lowercase().starts_with("content-length:") {
                if let Some(len_str) = line.split(':').nth(1) {
                    content_length = len_str.trim().parse().unwrap_or(0);
                }
            }
        }

        // Ler body se existir
        let mut body = String::new();
        if content_length > 0 {
            let mut buffer = vec![0u8; content_length];
            if let Ok(reader) = stream.try_clone() {
                use std::io::Read;
                let mut reader = reader;
                if reader.read_exact(&mut buffer).is_ok() {
                    body = String::from_utf8_lossy(&buffer).to_string();
                }
            }
        }

        // Rotear requisição
        match (method, path) {
            ("GET", "/") => serve_index(&mut stream),
            ("GET", "/api/location") => get_current_location(&mut stream, &state),
            ("POST", "/api/location") => update_location(&mut stream, &state, &body),
            ("GET", "/api/history") => get_history(&mut stream, &state),
            ("DELETE", "/api/history/clear") => clear_history(&mut stream, &state),
            _ => send_response(&mut stream, 404, "text/plain", b"Not Found"),
        }
    }
}

fn serve_index(stream: &mut TcpStream) {
    let html = include_str!("../static/index.html");
    send_response(stream, 200, "text/html; charset=utf-8", html.as_bytes());
}

fn get_current_location(stream: &mut TcpStream, state: &Arc<AppState>) {
    if let Ok(location) = state.current_location.lock() {
        if let Some(loc) = &*location {
            let json = loc.to_json();
            let json_str = json.to_string();
            send_response(stream, 200, "application/json", json_str.as_bytes());
        } else {
            let error = r#"{"error":"No location data available"}"#;
            send_response(stream, 404, "application/json", error.as_bytes());
        }
    } else {
        send_response(stream, 500, "text/plain", b"Internal Server Error");
    }
}

fn update_location(stream: &mut TcpStream, state: &Arc<AppState>, body: &str) {
    // Parse JSON body
    if let Ok(json) = avila_json::parse(body) {
        if let JsonValue::Object(map) = json {
            let latitude = map.get("latitude").and_then(|v| v.as_f64());
            let longitude = map.get("longitude").and_then(|v| v.as_f64());

            if let (Some(lat), Some(lng)) = (latitude, longitude) {
                let accuracy = map.get("accuracy").and_then(|v| v.as_f64());
                let device_name = map.get("device_name")
                    .and_then(|v| v.as_str())
                    .unwrap_or("Unknown Device")
                    .to_string();

                // Timestamp atual (formato simples)
                let timestamp = format!("{}", std::time::SystemTime::now()
                    .duration_since(std::time::UNIX_EPOCH)
                    .unwrap().as_secs());

                let new_location = Location {
                    latitude: lat,
                    longitude: lng,
                    accuracy,
                    timestamp,
                    device_name,
                };

                // Atualizar localização atual
                if let Ok(mut current) = state.current_location.lock() {
                    *current = Some(new_location.clone());
                }

                // Adicionar ao histórico
                if let Ok(mut history) = state.history.lock() {
                    history.locations.push(new_location);

                    // Manter apenas últimas 1000
                    if history.locations.len() > 1000 {
                        history.locations.remove(0);
                    }
                }

                // Salvar
                state.save_history();

                let success = r#"{"status":"success","message":"Location updated successfully"}"#;
                send_response(stream, 200, "application/json", success.as_bytes());
                return;
            }
        }
    }

    send_response(stream, 400, "text/plain", b"Invalid JSON");
}

fn get_history(stream: &mut TcpStream, state: &Arc<AppState>) {
    if let Ok(history) = state.history.lock() {
        let json = history.to_json();
        let json_str = json.to_string();
        send_response(stream, 200, "application/json", json_str.as_bytes());
    } else {
        send_response(stream, 500, "text/plain", b"Internal Server Error");
    }
}

fn clear_history(stream: &mut TcpStream, state: &Arc<AppState>) {
    if let Ok(mut history) = state.history.lock() {
        history.locations.clear();
    }
    state.save_history();

    let success = r#"{"status":"success","message":"History cleared successfully"}"#;
    send_response(stream, 200, "application/json", success.as_bytes());
}

fn send_response(stream: &mut TcpStream, status: u16, content_type: &str, body: &[u8]) {
    let status_text = match status {
        200 => "OK",
        400 => "Bad Request",
        404 => "Not Found",
        500 => "Internal Server Error",
        _ => "Unknown",
    };

    let response = format!(
        "HTTP/1.1 {} {}\r\n\
         Content-Type: {}\r\n\
         Content-Length: {}\r\n\
         Access-Control-Allow-Origin: *\r\n\
         Access-Control-Allow-Methods: GET, POST, DELETE, OPTIONS\r\n\
         Access-Control-Allow-Headers: Content-Type\r\n\
         Connection: close\r\n\
         \r\n",
        status, status_text, content_type, body.len()
    );

    let _ = stream.write_all(response.as_bytes());
    let _ = stream.write_all(body);
    let _ = stream.flush();
}

fn main() -> std::io::Result<()> {
    println!("🌍 Device Location Tracker - Arxis Edition");
    println!("📍 Server starting on http://localhost:8080");
    println!("🦀 100% Native Rust - Zero External Dependencies!");
    println!("🚀 Using Arxis Ecosystem");
    println!("----------------------------------------");

    let listener = TcpListener::bind("0.0.0.0:8080")?;
    let state = Arc::new(AppState::new());

    println!("✅ Server ready! Open http://localhost:8080 in your browser");

    for stream in listener.incoming() {
        match stream {
            Ok(stream) => {
                let state = Arc::clone(&state);
                thread::spawn(move || {
                    handle_client(stream, state);
                });
            }
            Err(e) => {
                eprintln!("❌ Connection error: {}", e);
            }
        }
    }

    Ok(())
}
