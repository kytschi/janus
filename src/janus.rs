use regex::Regex;
use serde::Deserialize;
use std::error::Error;
use std::fs::File;
use std::fs;
use std::io::BufRead;
use std::io::BufReader;
use std::path::Path;

#[derive(Deserialize, Debug)]
struct Cfg {
    log_folders: Vec<String>,
    patterns: Vec<String>
}

static mut PATTERNS: Vec<String> = vec![];
static mut IPS: Vec<String> = vec![];

fn main() {
    println!("Janus 0.0.1");

    // Load the config.
    let cfg = load_cfg("cfg.json").unwrap();

    // Process the patterns.
    for file in cfg.patterns.iter() {
        let to_join = vec!["./patterns/".to_string(), file.to_string(), ".json".to_string()];
        let joined = to_join.join("");
        load_patterns(joined);
    }

    // Load the ips.
    load_ips("ips.json");

    // Process the logs in the log folders
    for file in cfg.log_folders.iter() {
        match process_logs(file.to_string()) {
            Ok(_) => println!("Processed {}", file),
            Err(e) => println!("Error processing the folder, {}, {}", file, e)
        }
    }

    write_ips("ips.json");
}

fn load_cfg<P: AsRef<Path>>(path: P) -> Result<Cfg, Box<dyn Error>> {
    println!("Loading CFG JSON");

    let file = File::open(path).expect("Failed to load the CFG JSON");
    let reader = BufReader::new(file);

    let cfg = serde_json::from_reader(reader)?;
    Ok(cfg)
}

fn load_ips<P: AsRef<Path>>(path: P) {
    println!("Loading IPs JSON");

    let file = File::open(path).expect("Failed to load the IPs JSON");
    let reader = BufReader::new(file);

    unsafe {
        IPS = serde_json::from_reader(reader).expect("Failed to parse the IPs JSON");
    }
}

fn load_patterns(path: String) {
    println!("Loading Patterns JSON, {}", path);

    let file = File::open(path).expect("Failed to load the Patterns JSON");
    let reader = BufReader::new(file);

    unsafe {
        let json: Vec<String> = serde_json::from_reader(reader).expect("Failed to process the pattern file");
        for pattern in json.iter() {
            PATTERNS.push(pattern.to_string());
        }
    }
}

fn process_logs(path: String) -> Result<(), Box<dyn Error>> {
    println!("Reading {}", path);
    let files = fs::read_dir(path)?;

    for file in files {
        let log = file.unwrap().path().display().to_string();
        if log.contains(".gz") {
            continue;
        }

        let log = File::open(log)?;
        for line in BufReader::new(log).lines() {
            let search = line.unwrap();
            unsafe {
                for pattern in PATTERNS.iter() {
                    if search.contains(&pattern.to_lowercase()) {
                        let re = Regex::new(r"\d{1,3}\.\d{1,3}\.\d{1,3}\.\d{1,3}").unwrap();
                        let search: &str = &search;
                        for ip in re.find_iter(search) {
                            let str_ip = &String::from(ip.as_str());
                            if ip.as_str() != "127.0.0.1" && !IPS.contains(str_ip) {
                                IPS.push(str_ip.to_owned());
                                println!("Found {}, blacklisting for pattern {}", ip.as_str(), pattern);
                            }
                        }
                    }
                }
            }
        }
    }

    Ok(())
}

fn write_ips<P: AsRef<Path>>(path: P) {
    println!("Writing IPs JSON");

    unsafe {
        let json: String = serde_json::to_string(&IPS).expect("Failed to convert IPs to JSON");
        fs::write(path, json);
    }
}